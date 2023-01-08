import 'dart:io';

import 'package:neoansi/neoansi.dart';
import 'package:process/process.dart';

import '../command_result.dart';
import '../install/profile.dart';
import '../logger.dart';
import '../process.dart';
import '../provider.dart';
import '../terminal.dart';
import 'visual_studio.dart';

Future<void> installLinuxWorkerPackages({required Scope scope}) async {
  final errors = <CommandMessage>[];
  final tryApt = <String>[];

  const pm = LocalProcessManager();
  if (!pm.canRun('python3')) {
    errors.add(CommandMessage('python3 not found in PATH'));
    tryApt.add('python3');
  }
  if (!pm.canRun('curl')) {
    errors.add(CommandMessage('curl not found in PATH'));
    tryApt.add('curl');
  }
  if (!pm.canRun('unzip')) {
    errors.add(CommandMessage('unzip not found in PATH'));
    tryApt.add('unzip');
  }

  if (errors.isNotEmpty) {
    throw CommandError.list([
      ...errors,
      if (tryApt.isNotEmpty)
        CommandMessage(
          'Try running `sudo apt install ${tryApt.join(' ')}`',
          type: CompletionType.info,
        )
    ]);
  }
}

final vsProvider = Provider((scope) => VisualStudio(scope: scope));

Future<void> installWindowsWorkerPackages({required Scope scope}) async {
  final log = PuroLogger.of(scope);

  final vs = scope.read(vsProvider);

  final pythonPrograms = await findProgramInPath(scope: scope, name: 'python3');
  if (Platform.isWindows) {
    // Windows has a dummy python3 executable that opens the microsoft store
    // when you run it, unless you give it arguments, then it prints and fails.
    // There doesn't appear to be a way to programmatically disable the "App
    // execution aliases" feature, so we will just delete the useless python3
    // executable directly, Microsoft is truly a gift that keeps on giving.
    for (var i = 0; i < pythonPrograms.length; i++) {
      final program = pythonPrograms[i];
      final parent = program.parent;
      if (parent.basename == 'WindowsApps' &&
          parent.parent.basename == 'Microsoft') {
        // Double check that the executable is indeed useless before deleting.
        final result = await runProcess(
          scope,
          program.path,
          ['-V'],
          runInShell: true,
        );
        if (result.exitCode == 9009) {
          program.deleteSync();
          pythonPrograms.removeAt(i);
          break;
        }
      }
    }
  }
  if (pythonPrograms.length > 1) {
    CommandMessage.format(
      (format) => 'Multiple installations of python3 found in your PATH\n'
          'If engine builds fail, try removing all but one:\n'
          '${pythonPrograms.map((e) => '${format.color(
                '*',
                bold: true,
                foregroundColor: Ansi8BitColor.red,
              )} ${e.path}').join('\n')}',
    ).queue(scope);
  } else if (pythonPrograms.isEmpty) {
    throw CommandError.list([
      CommandMessage('python3 not found in your PATH'),
      CommandMessage(
        'Try running `winget install -e -i --id=Python.Python.3.11 --source=winget --scope=machine`',
        type: CompletionType.info,
      ),
    ]);
  }
  final python3Result = await runProcess(
    scope,
    'python3',
    ['-V'],
    runInShell: true,
  );
  if (python3Result.exitCode != 0) {
    throw CommandError(
      '`python3 -V` did not pass the vibe check (exited with code ${python3Result.exitCode})',
    );
  }

  if (vs.isInstalled) {
    CommandMessage(
      'Visual Studio ${vs.fullVersion} detected at ${vs.installLocation}',
      type: CompletionType.info,
    ).queue(scope);

    log.v('vs.isPrerelease: ${vs.isPrerelease}');

    final String? windows10SdkVersion = vs.getWindows10SDKVersion();
    log.v('vs.windows10SDKVersion: $windows10SdkVersion');
    log.v('vs.isAtLeastMinimumVersion: ${vs.isAtLeastMinimumVersion}');
    log.v('vs.displayName: ${vs.displayName}');
    log.v('vs.displayVersion: ${vs.displayVersion}');
    log.v('vs.fullVersion: ${vs.fullVersion}');

    // Messages for faulty installations.
    if (!vs.isAtLeastMinimumVersion) {
      throw CommandError(
        'The latest version of Visual Studio that Puro can detect is ${vs.displayVersion}\n'
        'Building flutter requires VS 2019 or later, download it at https://visualstudio.microsoft.com/downloads/\n'
        'During setup, select the "${vs.workloadDescription}" workload',
      );
    } else if (vs.isRebootRequired) {
      throw CommandError('Visual Studio says a reboot is required');
    } else if (!vs.isComplete) {
      throw CommandError(
        'Visual Studio says the installation is incomplete, try repairing it with the installer',
      );
    } else if (!vs.hasNecessaryComponents) {
      throw CommandError(
        'Visual Studio is missing necessary components, re-run the installer and '
        'include the "${vs.workloadDescription}" workload'
        'The following sub-components are also required: ${vs.requiredComponents().values.join(', ')}',
      );
    } else if (windows10SdkVersion == null) {
      throw CommandError(
        'Visual Studio is missing the Windows 10 SDK, re-run the installer and '
        'select Windows 10 SDK under the "${vs.workloadDescription}" workload',
      );
    }
  } else {
    throw CommandError(
      'Visual Studio not installed, download it at https://visualstudio.microsoft.com/downloads/\n'
      'During setup, select the "${vs.workloadDescription}" workload',
    );
  }
}
