import 'dart:io';

import '../command_result.dart';
import '../config.dart';
import '../env/default.dart';
import '../extensions.dart';
import '../file_lock.dart';
import '../logger.dart';
import '../process.dart';
import '../provider.dart';
import '../terminal.dart';
import '../version.dart';

const bashShimHeader = '''#!/usr/bin/env bash
set -e
unset CDPATH
function follow_links() (
  cd -P "\$(dirname -- "\$1")"
  file="\$PWD/\$(basename -- "\$1")"
  while [[ -h "\$file" ]]; do
    cd -P "\$(dirname -- "\$file")"
    file="\$(readlink -- "\$file")"
    cd -P "\$(dirname -- "\$file")"
    file="\$PWD/\$(basename -- "\$file")"
  done
  echo "\$file"
)
PROG_NAME="\$(follow_links "\${BASH_SOURCE[0]}")"
''';

Future<void> ensurePuroInstalled({
  required Scope scope,
  bool force = false,
  bool promote = false,
}) async {
  final config = PuroConfig.of(scope);
  if (!config.shouldInstall) return;
  if (!config.globalPrefsJsonFile.existsSync()) {
    await updateGlobalPrefs(scope: scope, fn: (prefs) async {});
  }
  if (promote) {
    await _promoteStandalone(scope: scope);
  } else {
    await _installTrampoline(
      scope: scope,
      force: force,
    );
  }
  await _installShims(scope: scope);
  await updateDefaultEnvSymlink(scope: scope);
}

Future<void> _promoteStandalone({required Scope scope}) async {
  final log = PuroLogger.of(scope);
  final version = await PuroVersion.of(scope);
  if (version.type == PuroInstallationType.distribution) {
    return;
  } else if (version.type != PuroInstallationType.standalone) {
    throw CommandError('Only standalone executables can be promoted');
  }
  final config = PuroConfig.of(scope);
  final executableFile = config.puroExecutableFile;
  final trampolineFile = config.puroTrampolineFile;
  final executableIsTrampoline = executableFile.pathEquals(trampolineFile);
  if (!executableIsTrampoline && trampolineFile.existsSync()) {
    trampolineFile.deleteSync();
  }
  executableFile.deleteOrRenameSync();
  final puroExecutable = version.puroExecutable!;
  executableFile.parent.createSync(recursive: true);
  if (!executableFile.parent.existsSync()) {
    throw AssertionError('Failed to create ${puroExecutable.parent.path}');
  }
  if (!puroExecutable.existsSync()) {
    throw CommandError.list([
      CommandMessage(
        'Failed to install puro because the executable `${puroExecutable.path}` is missing',
      ),
      if (Platform.isWindows)
        CommandMessage(
          'The most likely culprit is Windows Defender, to make an exception, '
          'go to Windows Security > Protection History > Click the most recent '
          'item > Check if it says puro.exe > Allow on device',
          type: CompletionType.info,
        ),
    ]);
  }
  version.puroExecutable!.renameSync(executableFile.path);
}

Future<void> _installTrampoline({
  required Scope scope,
  bool force = false,
}) async {
  final version = await PuroVersion.of(scope);
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);
  final executableFile = config.puroExecutableFile;
  final trampolineFile = config.puroTrampolineFile;
  final executableIsTrampoline = executableFile.pathEquals(trampolineFile);

  final String command;
  final String installLocation;
  switch (version.type) {
    case PuroInstallationType.distribution:
      if (!executableIsTrampoline && trampolineFile.existsSync()) {
        trampolineFile.deleteSync();
      }
      // Already installed
      return;
    case PuroInstallationType.standalone:
      command = '"${Platform.executable}"';
      installLocation = Platform.executable;
      break;
    case PuroInstallationType.development:
      final puroDartFile =
          version.packageRoot!.childDirectory('bin').childFile('puro.dart');
      command = '"${Platform.executable}" "${puroDartFile.path}"';
      installLocation = puroDartFile.path;
      break;
    case PuroInstallationType.pub:
      command = 'dart pub global run puro';
      installLocation = 'pub';
      break;
    default:
      throw CommandError("Can't install puro: ${version.type.description}");
  }

  final trampolineHeader = Platform.isWindows
      ? '@echo off\nREM Puro installed at $installLocation'
      : '#!/usr/bin/env bash\n# Puro installed at $installLocation';

  final trampolineScript = Platform.isWindows
      ? '$trampolineHeader\n$command %* & exit /B !ERRORLEVEL!'
      : '$trampolineHeader\n$command "\$@"';

  final trampolineExists = trampolineFile.existsSync();
  final executableExists =
      executableIsTrampoline ? trampolineExists : executableFile.existsSync();
  final installed = trampolineExists || executableExists;

  if (installed) {
    final trampolineStat = trampolineFile.statSync();
    final exists = trampolineStat.type == FileSystemEntityType.file;
    // --x--x--x -> 0b001001001 -> 0x49
    final needsChmod =
        !Platform.isWindows && trampolineStat.mode & 0x49 != 0x49;
    final upToDate = exists &&
        await compareFileAtomic(
          scope: scope,
          file: trampolineFile,
          content: trampolineHeader,
          prefix: true,
        );
    log.d('trampolineStat: $trampolineStat');
    log.d('exists: $exists');
    log.d('needsChmod: $needsChmod');
    log.d('upToDate: $upToDate');
    log.d('trampolineStat.mode: ${trampolineStat.mode.toRadixString(16)}');
    if (upToDate) {
      if (needsChmod) {
        await runProcess(scope, 'chmod', ['+x', trampolineFile.path]);
      }
      return;
    } else if (!force) {
      throw CommandError(
        'A different version of puro is installed in `${config.puroRoot.path}`, '
        'run `puro install-puro --force` to overwrite it or `--no-install` to '
        'ignore this error.',
      );
    }
  }

  executableFile.deleteOrRenameSync();
  trampolineFile.deleteOrRenameSync();
  trampolineFile.parent.createSync(recursive: true);
  trampolineFile.writeAsStringSync(trampolineScript);
  if (!Platform.isWindows) {
    await runProcess(scope, 'chmod', ['+x', trampolineFile.path]);
  }
}

Future<void> _installShims({
  required Scope scope,
}) async {
  final config = PuroConfig.of(scope);
  if (config.enableShims) {
    if (Platform.isWindows) {
      await writePassiveAtomic(
        scope: scope,
        file: config.puroDartShimFile,
        content: '@echo off\n'
            'SETLOCAL ENABLEDELAYEDEXPANSION\n'
            'FOR %%i IN ("%~dp0.") DO SET PURO_BIN=%%~fi\n'
            '"%PURO_BIN%\\puro.exe" dart %* & exit /B !ERRORLEVEL!',
      );
      await writePassiveAtomic(
        scope: scope,
        file: config.puroFlutterShimFile,
        content: '@echo off\n'
            'SETLOCAL ENABLEDELAYEDEXPANSION\n'
            'FOR %%i IN ("%~dp0.") DO SET PURO_BIN=%%~fi\n'
            '"%PURO_BIN%\\puro.exe" flutter %* & exit /B !ERRORLEVEL!',
      );
    } else {
      await writePassiveAtomic(
        scope: scope,
        file: config.puroDartShimFile,
        content: '$bashShimHeader\n'
            'PURO_BIN="\$(cd "\${PROG_NAME%/*}" ; pwd -P)"\n'
            '"\$PURO_BIN/puro" dart "\$@"',
      );
      await writePassiveAtomic(
        scope: scope,
        file: config.puroFlutterShimFile,
        content: '$bashShimHeader\n'
            'PURO_BIN="\$(cd "\${PROG_NAME%/*}" ; pwd -P)"\n'
            '"\$PURO_BIN/puro" flutter "\$@"',
      );
      await runProcess(
        scope,
        'chmod',
        [
          '+x',
          config.puroDartShimFile.path,
          config.puroFlutterShimFile.path,
        ],
      );
    }
  } else {
    if (config.puroDartShimFile.existsSync()) {
      config.puroDartShimFile.deleteSync();
    }
    if (config.puroFlutterShimFile.existsSync()) {
      config.puroFlutterShimFile.deleteSync();
    }
  }
}
