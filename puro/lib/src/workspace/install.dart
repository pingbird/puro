import 'package:file/file.dart';

import '../config.dart';
import '../env/version.dart';
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
  await runOptional(
    scope,
    'installing IntelliJ config',
    () async {
      final ideConfig = await IntelliJConfig.load(
        scope: scope,
        projectDir: projectDir,
      );
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
      final gitignoreFile = ideConfig.workspaceDir.childFile('.gitignore');
      if (ideConfig.exists ||
          (gitignoreFile.existsSync() &&
              (await gitignoreFile.readAsString())
                  .split('\n')
                  .contains('.vscode')) ||
          vscode == true) {
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
    ideConfig.dartSdkDir = null;
    ideConfig.flutterSdkDir = environment.flutterDir;
    await ideConfig.backup(scope: scope);
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
Future<void> switchEnvironment({
  required Scope scope,
  required String? name,
  bool? vscode,
  bool? intellij,
}) async {
  final config = PuroConfig.of(scope);
  final model = config.readDotfile();
  final environment =
      name == null ? config.tryGetProjectEnv() : config.getEnv(name);
  if (environment == null) {
    throw AssertionError('No environment provided');
  }
  final projectDir = config.parentProjectDir;
  if (projectDir == null) {
    throw AssertionError("Couldn't find dart project in current directory");
  }
  if (!environment.exists) {
    if (name != null &&
        (FlutterChannel.parse(name) != null || tryParseVersion(name) != null)) {
      throw ArgumentError(
        'No environment named `$name`\n'
        'That looks like a version, you probably meant to do `puro create my_env $name; puro use my_env`',
      );
    }
    environment.ensureExists();
  }
  model.env = environment.name;
  config.writeDotfile(model);
  await installWorkspaceEnvironment(
    scope: scope,
    projectDir: projectDir,
    environment: environment,
    vscode: vscode,
    intellij: intellij,
  );
}
