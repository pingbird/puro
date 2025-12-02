import 'dart:io';

import 'package:neoansi/neoansi.dart';

import '../command_result.dart';
import '../config.dart';
import '../process.dart';
import '../provider.dart';
import '../terminal.dart';
import 'worker.dart';

Future<int> runBuildEnvShell({
  required Scope scope,
  List<String>? command,
  EnvConfig? environment,
}) async {
  final terminal = Terminal.of(scope);

  if (environment != null) {
    environment.engine.ensureExists();
  }

  if (Platform.environment['PURO_ENGINE_BUILD_ENV'] != null) {
    throw CommandError('Already inside an engine build environment');
  }

  final buildEnv = await getEngineBuildEnvVars(scope: scope);
  final defaultShell = command == null || command.isEmpty;
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
      ..writeln(
        terminal.format.color(
          '[ Running ${command![0]} with engine build environment,\n'
          '  type `exit` to return to the normal shell ]\n',
          bold: true,
          foregroundColor: Ansi8BitColor.blue,
        ),
      );
  }

  final process = await startProcess(
    scope,
    command.first,
    command.skip(1).toList(),
    environment: buildEnv,
    mode: ProcessStartMode.inheritStdio,
    workingDirectory: defaultShell ? environment?.engine.srcDir.path : null,
    rosettaWorkaround: true,
  );

  final exitCode = await process.exitCode;

  if (defaultShell) {
    terminal
      ..flushStatus()
      ..writeln(
        terminal.format.color(
          '\n[ Returning from engine build shell ]',
          bold: true,
          foregroundColor: Ansi8BitColor.blue,
        ),
      );
  }

  return exitCode;
}
