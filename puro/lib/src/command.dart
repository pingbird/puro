import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:async/async.dart';
import 'package:clock/clock.dart';
import 'package:file/local.dart';

import '../models.dart';
import 'command_result.dart';
import 'config.dart';
import 'logger.dart';
import 'provider.dart';
import 'terminal.dart';
import 'version.dart';

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
  bool get hidden => name.startsWith('_');

  /// Whether or not puro should check for updates while this command is
  /// running.
  bool get allowUpdateCheck => true;

  @override
  String get summary => aliases.isEmpty
      ? description.split('\n').first
      : '${description.split('\n').first}\naliases: ${aliases.join(', ')}';

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
  String? pubCacheOverride;
  bool? legacyPubCache;
  String? gitExecutableOverride;
  String? rootDirOverride;
  String? projectDirOverride;
  String? workingDirOverride;
  String? flutterGitUrlOverride;
  String? engineGitUrlOverride;
  String? dartSdkGitUrlOverride;
  String? versionsJsonUrlOverride;
  String? flutterStorageBaseUrlOverride;
  String? environmentOverride;
  bool? shouldInstallOverride;
  bool? shouldSkipCacheSyncOverride;
  bool? allowUpdateCheckOverride;

  late List<String> args;
  ArgResults? results;
  final logEntries = <LogEntry>[];
  final messages = <CommandMessage>[];
  final callbackQueue = <void Function()>[];
  final fileSystem = const LocalFileSystem();
  final backgroundTasks = <Future<void>, String>{};
  bool initialized = false;

  // Silly workaround to allow us to keep argument results even with invalid
  // arguments that throw when parsed.
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

  var isExiting = false;

  Future<Never> exitPuro(int code) async {
    if (isExiting) {
      throw AssertionError('Already exiting');
    }
    isExiting = true;
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
            log.add(
              LogEntry(
                clock.now(),
                level,
                'Exception while $name\n$exception\n$stackTrace',
              ),
            );
          }
        }()] =
        name;
  }

  @override
  Future<void> printUsage() async {
    await writeResultAndExit(
      CommandHelpResult(didRequestHelp: didRequestHelp, usage: usage),
    );
  }

  void addMessage(
    String message, {
    CompletionType? type = CompletionType.info,
  }) {
    messages.add(CommandMessage(message, type: type));
  }

  var _exiting = false;
  Future<Never> writeResultAndExit(CommandResult result) async {
    try {
      if (_exiting) await Completer<void>().future;
      _exiting = true;
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
        terminal.enableStatus = false;
        await stderr.flush();
        stdout.writeln(
          CommandMessage.formatMessages(
            messages: messages.followedBy(result.messages),
            format: terminal.format,
            success: model.success,
          ),
        );
        messages.clear();
      }
      await exitPuro(model.success ? 0 : 1);
    } catch (exception, stackTrace) {
      stderr.writeln(
        'Exception while writing result:\n$exception\n$stackTrace',
      );
      exit(1);
    }
  }

  @override
  ArgResults parse(Iterable<String> args) {
    this.args = args.toList();
    return super.parse(args);
  }

  @override
  Future<CommandResult?> runCommand(ArgResults topLevelResults) async {
    results = topLevelResults;

    if (!initialized) {
      for (final callback in callbackQueue) {
        callback();
      }
      callbackQueue.clear();

      // Initialize config

      final homeDir = PuroConfig.getHomeDir(
        scope: scope,
        fileSystem: fileSystem,
      );
      final puroRoot = PuroConfig.getPuroRoot(
        scope: scope,
        fileSystem: fileSystem,
        homeDir: homeDir,
      );
      final prefsJson = puroRoot.childFile('prefs.json');
      scope.add(globalPrefsJsonFileProvider, prefsJson);
      final firstRun =
          !prefsJson.existsSync() || prefsJson.statSync().size == 0;
      scope.add(isFirstRunProvider, firstRun);
      log.d('firstRun: $firstRun');
      log.d('legacyPubCache: $legacyPubCache');

      final config = await PuroConfig.fromCommandLine(
        scope: scope,
        fileSystem: fileSystem,
        gitExecutable: gitExecutableOverride,
        puroRoot: puroRoot,
        homeDir: homeDir,
        pubCache: pubCacheOverride,
        legacyPubCache: legacyPubCache,
        workingDir: workingDirOverride,
        projectDir: projectDirOverride,
        flutterGitUrl: flutterGitUrlOverride,
        engineGitUrl: engineGitUrlOverride,
        dartSdkGitUrl: dartSdkGitUrlOverride,
        releasesJsonUrl: versionsJsonUrlOverride,
        flutterStorageBaseUrl: flutterStorageBaseUrlOverride,
        environmentOverride: environmentOverride,
        shouldInstall: shouldInstallOverride,
        shouldSkipCacheSync: shouldSkipCacheSyncOverride,
        firstRun: firstRun,
      );
      scope.add(PuroConfig.provider, config);
      scope.add(CommandMessage.provider, messages.add);

      final commandName = topLevelResults.command?.name;
      final command = commandName == null ? null : commands[commandName];
      if (command is PuroCommand &&
          command.allowUpdateCheck &&
          (allowUpdateCheckOverride ?? true)) {
        final message = await checkIfUpdateAvailable(
          scope: scope,
          runner: this,
        );
        if (message != null) {
          messages.add(message);
        }
      }

      initialized = true;
    }

    if (topLevelResults.wasParsed('version') &&
        topLevelResults.command?.name != 'version') {
      return run(['version']);
    }

    return super.runCommand(topLevelResults);
  }
}
