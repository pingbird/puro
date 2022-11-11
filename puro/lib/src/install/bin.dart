import 'dart:io';

import '../config.dart';
import '../file_lock.dart';
import '../provider.dart';
import '../version.dart';

Future<void> ensurePuroInstalled({
  required Scope scope,
  bool force = false,
}) async {
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

  final String command;
  switch (version.type) {
    case PuroInstallationType.distribution:
      // Already installed
      return;
    case PuroInstallationType.standalone:
      command = '"${Platform.executable}"';
      break;
    case PuroInstallationType.development:
      final puroDartFile =
          version.packageRoot!.childDirectory('bin').childFile('puro.dart');
      command = '"${Platform.executable}" "${puroDartFile.path}"';
      break;
    case PuroInstallationType.pub:
      command = 'pub global run puro';
      break;
    default:
      throw ArgumentError("Can't install puro: ${version.type.description}");
  }

  final trampolineScript = Platform.isWindows
      ? '$command %* & exit /B !ERRORLEVEL!'
      : '#!/usr/bin/env bash\n$command "\$@"';

  final executableFile = config.puroExecutableFile;
  final trampolineFile = config.puroTrampolineFile;

  final installed = trampolineFile.existsSync() || executableFile.existsSync();

  if (installed) {
    final upToDate = await compareFileAtomic(
      scope: scope,
      file: trampolineFile,
      content: trampolineScript,
    );
    if (upToDate) {
      return;
    } else if (!force) {
      throw ArgumentError(
        'A different version of puro is installed in `${config.puroRoot.path}`, '
        'run `puro install-puro --force` to overwrite it',
      );
    }
  }

  if (trampolineFile.existsSync()) {
    trampolineFile.deleteSync();
  }
  if (executableFile.existsSync()) {
    executableFile.deleteSync();
  }
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
      content: 'FOR %%i IN ("%~dp0.") DO SET PURO_BIN=%%~fi\n'
          '"%PURO_BIN%\\puro.exe" dart %* & exit /B !ERRORLEVEL!',
    );
    await writePassiveAtomic(
      scope: scope,
      file: config.puroFlutterShimFile,
      content: 'FOR %%i IN ("%~dp0.") DO SET PURO_BIN=%%~fi\n'
          '"%PURO_BIN%\\puro.exe" flutter %* & exit /B !ERRORLEVEL!',
    );
  } else {
    await writePassiveAtomic(
      scope: scope,
      file: config.puroDartShimFile,
      content: '#!/usr/bin/env bash\n'
          'set -e\n'
          'unset CDPATH\n'
          'PURO_BIN="\$(cd "\${PROG_NAME%/*}" ; pwd -P)"\n'
          '"\$PURO_BIN/puro" dart "\$@"',
    );
    await writePassiveAtomic(
      scope: scope,
      file: config.puroFlutterShimFile,
      content: '#!/usr/bin/env bash\n'
          'set -e\n'
          'unset CDPATH\n'
          'PURO_BIN="\$(cd "\${PROG_NAME%/*}" ; pwd -P)"\n'
          '"\$PURO_BIN/puro" flutter "\$@"',
    );
  }
}
