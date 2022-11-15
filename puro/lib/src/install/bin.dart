import 'dart:io';

import '../command_result.dart';
import '../config.dart';
import '../extensions.dart';
import '../file_lock.dart';
import '../process.dart';
import '../provider.dart';
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
}) async {
  final config = PuroConfig.of(scope);
  if (!config.globalPrefsJsonFile.existsSync()) {
    await updateGlobalPrefs(scope: scope, fn: (prefs) async {});
  }
  await _installTrampoline(
    scope: scope,
    force: force,
  );
  await _installShims(scope: scope);
}

Future<void> _installTrampoline({
  required Scope scope,
  bool force = false,
}) async {
  final version = await PuroVersion.of(scope);
  final config = PuroConfig.of(scope);
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
      command = 'pub global run puro';
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
    final upToDate = trampolineExists &&
        await compareFileAtomic(
          scope: scope,
          file: trampolineFile,
          content: trampolineHeader,
          prefix: true,
        );
    if (upToDate) {
      return;
    } else if (!force) {
      throw CommandError(
        'A different version of puro is installed in `${config.puroRoot.path}`, '
        'run `puro install-puro --force` to overwrite it',
      );
    }
  }

  executableFile.deleteOrRenameSync();
  trampolineFile.deleteOrRenameSync();
  trampolineFile.parent.createSync(recursive: true);
  trampolineFile.writeAsStringSync(trampolineScript);
}

Future<void> _installShims({
  required Scope scope,
}) async {
  final config = PuroConfig.of(scope);
  if (Platform.isWindows) {
    await writePassiveAtomic(
      scope: scope,
      file: config.puroDartShimFile,
      content: '@echo off\n'
          'FOR %%i IN ("%~dp0.") DO SET PURO_BIN=%%~fi\n'
          '"%PURO_BIN%\\puro.exe" dart %* & exit /B !ERRORLEVEL!',
    );
    await writePassiveAtomic(
      scope: scope,
      file: config.puroFlutterShimFile,
      content: '@echo off\n'
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
}
