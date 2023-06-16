import 'dart:convert';
import 'dart:io';

import 'package:neoansi/neoansi.dart';
import 'package:process/process.dart';

import '../command_result.dart';
import '../config.dart';
import '../install/profile.dart';
import '../logger.dart';
import '../process.dart';
import '../progress.dart';
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

final visualStudioProvider = Provider((scope) => VisualStudio(scope: scope));

Future<VisualStudio> ensureVisualStudioInstalled({
  required Scope scope,
}) async {
  final log = PuroLogger.of(scope);
  final vs = scope.read(visualStudioProvider);

  if (vs.isInstalled) {
    CommandMessage(
      'Using ${vs.displayName} (${vs.fullVersion}) from ${vs.installLocation}',
      type: CompletionType.info,
    ).queue(scope);

    final String? windows10SdkVersion = vs.getWindows10SDKVersion();

    log.d('vs.isPrerelease: ${vs.isPrerelease}');
    log.d('vs.windows10SDKVersion: $windows10SdkVersion');
    log.d('vs.isAtLeastMinimumVersion: ${vs.isAtLeastMinimumVersion}');
    log.d('vs.displayName: ${vs.displayName}');
    log.d('vs.displayVersion: ${vs.displayVersion}');
    log.d('vs.fullVersion: ${vs.fullVersion}');

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

  await ensureWindowsDebuggerInstalled(scope: scope);
  await ensureWindowsLongPathsEnabled(scope: scope);

  return vs;
}

Future<void> ensureWindowsDebuggerInstalled({required Scope scope}) async {
  // Building the engine requires the "Debugging Tools for Windows" feature to
  // be installed, holy cow, this stuff is blood boiling. Visual Studio
  // installs the Windows 10 SDK but doesn't let you select the debugging tools.
  // So what we do is use a convoluted method (without administrator) to locate
  // where it put that installer and run it headlessly.

  final vs = scope.read(visualStudioProvider);
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);

  final win10sdkPath =
      config.fileSystem.directory(vs.getWindows10SdkLocation()!);
  final debuggersDir =
      win10sdkPath.childDirectory('Debuggers').childDirectory('x86');
  final dbghelpFile = debuggersDir.childFile('dbghelp.dll');
  log.d('dbghelpFile: $dbghelpFile');
  await ProgressNode.of(scope).wrap((scope, node) async {
    node.description = 'Installing Windows debugger';
    if (!dbghelpFile.existsSync()) {
      final result = await runProcess(
        scope,
        'powershell',
        [
          '-command',
          'Get-ChildItem -Path "Registry::HKCR\\Installer\\Dependencies" | Foreach-Object {Get-ItemProperty \$_.PsPath } | ConvertTo-Json',
        ],
        throwOnFailure: true,
        debugLogging: false,
      );

      int compareVersions(String a, String b) {
        final x = a.split('.').map(int.parse).toList();
        final y = b.split('.').map(int.parse).toList();
        for (var i = 0;; i++) {
          if (x.length <= i) {
            if (y.length <= i) {
              return 0;
            }
            return -1;
          } else if (y.length <= i) {
            return 1;
          }
          final result = x[i].compareTo(y[i]);
          if (result != 0) return result;
        }
      }

      final dependencyList =
          (jsonDecode(result.stdout as String) as List<dynamic>).toList();
      dependencyList.removeWhere((dynamic e) =>
          e['Version'] == null ||
          e['DisplayName'] == null ||
          !(e['DisplayName'] as String)
              .startsWith('Windows Software Development Kit - Windows 10.'));
      if (dependencyList.isNotEmpty) {
        final dynamic dependency = dependencyList.reduce(
          (dynamic a, dynamic b) =>
              compareVersions(a['Version'] as String, b['Version'] as String) >
                      0
                  ? a
                  : b,
        );
        final dependencyKey = dependency['PSChildName'] as String;
        log.d('dependencyKey: $dependencyKey');
        final depDirectory = config.fileSystem
            .directory(Platform.environment['ProgramData']!)
            .childDirectory('Package Cache')
            .childDirectory(dependencyKey);
        log.d('depDirectory: $depDirectory');
        var installerFile = depDirectory.childFile('winsdksetup.exe');
        if (!installerFile.existsSync()) {
          installerFile = depDirectory.childFile('sdksetup.exe');
        }
        if (installerFile.existsSync()) {
          final result = await runProcess(
            scope,
            installerFile.path,
            [
              '/features',
              'OptionId.WindowsDesktopDebuggers',
              '/q',
              '/norestart'
            ],
          );
          if (result.exitCode == 0) return;
        }
      }
      throw CommandError(
        'Could not find Windows debugging tools, this can be installed by going to:\n'
        'Settings -> Apps and Features -> Latest "Windows Software Development Kit" -> Modify -> Change -> Check "Debugging Tools For Windows" -> Change\n'
        'https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/debugger-download-tools#small-classic-windbg-preview-logo-debugging-tools-for-windows-windbg',
      );
    }
  });
}

Future<void> ensureWindowsLongPathsEnabled({required Scope scope}) async {
  Future<bool> check() async {
    final longPathsEnabled = await readWindowsRegistryValue(
      scope: scope,
      key: r'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem',
      valueName: 'LongPathsEnabled',
    );
    return longPathsEnabled == '0x1';
  }

  if (!await check()) {
    await writeWindowsRegistryValue(
      scope: scope,
      key: r'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem',
      valueName: 'LongPathsEnabled',
      elevated: true,
      value: '0x1',
    );
    if (!await check()) {
      throw CommandError(
        'Building the engine requires long paths to be enabled, run the following command in powershell as an administrator:\n'
        'Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\FileSystem" -Name "LongPathsEnabled" -Value 1 -Force',
      );
    }
  }
}

Future<void> ensureWindowsPythonInstalled({required Scope scope}) async {
  final pythonPrograms = await findProgramInPath(scope: scope, name: 'python3');
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
}

Future<Map<String, String>> getEngineBuildEnvVars({
  required Scope scope,
  required EnvConfig environment,
}) async {
  final config = PuroConfig.of(scope);

  environment.engine.ensureExists();

  final env = <String, String>{'PURO_ENGINE_BUILD_ENV': '1'};
  final extraPaths = <String>[config.depotToolsDir.path];
  // Put extra paths in front so they take precedence
  final delimiter = Platform.isWindows ? ';' : ':';
  env['PATH'] = extraPaths
      .followedBy(Platform.environment['PATH']!.split(delimiter))
      .join(delimiter);
  if (Platform.isWindows) {
    final vs = await ensureVisualStudioInstalled(scope: scope);
    env['DEPOT_TOOLS_WIN_TOOLCHAIN'] = '0';
    env['GYP_MSVS_OVERRIDE_PATH'] = vs.installLocation!;
    env['WINDOWSSDKDIR'] = vs.getWindows10SdkLocation()!;
  }
  final log = PuroLogger.of(scope);
  log.v(
    'Engine build env:\n${env.entries.map((e) => '${e.key}=${e.value}').join('\n')}',
  );
  return env;
}
