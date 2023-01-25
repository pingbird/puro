import 'dart:io';

import 'package:args/command_runner.dart';

import 'command.dart';
import 'command_result.dart';
import 'commands/clean.dart';
import 'commands/dart.dart';
import 'commands/engine.dart';
import 'commands/env_create.dart';
import 'commands/env_ls.dart';
import 'commands/env_rm.dart';
import 'commands/env_upgrade.dart';
import 'commands/env_use.dart';
import 'commands/flutter.dart';
import 'commands/gc.dart';
import 'commands/generate_docs.dart';
import 'commands/ls_versions.dart';
import 'commands/prefs.dart';
import 'commands/pub.dart';
import 'commands/puro_install.dart';
import 'commands/puro_upgrade.dart';
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
    'A powerful tool for installing and upgrading Flutter versions',
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
      'git-executable',
      help: 'Overrides the path to the git executable',
      valueHelp: 'exe',
      callback: runner.wrapCallback((exe) {
        runner.gitExecutableOverride = exe;
      }),
    )
    ..addOption(
      'root',
      help:
          'Overrides the global puro root directory. (defaults to `~/.puro` or \$PURO_ROOT)',
      valueHelp: 'dir',
      callback: runner.wrapCallback((dir) {
        runner.rootDirOverride = dir;
      }),
    )
    ..addOption(
      'dir',
      help: 'Overrides the current working directory',
      valueHelp: 'dir',
      callback: runner.wrapCallback((dir) {
        runner.workingDirOverride = dir;
      }),
    )
    ..addOption(
      'project',
      abbr: 'p',
      help: 'Overrides the selected flutter project',
      valueHelp: 'dir',
      callback: runner.wrapCallback((dir) {
        runner.projectDirOverride = dir;
      }),
    )
    ..addOption(
      'env',
      abbr: 'e',
      help: 'Overrides the selected environment',
      valueHelp: 'name',
      callback: runner.wrapCallback((name) {
        runner.environmentOverride = name?.toLowerCase();
      }),
    )
    ..addOption(
      'flutter-git-url',
      help: 'Overrides the Flutter SDK git url',
      valueHelp: 'url',
      callback: runner.wrapCallback((url) {
        runner.flutterGitUrlOverride = url;
      }),
    )
    ..addOption(
      'engine-git-url',
      help: 'Overrides the Flutter Engine git url',
      valueHelp: 'url',
      callback: runner.wrapCallback((url) {
        runner.engineGitUrlOverride = url;
      }),
    )
    ..addOption(
      'releases-json-url',
      help: 'Overrides the Flutter releases json url',
      valueHelp: 'url',
      callback: runner.wrapCallback((url) {
        runner.versionsJsonUrlOverride = url;
      }),
    )
    ..addOption(
      'flutter-storage-base-url',
      help: 'Overrides the Flutter storage base url',
      valueHelp: 'url',
      callback: runner.wrapCallback((url) {
        runner.flutterStorageBaseUrlOverride = url;
      }),
    )
    ..addOption(
      'log-level',
      help: 'Changes how much information is logged to the console, 0 being '
          'no logging at all, and 4 being extremely verbose',
      valueHelp: '0-4',
      callback: runner.wrapCallback((str) {
        if (str == null) return;
        final logLevel = int.parse(str);
        if (logLevel < 0 || logLevel > 4) {
          throw CommandError(
            'Argument `log-level` must be a number between 0 and 4, inclusive',
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
      help: 'Verbose logging, alias for --log-level=3',
      callback: runner.wrapCallback((flag) {
        if (flag) {
          log.level = LogLevel.verbose;
        }
      }),
    )
    ..addFlag(
      'color',
      help: 'Enable or disable ANSI colors',
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
      help: 'Enable progress bars',
      callback: runner.wrapCallback((flag) {
        if (runner.results!.wasParsed('progress')) {
          terminal.enableStatus = flag;
        }
      }),
    )
    ..addFlag(
      'json',
      help: 'Output in JSON where possible',
      negatable: false,
    )
    ..addFlag(
      'install',
      help: 'Whether to attempt to install puro',
      callback: runner.wrapCallback((flag) {
        if (runner.results!.wasParsed('install')) {
          runner.shouldInstallOverride = runner.results!['install'] as bool;
        }
      }),
    )
    ..addFlag(
      'version',
      help: 'Prints version information, same as the `version` command',
      negatable: false,
    );
  runner
    ..addCommand(VersionCommand())
    ..addCommand(EnvCreateCommand())
    ..addCommand(EnvUpgradeCommand())
    ..addCommand(EnvLsCommand())
    ..addCommand(EnvUseCommand())
    ..addCommand(CleanCommand())
    ..addCommand(EnvRmCommand())
    ..addCommand(FlutterCommand())
    ..addCommand(DartCommand())
    ..addCommand(PubCommand())
    ..addCommand(GenerateDocsCommand())
    ..addCommand(PuroUpgradeCommand())
    ..addCommand(PuroInstallCommand())
    ..addCommand(GcCommand())
    ..addCommand(LsVersionsCommand())
    ..addCommand(EngineCommand())
    ..addCommand(PrefsCommand());
  try {
    final result = await runner.run(args);
    if (result == null) {
      await runner.printUsage();
    } else {
      await runner.writeResultAndExit(result);
    }
  } on CommandError catch (exception, stackTrace) {
    log.v('$stackTrace');
    await runner.writeResultAndExit(exception.result);
  } on UsageException catch (exception) {
    await runner.writeResultAndExit(
      CommandHelpResult(
        didRequestHelp: runner.didRequestHelp,
        help: exception.message,
        usage: exception.usage,
      ),
    );
  } catch (exception, stackTrace) {
    await runner.writeResultAndExit(CommandErrorResult(exception, stackTrace));
  }
}
