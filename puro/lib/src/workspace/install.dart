import 'package:file/file.dart';

import '../config.dart';
import '../env/default.dart';
import '../logger.dart';
import '../provider.dart';
import 'common.dart';
import 'gitignore.dart';
import 'intellij.dart';
import 'vscode.dart';

/// Modifies IntelliJ and VSCode configs of the current project to use the
/// selected environment's Flutter SDK.
Future<void> installIdeConfigs({
  required Scope scope,
  required Directory projectDir,
  required EnvConfig environment,
  bool? vscode,
  bool? intellij,
}) async {
  final log = PuroLogger.of(scope);
  log.d('vscode override: $vscode');
  log.d('intellij override: $vscode');
  await runOptional(
    scope,
    'installing IntelliJ config',
    () async {
      final ideConfig = await IntelliJConfig.load(
        scope: scope,
        projectDir: projectDir,
      );
      log.d('intellij exists: ${ideConfig.exists}');
      if (ideConfig.exists || intellij == true) {
        await installIdeConfig(
          scope: scope,
          ideConfig: ideConfig,
          environment: environment,
        );
      }
    },
    skip: intellij == false,
  );

  await runOptional(
    scope,
    'installing VSCode config',
    () async {
      final ideConfig = await VSCodeConfig.load(
        scope: scope,
        projectDir: projectDir,
      );
      log.d('vscode exists: ${ideConfig.exists}');
      if (ideConfig.exists || vscode == true) {
        await installIdeConfig(
          scope: scope,
          ideConfig: ideConfig,
          environment: environment,
        );
      }
    },
    skip: vscode == false,
  );
}

Future<void> installIdeConfig({
  required Scope scope,
  required IdeConfig ideConfig,
  required EnvConfig environment,
}) async {
  final flutterSdkPath = environment.flutterDir.path;
  final dartSdkPath = environment.flutter.cache.dartSdkDir.path;
  final log = PuroLogger.of(scope);
  log.v('Workspace path: `${ideConfig.workspaceDir.path}`');
  if (ideConfig.flutterSdkDir?.path != flutterSdkPath ||
      (ideConfig.dartSdkDir != null &&
          ideConfig.dartSdkDir?.path != dartSdkPath)) {
    log.v('Configuring ${ideConfig.name}...');
    await ideConfig.backup(scope: scope);
    ideConfig.dartSdkDir = environment.flutter.cache.dartSdkDir;
    ideConfig.flutterSdkDir = environment.flutterDir;
    await ideConfig.save(scope: scope);
  } else {
    log.v('${environment.name} already configured');
  }
}

/// Installs gitignores and IDE configs to [projectDir}.
Future<void> installWorkspaceEnvironment({
  required Scope scope,
  required Directory projectDir,
  required EnvConfig environment,
  bool? vscode,
  bool? intellij,
}) async {
  await runOptional(
    scope,
    'updating gitignore',
    () => updateGitignore(
      scope: scope,
      projectDir: projectDir,
      ignores: gitIgnoredFilesForWorkspace,
    ),
  );
  await runOptional(
    scope,
    'installing IDE configs',
    () => installIdeConfigs(
      scope: scope,
      projectDir: projectDir,
      environment: environment,
      vscode: vscode,
      intellij: intellij,
    ),
  );
}

/// Switches the environment of the current project.
Future<EnvConfig> switchEnvironment({
  required Scope scope,
  required String? envName,
  bool? vscode,
  bool? intellij,
}) async {
  final config = PuroConfig.of(scope);
  final model = config.readDotfile();
  final environment = await getProjectEnvOrDefault(
    scope: scope,
    envName: envName,
  );
  model.env = environment.name;
  config.writeDotfile(scope, model);
  final projectDir = config.ensureParentProjectDir();
  await installWorkspaceEnvironment(
    scope: scope,
    projectDir: projectDir,
    environment: environment,
    vscode: vscode,
    intellij: intellij,
  );
  return environment;
}
