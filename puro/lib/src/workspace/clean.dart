import 'package:file/file.dart';

import '../config.dart';
import '../logger.dart';
import '../provider.dart';
import 'gitignore.dart';
import 'intellij.dart';
import 'vscode.dart';

/// Restores IDE settings back to their original
Future<void> restoreIdeConfigs({
  required Scope scope,
  required Directory projectDir,
  required EnvConfig environment,
}) async {
  final log = PuroLogger.of(scope);
  final flutterSdkPath = environment.flutterDir.path;
  final dartSdkPath = environment.flutter.cache.dartSdkDir.path;
  for (final entry in {
    'IntelliJ': await IntelliJConfig.load(scope: scope, projectDir: projectDir),
    'VSCode': await VSCodeConfig.load(scope: scope, projectDir: projectDir),
  }.entries) {
    final ideConfig = entry.value;
    if (ideConfig == null) {
      log.v('${entry.key} config not found in current project');
      continue;
    }
    // Only restore if the SDK path matches what is selected, this should be
    // mostly harmless either way.
    if (ideConfig.flutterSdkDir?.path == flutterSdkPath ||
        ideConfig.dartSdkDir?.path == dartSdkPath) {
      log.v('Restoring ${entry.key}...');
      await ideConfig.restore(scope: scope);
    } else {
      log.v('${entry.key} already restored');
    }
  }
}

/// Attempts to restore everything in the workspace back to where it was before
/// using puro, this includes the gitignore and IDE configuration.
Future<void> cleanWorkspace({
  required Scope scope,
  Directory? projectDir,
}) async {
  final config = PuroConfig.of(scope);
  final environment = config.tryGetCurrentEnv();
  projectDir ??= config.parentProjectDir;
  if (projectDir == null) {
    throw AssertionError("Couldn't find dart project in current directory");
  }
  if (environment == null) return;
  await runOptional(scope, 'restoring gitignore', () {
    return updateGitignore(
      scope: scope,
      projectDir: projectDir!,
      ignores: {},
    );
  });
  await runOptional(scope, 'restoring IDE configs', () {
    return restoreIdeConfigs(
      scope: scope,
      projectDir: projectDir!,
      environment: environment,
    );
  });
  config.dotfileForWriting.deleteSync();
}
