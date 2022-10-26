import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/local.dart';

import '../models.dart';
import 'config.dart';
import 'logger.dart';
import 'provider.dart';
import 'terminal.dart';

class CommandErrorResult extends CommandResult {
  CommandErrorResult(this.exception, this.stackTrace);

  final Object exception;
  final StackTrace stackTrace;

  @override
  CommandResultModel toModel() {
    return CommandResultModel(
      success: false,
      error: CommandErrorModel(
        exception: '$exception',
        exceptionType: '${exception.runtimeType}',
        stackTrace: '$stackTrace',
      ),
    );
  }

  @override
  String description(OutputFormatter format) => '$exception\n$stackTrace';
}

class CommandHelpResult extends CommandResult {
  CommandHelpResult({
    required this.didRequestHelp,
    this.message,
    this.usage,
  });

  final bool didRequestHelp;
  final String? message;
  final String? usage;

  @override
  CompletionType? get type => CompletionType.plain;

  @override
  CommandResultModel toModel() {
    return CommandResultModel(
      success: didRequestHelp,
      message: message,
      usage: usage,
    );
  }

  @override
  String description(OutputFormatter format) =>
      [message, usage].where((e) => e != null).join('\n').trim();
}

abstract class CommandResult {
  CommandResultModel toModel();

  CompletionType? get type => null;

  String description(OutputFormatter format);

  @override
  String toString() => description(plainFormatter);
}

class BasicMessageResult extends CommandResult {
  BasicMessageResult({
    required this.success,
    required this.message,
    this.type,
  });

  final bool success;
  final String message;

  @override
  final CompletionType? type;

  @override
  String description(OutputFormatter format) => message;

  @override
  CommandResultModel toModel() {
    return CommandResultModel(
      success: success,
      message: message,
    );
  }
}

abstract class PuroCommand extends Command<CommandResult> {
  @override
  PuroCommandRunner get runner => super.runner as PuroCommandRunner;

  Scope get scope => runner.scope;

  String? get argumentUsage => null;

  @override
  bool get takesArguments => argumentUsage != null;

  @override
  String get description => '';

  @override
  String get invocation {
    final parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner.executableName);

    final invocation = parents.reversed.join(' ');
    return subcommands.isNotEmpty
        ? '$invocation <subcommand> [arguments]'
        : '$invocation${argumentUsage == null ? '' : ' $argumentUsage'}';
  }

  @override
  void printUsage() {
    runner.writeResultAndExit(
      CommandHelpResult(
        didRequestHelp: runner.didRequestHelp,
        usage: usage,
      ),
    );
  }

  String unwrapSingleArgument() {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException(
        'Exactly one argument expected, got ${rest.length}',
        usage,
      );
    }
    return rest.first;
  }

  List<String> unwrapArguments({
    int startingAt = 0,
    int atLeast = 0,
    int? atMost,
    int? exactly,
  }) {
    Iterable<String> rest = argResults!.rest;
    if (rest.length < startingAt + atLeast) {
      throw UsageException(
        'At least ${startingAt + atLeast} arguments expected, got ${rest.length}',
        usage,
      );
    }
    rest = rest.skip(startingAt);

    if (exactly != null && rest.length != exactly) {
      throw UsageException(
        'Exactly ${exactly + startingAt} arguments expected, got ${rest.length}',
        usage,
      );
    }

    if (atMost != null) {
      if (rest.length > atMost) {
        throw UsageException(
          'At most ${atMost + startingAt} arguments expected, got ${rest.length}',
          usage,
        );
      }
      rest = rest.take(atMost);
    }

    return rest.toList();
  }
}

const prettyJsonEncoder = JsonEncoder.withIndent('  ');

class PuroCommandRunner extends CommandRunner<CommandResult> {
  PuroCommandRunner(
    super.executableName,
    super.description, {
    required this.scope,
    required this.isJson,
  });

  final Scope scope;

  late final log = PuroLogger.of(scope);
  late final terminal = Terminal.of(scope);
  final bool isJson;

  // CLI args
  String? gitExecutableOverride;
  String? rootDirOverride;
  String? projectDirOverride;
  String? workingDirOverride;
  String? flutterGitUrlOverride;
  String? engineGitUrlOverride;
  String? versionsJsonUrlOverride;
  String? flutterStorageBaseUrlOverride;
  String? environmentOverride;

  late List<String> args;
  ArgResults? results;
  final logEntries = <LogEntry>[];
  final callbackQueue = <void Function()>[];
  final fileSystem = const LocalFileSystem();

  void Function(T) wrapCallback<T>(void Function(T) fn) {
    return (str) {
      callbackQueue.add(() {
        fn(str);
      });
    };
  }

  /// Args before `--`.
  Iterable<String> get puroArgs {
    final index = args.indexOf('--');
    return index >= 0 ? args.take(index) : args;
  }

  bool get didRequestHelp =>
      puroArgs.where((e) => !e.startsWith('-')).isEmpty ||
      puroArgs.contains('--help') ||
      puroArgs.contains('-h') ||
      puroArgs.where((e) => !e.startsWith('-')).take(1).contains('help');

  @override
  void printUsage() {
    writeResultAndExit(
      CommandHelpResult(
        didRequestHelp: didRequestHelp,
        usage: usage,
      ),
    );
  }

  void writeResultAndExit(CommandResult result) {
    final model = result.toModel();
    if (isJson) {
      final resultJson = model.toProto3Json();
      stdout.writeln(
        prettyJsonEncoder.convert(<String, dynamic>{
          ...resultJson as Map<String, dynamic>,
          'logs': [
            for (final entry in logEntries)
              LogEntryModel(
                timestamp: entry.timestamp.toIso8601String(),
                level: entry.level.index,
                message: entry.message,
              ).toProto3Json(),
          ],
        }),
      );
    } else {
      if (model.success) {
        terminal.resetStatus();
      } else {
        terminal.preserveStatus();
      }
      stdout.write(
        terminal.format.complete(
          result.description(terminal.format),
          type: result.type ??
              (model.success ? CompletionType.success : CompletionType.failure),
        ),
      );
    }
    exit(model.success ? 0 : 1);
  }

  @override
  ArgResults parse(Iterable<String> args) {
    this.args = args.toList();
    return super.parse(args);
  }

  @override
  Future<CommandResult?> runCommand(ArgResults topLevelResults) {
    results = topLevelResults;

    for (final callback in callbackQueue) {
      callback();
    }
    callbackQueue.clear();

    // Initialize config
    final config = PuroConfig.fromCommandLine(
      fileSystem: fileSystem,
      gitExecutable: gitExecutableOverride,
      puroRoot: rootDirOverride,
      workingDir: workingDirOverride,
      projectDir: projectDirOverride,
      flutterGitUrl: flutterGitUrlOverride,
      engineGitUrl: engineGitUrlOverride,
      releasesJsonUrl: versionsJsonUrlOverride,
      flutterStorageBaseUrl: flutterStorageBaseUrlOverride,
      environmentOverride: environmentOverride,
    );
    scope.add(
      PuroConfig.provider,
      config,
    );

    log.d('Config: $config');

    return super.runCommand(topLevelResults);
  }
}
