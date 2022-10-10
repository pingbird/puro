import 'package:args/command_runner.dart';
import 'package:puro/src/commands/env.dart';
import 'package:puro/src/logger.dart';

import 'command.dart';

void main(List<String> args) async {
  final runner = PuroCommandRunner(
    'puro',
    'A tool for managing Flutter versions, applying patches, and automating builds.',
  );
  runner.argParser
    ..addOption(
      'git',
      help: 'Overrides the path to the git executable.',
      valueHelp: 'exe',
    )
    ..addOption(
      'root',
      help: 'Overrides the path to the directory containing environments.',
      valueHelp: 'dir',
    )
    ..addOption(
      'dir',
      help: 'Overrides the current working directory.',
      valueHelp: 'dir',
    )
    ..addOption(
      'flutter-git',
      help: 'Overrides the Flutter SDK git url.',
      valueHelp: 'url',
    )
    ..addOption(
      'engine-git',
      help: 'Overrides the Flutter Engine git url.',
      valueHelp: 'url',
    )
    ..addOption(
      'releases-json',
      help: 'Overrides the Flutter releases json url.',
      valueHelp: 'url',
      callback: runner.wrapCallback((str) {
        runner.versionsJsonUrl = str;
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
          runner.logLevel = LogLevel.debug;
        }
      }),
    )
    ..addFlag(
      'color',
      help: 'Enable or disable ANSI colors.',
    )
    ..addFlag(
      'json',
      help: 'Output in JSON where possible.',
      negatable: false,
    );
  runner.addCommand(EnvCommand());
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
