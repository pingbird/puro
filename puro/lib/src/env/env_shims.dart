import 'dart:io';

import '../config.dart';
import '../file_lock.dart';
import '../git.dart';
import '../install/bin.dart';
import '../process.dart';
import '../provider.dart';
import '../workspace/gitignore.dart';

Future<void> installEnvShims({
  required Scope scope,
  required EnvConfig environment,
}) async {
  final git = GitClient.of(scope);
  final flutterConfig = environment.flutter;

  // Delete these because running them can corrupt our cache
  final sharedScripts = {
    'shared.bat',
    'shared.sh',
    'update_dart_sdk.ps1',
    'update_dart_sdk.sh',
  };

  final ignores = {
    'bin/cache',
    'bin/dart',
    'bin/dart.bat',
    'bin/flutter',
    'bin/flutter.bat',
    for (final name in sharedScripts) 'bin/internal/$name',
  };

  await updateGitignore(
    scope: scope,
    projectDir: environment.flutterDir,
    ignores: ignores,
  );

  for (final name in sharedScripts) {
    final file = flutterConfig.binInternalDir.childFile(name);
    if (file.existsSync()) file.deleteSync();
  }

  await writePassiveAtomic(
    scope: scope,
    file: flutterConfig.binDir.childFile('dart'),
    content: '$bashShimHeader\n'
        'export FLUTTER_BIN="\$(cd "\${PROG_NAME%/*}" ; pwd -P)"\n'
        'PURO_BIN="\$FLUTTER_BIN/../../../../bin"\n' // Backing out of envs/<name>/flutter/bin
        '"\$PURO_BIN/puro" dart "\$@"\n',
  );
  await writePassiveAtomic(
    scope: scope,
    file: flutterConfig.binDir.childFile('flutter'),
    content: '$bashShimHeader\n'
        'export FLUTTER_BIN="\$(cd "\${PROG_NAME%/*}" ; pwd -P)"\n'
        'PURO_BIN="\$FLUTTER_BIN/../../../../bin"\n' // Backing out of envs/<name>/flutter/bin
        '"\$PURO_BIN/puro" flutter "\$@"\n',
  );

  if (!Platform.isWindows) {
    await runProcess(
      scope,
      'chmod',
      [
        '+x',
        flutterConfig.binDir.childFile('dart').path,
        flutterConfig.binDir.childFile('flutter').path,
      ],
    );
  }

  await writePassiveAtomic(
    scope: scope,
    file: flutterConfig.binDir.childFile('dart.bat'),
    content: '@echo off\n'
        'FOR %%i IN ("%~dp0.") DO SET FLUTTER_BIN=%%~fi\n'
        'SET PURO_BIN=%FLUTTER_BIN%\\..\\..\\..\\..\\bin\n'
        '"%PURO_BIN%\\puro" dart %* & exit /B !ERRORLEVEL!\n',
  );
  await writePassiveAtomic(
    scope: scope,
    file: flutterConfig.binDir.childFile('flutter.bat'),
    content: '@echo off\n'
        'FOR %%i IN ("%~dp0.") DO SET FLUTTER_BIN=%%~fi\n'
        'SET PURO_BIN=%FLUTTER_BIN%\\..\\..\\..\\..\\bin\n'
        '"%PURO_BIN%\\puro" flutter %* & exit /B !ERRORLEVEL!\n',
  );

  for (final ignore in ignores.skip(1)) {
    await git.assumeUnchanged(
      repository: flutterConfig.sdkDir,
      file: ignore,
    );
  }
}
