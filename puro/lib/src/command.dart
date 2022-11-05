import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:async/async.dart';
import 'package:clock/clock.dart';
import 'package:file/local.dart';

import '../models.dart';
import 'config.dart';
import 'logger.dart';
import 'provider.dart';
import 'terminal.dart';
import 'version.dart';

extension CommandResultModelExtensions on CommandResultModel {
  void addMessage(CommandMessage message, OutputFormatter format) {
    messages.add(
      CommandMessageModel(
        type: (message.type ??
                (success ? CompletionType.success : CompletionType.failure))
            .name,
        message: message.message(format),
      ),
    );
  }

  void addMessages(Iterable<CommandMessage> messages, OutputFormatter format) {
    for (final message in messages) {
      addMessage(message, format);
    }
  }
}

class CommandErrorResult extends CommandResult {
  CommandErrorResult(this.exception, this.stackTrace);

  final Object exception;
  final StackTrace stackTrace;

  @override
  CommandMessage get message =>
      CommandMessage((format) => '$exception\n$stackTrace');

  @override
  bool get success => false;

  @override
  CommandResultModel? get model => CommandResultModel(
        error: CommandErrorModel(
          exception: '$exception',
          exceptionType: '${exception.runtimeType}',
          stackTrace: '$stackTrace',
        ),
      );
}

class CommandHelpResult extends CommandResult {
  CommandHelpResult({
    required this.didRequestHelp,
    this.help,
    this.usage,
  });

  final bool didRequestHelp;
  final String? help;
  final String? usage;

  @override
  Iterable<CommandMessage> get messages => [
        if (message != null)
          CommandMessage(
            (format) => help!,
            type: CompletionType.failure,
          ),
        if (usage != null)
          CommandMessage(
            (format) => usage!,
            type: message == null && didRequestHelp
                ? CompletionType.plain
                : CompletionType.info,
          ),
      ];

  @override
  bool get success => didRequestHelp;

  @override
  CommandResultModel? get model => CommandResultModel(usage: usage);
}

class CommandMessage {
  CommandMessage(this.message, {this.type});
  final CompletionType? type;
  final String Function(OutputFormatter format) message;

  static String formatMessages({
    required Iterable<CommandMessage> messages,
    required OutputFormatter format,
    required bool success,
  }) {
    return messages
        .map((e) => format.complete(
              e.message(format),
              type: e.type ??
                  (success ? CompletionType.success : CompletionType.failure),
            ))
        .join('\n');
  }
}

abstract class CommandResult {
  bool get success;

  CommandMessage? get message => null;

  Iterable<CommandMessage> get messages => [message!];

  CommandResultModel? get model => null;

  CommandResultModel toModel([OutputFormatter format = plainFormatter]) {
    final result = CommandResultModel();
    if (model != null) {
      result.mergeFromMessage(model!);
    }
    result.success = success;
    result.addMessages(messages, format);
    return result;
  }

  @override
  String toString() => CommandMessage.formatMessages(
        messages: messages,
        format: plainFormatter,
        success: toModel().success,
      );
}

class BasicMessageResult extends CommandResult {
  BasicMessageResult({
    required this.success,
    required String message,
    CompletionType? type,
    this.model,
  }) : messages = [CommandMessage((format) => message, type: type)];

  BasicMessageResult.list({
    required this.success,
    required this.messages,
    this.model,
  });

  @override
  final bool success;
  @override
  final List<CommandMessage> messages;
  @override
  final CommandResultModel? model;
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

  /// Whether or not puro should check for updates while this command is
  /// running.
  bool get allowUpdateCheck => true;

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

  String get usageWithoutDescription {
    final usageLines = usage.split('\n');
    return usageLines.skipWhile((line) => line.isNotEmpty).join('\n').trim();
  }

  @override
  void printUsage() {
    runner.writeResultAndExit(
      CommandHelpResult(
        didRequestHelp: runner.didRequestHelp,
        usage: usageWithoutDescription,
      ),
    );
  }

  String unwrapSingleArgument() {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      throw UsageException(
        'Exactly one argument expected, got ${rest.length}',
        usageWithoutDescription,
      );
    }
    return rest.first;
  }

  String? unwrapSingleOptionalArgument() {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      return null;
    } else if (rest.length != 1) {
      throw UsageException(
        'Zero or one arguments expected, got ${rest.length}',
        usageWithoutDescription,
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
        usageWithoutDescription,
      );
    }
    rest = rest.skip(startingAt);

    if (exactly != null && rest.length != exactly) {
      throw UsageException(
        'Exactly ${exactly + startingAt} arguments expected, got ${rest.length}',
        usageWithoutDescription,
      );
    }

    if (atMost != null) {
      if (rest.length > atMost) {
        throw UsageException(
          'At most ${atMost + startingAt} arguments expected, got ${rest.length}',
          usageWithoutDescription,
        );
      }
      rest = rest.take(atMost);
    }

    return rest.toList();
  }
}

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
  final messages = <CommandMessage>[];
  final callbackQueue = <void Function()>[];
  final fileSystem = const LocalFileSystem();
  final backgroundTasks = <Future<void>, String>{};

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

  Future<Never> exitPuro(int code) async {
    final results = <ResultFuture<void>, String>{
      for (final entry in backgroundTasks.entries)
        ResultFuture(entry.key): entry.value,
    };

    await Future.wait(results.keys).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        final incompleteTasks = results.entries.where((e) => !e.key.isComplete);
        log.w(
          'Gave up waiting for the following background tasks:\n'
          '${incompleteTasks.map((e) => '* ${e.value}').join('\n')}',
        );
        return [];
      },
    );

    exit(code);
  }

  void startInBackground({
    required String name,
    required FutureOr<void> Function() task,
    LogLevel level = LogLevel.verbose,
  }) {
    backgroundTasks[() async {
      try {
        await task();
      } catch (exception, stackTrace) {
        log.add(LogEntry(
          clock.now(),
          level,
          'Exception while $name\n$exception\n$stackTrace',
        ));
      }
    }()] = name;
  }

  @override
  void printUsage() {
    writeResultAndExit(
      CommandHelpResult(
        didRequestHelp: didRequestHelp,
        usage: usage,
      ),
    );
  }

  void addMessage(
    String message, {
    CompletionType? type = CompletionType.info,
  }) {
    messages.add(CommandMessage((format) => message, type: type));
  }

  Future<Never> writeResultAndExit(CommandResult result) async {
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
      stdout.writeln(
        CommandMessage.formatMessages(
          messages: messages.followedBy(result.messages),
          format: terminal.format,
          success: model.success,
        ),
      );
    }
    await exitPuro(model.success ? 0 : 1);
  }

  @override
  ArgResults parse(Iterable<String> args) {
    this.args = args.toList();
    return super.parse(args);
  }

  @override
  Future<CommandResult?> runCommand(ArgResults topLevelResults) async {
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

    final commandName = topLevelResults.command?.name;
    if (commandName != null &&
        !((commands[commandName] as PuroCommand?)?.allowUpdateCheck ?? true)) {
      final message = await checkIfUpdateAvailable(scope: scope, runner: this);
      if (message != null) {
        messages.add(message);
      }
    }

    return super.runCommand(topLevelResults);
  }
}
