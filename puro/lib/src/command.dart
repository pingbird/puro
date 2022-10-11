import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/local.dart';
import 'package:puro/src/logger.dart';
import 'package:puro/src/provider.dart';

import '../models.dart';
import 'config.dart';

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
  String? get description => '$exception\n$stackTrace';
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
  CommandResultModel toModel() {
    return CommandResultModel(
      success: didRequestHelp,
      message: message,
      usage: usage,
    );
  }

  @override
  String? get description => '$message\n$usage';
}

abstract class CommandResult {
  CommandResultModel toModel();
  String? get description;

  @override
  String toString() => description ?? super.toString();
}

class BasicMessageResult extends CommandResult {
  BasicMessageResult({
    required this.success,
    this.message,
  });

  final bool success;
  final String? message;

  @override
  String? get description => message;

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
    super.description,
  );

  // CLI args
  final scope = RootScope();
  LogLevel? logLevel = LogLevel.warning;
  String? versionsJsonUrl;
  String? flutterStorageBaseUrl;
  String? environmentOverride;

  late ArgResults results;
  final logEntries = <LogEntry>[];
  final callbackQueue = <void Function()>[];
  final fileSystem = const LocalFileSystem();
  late PuroLogger log;

  void Function(T) wrapCallback<T>(void Function(T) fn) {
    return (str) {
      callbackQueue.add(() {
        fn(str);
      });
    };
  }

  bool get didRequestHelp =>
      results.wasParsed('help') ||
      results.arguments
          .where((e) => !e.startsWith('-'))
          .take(1)
          .contains('help');

  bool get isJson => results['json'] as bool;

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
    } else if (model.success) {
      stdout.writeln('$result');
    } else {
      log.e('$result');
    }
    exit(model.success ? 0 : 1);
  }

  @override
  Future<CommandResult?> runCommand(ArgResults topLevelResults) {
    results = topLevelResults;

    for (final callback in callbackQueue) {
      callback();
    }
    callbackQueue.clear();

    // Initialize config
    scope.add(
      PuroConfig.provider,
      PuroConfig.fromCommandLine(
        fileSystem: fileSystem,
        gitExecutable: topLevelResults['git'] as String,
        puroRoot: topLevelResults['root'] as String,
        workingDir: topLevelResults['dir'] as String,
        flutterGitUrl: topLevelResults['flutter-git'] as String,
        engineGitUrl: topLevelResults['engine-git'] as String,
        releasesJsonUrl: versionsJsonUrl,
        flutterStorageBaseUrl: flutterStorageBaseUrl,
        environmentOverride: environmentOverride,
      ),
    );

    // Logging
    final void Function(LogEntry entry) onEvent;
    if (isJson) {
      onEvent = logEntries.add;
    } else {
      final printer = PuroLogPrinter(
        sink: stderr,
        enableColor: results.wasParsed('color')
            ? results['color'] as bool
            : stderr.supportsAnsiEscapes,
      );
      onEvent = printer.add;
    }
    log = PuroLogger(
      level: logLevel,
      onEvent: onEvent,
    );
    scope.add(
      PuroLogger.provider,
      log,
    );

    return super.runCommand(topLevelResults);
  }
}
