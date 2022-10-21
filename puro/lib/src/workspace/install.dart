import 'package:file/file.dart';

import '../config.dart';
import '../env/releases.dart';
import '../logger.dart';
import '../provider.dart';
import 'gitignore.dart';
import 'intellij.dart';
import 'vscode.dart';

/// Modifies IntelliJ and VSCode configs of the current project to use the
/// selected environment's Flutter SDK.
Future<void> installIdeConfigs({
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
    if (ideConfig.flutterSdkDir?.path != flutterSdkPath ||
        (ideConfig.dartSdkDir != null &&
            ideConfig.dartSdkDir?.path != dartSdkPath)) {
      log.v('Configuring ${entry.key}...');
      ideConfig.dartSdkDir = null;
      ideConfig.flutterSdkDir = environment.flutterDir;
      await ideConfig.backup(scope: scope);
      await ideConfig.save(scope: scope);
    } else {
      log.v('${entry.key} already configured');
    }
  }
}

/// Installs gitignores and IDE configs to [projectDir}.
Future<void> installWorkspaceEnvironment({
  required Scope scope,
  required Directory projectDir,
  required EnvConfig environment,
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
    ),
  );
}

/// Switches the environment of the current project.
Future<void> switchEnvironment({
  required Scope scope,
  required String? name,
}) async {
  final config = PuroConfig.of(scope);
  final model = config.readDotfile();
  final environment =
      name == null ? config.tryGetCurrentEnv() : config.getEnv(name);
  if (environment == null) {
    throw AssertionError('No environment provided');
  }
  final projectDir = config.parentProjectDir;
  if (projectDir == null) {
    throw AssertionError("Couldn't find dart project in current directory");
  }
  if (!environment.exists) {
    if (name != null && FlutterChannel.parse(name) != null) {
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
  );
}
