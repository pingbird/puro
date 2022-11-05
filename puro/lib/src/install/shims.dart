import 'dart:io';

import '../config.dart';
import '../file_lock.dart';
import '../provider.dart';

Future<void> installShims({
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
