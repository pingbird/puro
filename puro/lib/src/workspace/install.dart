import 'package:file/file.dart';

import '../config.dart';
import '../env/default.dart';
import '../extensions.dart';
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
  required ProjectConfig projectConfig,
  bool? vscode,
  bool? intellij,
  EnvConfig? replaceOnly,
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
        projectConfig: projectConfig,
      );
      log.d('intellij exists: ${ideConfig.exists}');
      if ((ideConfig.exists || intellij == true) &&
          (replaceOnly == null ||
              (ideConfig.dartSdkDir?.absolute
                      .pathEquals(replaceOnly.flutter.cache.dartSdkDir) ==
                  true))) {
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
        projectConfig: projectConfig,
      );
      log.d('vscode exists: ${ideConfig.exists}');
      if ((ideConfig.exists || vscode == true) ||
          (replaceOnly == null ||
              (ideConfig.dartSdkDir?.absolute
                      .pathEquals(replaceOnly.flutter.cache.dartSdkDir) ==
                  true))) {
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
  required ProjectConfig projectConfig,
  bool? vscode,
  bool? intellij,
  EnvConfig? replaceOnly,
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
      projectConfig: projectConfig,
      replaceOnly: replaceOnly,
    ),
  );
}

/// Switches the environment of the current project.
Future<EnvConfig> switchEnvironment({
  required Scope scope,
  required String? envName,
  required ProjectConfig projectConfig,
  Directory? projectDir,
  bool? vscode,
  bool? intellij,
  bool passive = false,
}) async {
  final config = PuroConfig.of(scope);
  projectDir ??= config.project.ensureParentProjectDir();
  final model = config.project.readDotfile();
  final environment = await getProjectEnvOrDefault(
    scope: scope,
    envName: envName,
  );
  final oldEnv = model.env;
  model.env = environment.name;
  await config.project.writeDotfile(scope, model);
  await installWorkspaceEnvironment(
    scope: scope,
    projectDir: projectDir,
    environment: environment,
    vscode: vscode,
    intellij: intellij,
    projectConfig: projectConfig,
    replaceOnly: passive && model.hasEnv() ? config.getEnv(oldEnv) : null,
  );
  return environment;
}
