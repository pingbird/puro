import '../config.dart';
import '../file_lock.dart';
import '../provider.dart';
import '../workspace/gitignore.dart';

Future<void> installEnvShims({
  required Scope scope,
  required EnvConfig environment,
}) async {
  final flutterConfig = environment.flutter;

  // Delete these because running them can corrupt our cache
  final sharedScripts = {
    'shared.bat',
    'shared.sh',
    'update_dart_sdk.ps1',
    'update_dart_sdk.sh',
  };

  await updateGitignore(
    scope: scope,
    projectDir: environment.flutterDir,
    ignores: {
      'bin/dart',
      'bin/dart.bat',
      'bin/flutter',
      'bin/flutter.bat',
      for (final name in sharedScripts) 'bin/internal/$name',
    },
  );

  for (final name in sharedScripts) {
    final file = flutterConfig.binInternalDir.childFile(name);
    if (file.existsSync()) file.deleteSync();
  }

  await writePassiveAtomic(
    scope: scope,
    file: flutterConfig.binDir.childFile('dart'),
    content: '#!/usr/bin/env bash\n'
        'set -e\n'
        'unset CDPATH\n'
        'export FLUTTER_BIN="\$(cd "\${PROG_NAME%/*}" ; pwd -P)"\n'
        'PURO_BIN="\$FLUTTER_BIN/../../../../bin"' // Backing out of envs/<name>/flutter/bin
        '"\$PURO_BIN/puro" dart "\$@"',
  );
  await writePassiveAtomic(
    scope: scope,
    file: flutterConfig.binDir.childFile('flutter'),
    content: '#!/usr/bin/env bash\n'
        'set -e\n'
        'unset CDPATH\n'
        'export FLUTTER_BIN="\$(cd "\${PROG_NAME%/*}" ; pwd -P)"\n'
        'PURO_BIN="\$FLUTTER_BIN/../../../../bin"'
        '"\$PURO_BIN/puro" flutter "\$@"',
  );
  await writePassiveAtomic(
    scope: scope,
    file: flutterConfig.binDir.childFile('dart.bat'),
    content: '@echo off\n'
        'FOR %%i IN ("%~dp0.") DO SET FLUTTER_BIN=%%~fi\n'
        'SET PURO_BIN=%FLUTTER_BIN%\\..\\..\\..\\..\\bin\n'
        '"%PURO_BIN%\\puro" dart %* & exit /B !ERRORLEVEL!',
  );
  await writePassiveAtomic(
    scope: scope,
    file: flutterConfig.binDir.childFile('flutter.bat'),
    content: '@echo off\n'
        'FOR %%i IN ("%~dp0.") DO SET FLUTTER_BIN=%%~fi\n'
        'SET PURO_BIN=%FLUTTER_BIN%\\..\\..\\..\\..\\bin\n'
        '"%PURO_BIN%\\puro" flutter %* & exit /B !ERRORLEVEL!',
  );
}
