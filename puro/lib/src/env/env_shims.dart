import 'dart:io';

import 'package:path/path.dart' as path;

import '../config.dart';
import '../file_lock.dart';
import '../git.dart';
import '../install/bin.dart';
import '../logger.dart';
import '../process.dart';
import '../provider.dart';
import '../workspace/gitignore.dart';

// Delete these because running them can corrupt our cache
const _sharedScripts = {
  'bin/internal/shared.bat',
  'bin/internal/shared.sh',
  'bin/internal/update_dart_sdk.ps1',
  'bin/internal/update_dart_sdk.sh',
};

const _binFiles = {
  'bin/dart',
  'bin/dart.bat',
  'bin/flutter',
  'bin/flutter.bat',
};

final _ignoredFiles = {
  'bin/cache',
  ..._binFiles,
  for (final name in _binFiles) '$name.bak',
  ..._sharedScripts,
};

Future<void> installEnvShims({
  required Scope scope,
  required EnvConfig environment,
}) async {
  final log = PuroLogger.of(scope);
  final git = GitClient.of(scope);
  final flutterConfig = environment.flutter;

  log.d('installEnvShims');

  for (var name in _binFiles) {
    name = name.replaceAll('/', path.context.separator);
    final file = flutterConfig.sdkDir.childFile(name);
    final bakFile = flutterConfig.sdkDir.childFile('$name.bak');
    if (bakFile.existsSync()) {
      if (file.existsSync()) {
        log.d('deleting $bakFile');
        bakFile.deleteSync();
      } else {
        log.d('renaming $bakFile -> $file');
        bakFile.renameSync(file.path);
      }
    }
  }

  await updateGitignore(
    scope: scope,
    projectDir: environment.flutterDir,
    ignores: _ignoredFiles,
  );

  for (var name in _sharedScripts) {
    name = name.replaceAll('/', path.context.separator);
    final file = flutterConfig.sdkDir.childFile(name);
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
        'SETLOCAL ENABLEDELAYEDEXPANSION\n'
        'FOR %%i IN ("%~dp0.") DO SET FLUTTER_BIN=%%~fi\n'
        'SET PURO_BIN=%FLUTTER_BIN%\\..\\..\\..\\..\\bin\n'
        '"%PURO_BIN%\\puro" dart %* & exit /B !ERRORLEVEL!\n',
  );
  await writePassiveAtomic(
    scope: scope,
    file: flutterConfig.binDir.childFile('flutter.bat'),
    content: '@echo off\n'
        'SETLOCAL ENABLEDELAYEDEXPANSION\n'
        'FOR %%i IN ("%~dp0.") DO SET FLUTTER_BIN=%%~fi\n'
        'SET PURO_BIN=%FLUTTER_BIN%\\..\\..\\..\\..\\bin\n'
        '"%PURO_BIN%\\puro" flutter %* & exit /B !ERRORLEVEL!\n',
  );

  await git.assumeUnchanged(
    repository: flutterConfig.sdkDir,
    files: _binFiles.followedBy(_sharedScripts).where(
          (name) => flutterConfig.sdkDir.childFile(name).existsSync(),
        ),
  );

  await updateGitAttributes(
    scope: scope,
    projectDir: environment.flutterDir,
    attributes: {
      for (final name in _binFiles.followedBy(_sharedScripts))
        name: 'merge=ours',
    },
  );

  await git.config(
    repository: environment.flutterDir,
    name: 'merge.ours.driver',
    value: Platform.isWindows ? 'rem' : 'true',
  );
}

Future<void> uninstallEnvShims({
  required Scope scope,
  required EnvConfig environment,
}) async {
  final log = PuroLogger.of(scope);
  final flutterConfig = environment.flutter;
  final git = GitClient.of(scope);

  log.d('uninstallEnvShims');

  for (var name in _binFiles) {
    name = name.replaceAll('/', path.context.separator);
    final file = flutterConfig.sdkDir.childFile(name);
    final bakFile = flutterConfig.sdkDir.childFile('$name.bak');
    if (file.existsSync()) {
      if (bakFile.existsSync()) {
        log.d('deleting $bakFile');
        bakFile.deleteSync();
      }
      log.d('renaming $file -> $bakFile');
      file.renameSync(bakFile.path);
    }
  }

  if (await git.tryGetCurrentCommitHash(repository: flutterConfig.sdkDir) !=
      null) {
    await git.assumeUnchanged(
      repository: flutterConfig.sdkDir,
      files: _binFiles.followedBy(_sharedScripts),
      value: false,
    );

    await updateGitAttributes(
      scope: scope,
      projectDir: flutterConfig.sdkDir,
      attributes: {},
    );
  }
}
