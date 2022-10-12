import 'package:args/command_runner.dart';

import 'command.dart';
import 'commands/create.dart';
import 'commands/dart.dart';
import 'commands/flutter.dart';
import 'commands/ls.dart';
import 'commands/rm.dart';
import 'commands/use.dart';
import 'logger.dart';

void main(List<String> args) async {
  final runner = PuroCommandRunner(
    'puro',
    'An experimental tool for managing flutter versions.',
  );
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
        runner.logLevel = {
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
          runner.logLevel = LogLevel.verbose;
        }
      }),
    )
    ..addFlag(
      'color',
      help: 'Enable or disable ANSI colors.',
      callback: runner.wrapCallback((flag) {
        if (runner.results!.wasParsed('color')) {
          runner.colorOverride = flag;
        }
      }),
    )
    ..addFlag(
      'json',
      help: 'Output in JSON where possible.',
      negatable: false,
    );
  runner
    ..addCommand(EnvCreateCommand())
    ..addCommand(EnvLsCommand())
    ..addCommand(EnvUseCommand())
    ..addCommand(EnvRmCommand())
    ..addCommand(FlutterCommand())
    ..addCommand(DartCommand());
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
        didRequestHelp: false,
        message: exception.message,
        usage: exception.usage,
      ),
    );
  } catch (exception, stackTrace) {
    runner.writeResultAndExit(CommandErrorResult(exception, stackTrace));
  }
}
