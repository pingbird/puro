import 'dart:io';

import 'package:neoansi/neoansi.dart';

import '../command.dart';
import '../command_result.dart';
import '../config.dart';
import '../engine/prepare.dart';
import '../engine/worker.dart';
import '../process.dart';
import '../terminal.dart';

class EngineCommand extends PuroCommand {
  EngineCommand() {
    addSubcommand(EnginePrepareCommand());
    addSubcommand(EngineBuildEnvCommand());
  }

  @override
  final name = 'engine';

  @override
  final description = 'Manages Flutter engine builds';
}

class EnginePrepareCommand extends PuroCommand {
  EnginePrepareCommand() {
    argParser.addOption(
      'fork',
      help:
          'The origin to use when cloning the engine, puro will set the upstream automatically.',
      valueHelp: 'url',
    );
    argParser.addFlag(
      'force',
      help: 'Forcefully upgrade the engine, erasing any unstaged changes',
      negatable: false,
    );
  }

  @override
  final name = 'prepare';

  @override
  final description = 'Prepares an environment for building the engine';

  @override
  String? get argumentUsage => '<env> [ref]';

  @override
  Future<CommandResult> run() async {
    final force = argResults!['force'] as bool;
    final fork = argResults!['fork'] as String?;
    final args = unwrapArguments(atLeast: 1, atMost: 2);
    final envName = args.first;
    final ref = args.length > 1 ? args[1] : null;

    final config = PuroConfig.of(scope);
    final env = config.getEnv(envName);
    env.ensureExists();
    if (ref != null && ref != env.flutter.engineVersion) {
      runner.addMessage(
        'Preparing a different version of the engine than what the framework expects\n'
        'Here be dragons', // rrerr
      );
    }
    await prepareEngine(
      scope: scope,
      environment: env,
      ref: ref,
      forkRemoteUrl: fork,
      force: force,
    );
    return BasicMessageResult(
      'Engine at `${env.engine.engineSrcDir.path}` ready to build',
    );
  }
}

class EngineBuildEnvCommand extends PuroCommand {
  @override
  final name = 'build-env';

  @override
  List<String> get aliases => ['buildenv'];

  @override
  final description =
      'Starts a shell with the proper environment variables for building the engine';

  @override
  String? get argumentUsage => '<env> [...command]';

  @override
  Future<CommandResult> run() async {
    final config = PuroConfig.of(scope);
    final terminal = Terminal.of(scope);

    final env = config.getEnv(unwrapArguments(atLeast: 1)[0]);
    env.ensureExists();

    if (Platform.environment['PURO_ENGINE_BUILD_ENV'] != null) {
      throw CommandError('Already inside an engine build environment');
    }

    final buildEnv = await getEngineBuildEnvVars(
      scope: scope,
      environment: env,
    );

    var command = unwrapArguments(startingAt: 1);
    final defaultShell = command.isEmpty;
    if (defaultShell) {
      if (Platform.isWindows) {
        final processTree = await getParentProcesses(scope: scope);
        command = ['cmd.exe'];
        for (final process in processTree) {
          if (process.name == 'powershell.exe' || process.name == 'cmd.exe') {
            command = [process.name];
            break;
          }
        }
      } else {
        final shell = Platform.environment['SHELL'];
        if (shell != null && shell.isNotEmpty) {
          command = [shell];
        } else {
          command = [if (Platform.isMacOS) '/bin/zsh' else '/bin/bash'];
        }
      }

      terminal
        ..flushStatus()
        ..writeln(terminal.format.color(
          '[ Running ${command[0]} with engine build environment,\n'
          '  type `exit` to return to the normal shell ]\n',
          bold: true,
          foregroundColor: Ansi8BitColor.blue,
        ));
    }

    final process = await startProcess(
      scope,
      command.first,
      command.skip(1).toList(),
      runInShell: true,
      environment: buildEnv,
      mode: ProcessStartMode.inheritStdio,
      workingDirectory: defaultShell ? env.engine.srcDir.path : null,
    );

    final exitCode = await process.exitCode;

    if (defaultShell) {
      terminal
        ..flushStatus()
        ..writeln(terminal.format.color(
          '\n[ Returning from engine build shell ]',
          bold: true,
          foregroundColor: Ansi8BitColor.blue,
        ));
    }

    await runner.exitPuro(exitCode);
  }
}
