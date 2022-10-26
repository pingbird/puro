import 'dart:io';

import 'package:args/command_runner.dart';

import 'command.dart';
import 'commands/clean.dart';
import 'commands/create.dart';
import 'commands/dart.dart';
import 'commands/flutter.dart';
import 'commands/generate-docs.dart';
import 'commands/ls.dart';
import 'commands/rm.dart';
import 'commands/use.dart';
import 'commands/version.dart';
import 'logger.dart';
import 'provider.dart';
import 'terminal.dart';

void main(List<String> args) async {
  final scope = RootScope();
  final terminal = Terminal(stdout: stderr);
  scope.add(Terminal.provider, terminal);

  final index = args.indexOf('--');
  final puroArgs = index >= 0 ? args.take(index) : args;
  final isJson = puroArgs.contains('--json');

  final runner = PuroCommandRunner(
    'puro',
    'An experimental tool for managing flutter versions.',
    scope: scope,
    isJson: isJson,
  );

  final PuroLogger log;
  if (isJson) {
    log = PuroLogger(
      terminal: terminal,
      onAdd: runner.logEntries.add,
    );
  } else {
    log = PuroLogger(
      terminal: terminal,
      level: LogLevel.warning,
    );
  }
  scope.add(PuroLogger.provider, log);

  runner.argParser
    ..addOption(
      'git',
      help: 'Overrides the path to the git executable.',
      valueHelp: 'exe',
      callback: runner.wrapCallback((exe) {
        runner.gitExecutableOverride = exe;
      }),
    )
    ..addOption(
      'root',
      help: 'Overrides the global puro root directory. (defaults to `~/.puro`)',
      valueHelp: 'dir',
      callback: runner.wrapCallback((dir) {
        runner.rootDirOverride = dir;
      }),
    )
    ..addOption(
      'dir',
      help: 'Overrides the current working directory.',
      valueHelp: 'dir',
      callback: runner.wrapCallback((dir) {
        runner.workingDirOverride = dir;
      }),
    )
    ..addOption(
      'project',
      abbr: 'p',
      help: 'Overrides the selected flutter project.',
      valueHelp: 'dir',
      callback: runner.wrapCallback((dir) {
        runner.projectDirOverride = dir;
      }),
    )
    ..addOption(
      'env',
      abbr: 'e',
      help: 'Overrides the selected environment.',
      valueHelp: 'name',
      callback: runner.wrapCallback((name) {
        runner.environmentOverride = name;
      }),
    )
    ..addOption(
      'flutter-git-url',
      help: 'Overrides the Flutter SDK git url.',
      valueHelp: 'url',
      callback: runner.wrapCallback((url) {
        runner.flutterGitUrlOverride = url;
      }),
    )
    ..addOption(
      'engine-git-url',
      help: 'Overrides the Flutter Engine git url.',
      valueHelp: 'url',
      callback: runner.wrapCallback((url) {
        runner.engineGitUrlOverride = url;
      }),
    )
    ..addOption(
      'releases-json-url',
      help: 'Overrides the Flutter releases json url.',
      valueHelp: 'url',
      callback: runner.wrapCallback((url) {
        runner.versionsJsonUrlOverride = url;
      }),
    )
    ..addOption(
      'flutter-storage-base-url',
      help: 'Overrides the Flutter storage base url.',
      valueHelp: 'url',
      callback: runner.wrapCallback((url) {
        runner.flutterStorageBaseUrlOverride = url;
      }),
    )
    ..addOption(
      'log-level',
      help: 'Changes how much information is logged to the console, 0 being '
          'no logging at all, and 4 being extremely verbose.',
      valueHelp: '0-4',
      callback: runner.wrapCallback((str) {
        if (str == null) return;
        final logLevel = int.parse(str);
        if (logLevel < 0 || logLevel > 4) {
          throw ArgumentError(
            'log-level must be a number between 0 and 4, inclusive',
          );
        }
        log.level = {
          1: LogLevel.error,
          2: LogLevel.warning,
          3: LogLevel.verbose,
          4: LogLevel.debug,
        }[logLevel];
      }),
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose logging, alias for --log-level=3.',
      callback: runner.wrapCallback((flag) {
        if (flag) {
          log.level = LogLevel.verbose;
        }
      }),
    )
    ..addFlag(
      'color',
      help: 'Enable or disable ANSI colors.',
      callback: runner.wrapCallback((flag) {
        if (runner.results!.wasParsed('color')) {
          terminal.enableColor = flag;
          if (!flag && !runner.results!.wasParsed('progress')) {
            terminal.enableStatus = false;
          }
        }
      }),
    )
    ..addFlag(
      'progress',
      help: 'Enable progress bars.',
      callback: runner.wrapCallback((flag) {
        if (runner.results!.wasParsed('progress')) {
          terminal.enableStatus = flag;
        }
      }),
    )
    ..addFlag(
      'json',
      help: 'Output in JSON where possible.',
      negatable: false,
    );
  runner
    ..addCommand(VersionCommand())
    ..addCommand(EnvCreateCommand())
    ..addCommand(EnvLsCommand())
    ..addCommand(EnvUseCommand())
    ..addCommand(CleanCommand())
    ..addCommand(EnvRmCommand())
    ..addCommand(FlutterCommand())
    ..addCommand(DartCommand())
    ..addCommand(GenerateDocsCommand());
  try {
    final result = await runner.run(args);
    if (result == null) {
      runner.printUsage();
    } else {
      runner.writeResultAndExit(result);
    }
  } on UsageException catch (exception) {
    runner.writeResultAndExit(
      CommandHelpResult(
        didRequestHelp: runner.didRequestHelp,
        message: exception.message,
        usage: exception.usage,
      ),
    );
  } catch (exception, stackTrace) {
    runner.writeResultAndExit(CommandErrorResult(exception, stackTrace));
  }
}
