import '../config.dart';
import '../provider.dart';
import 'version.dart';

Future<EnvConfig> getProjectEnvOrDefault({
  required Scope scope,
  String? envName,
}) async {
  final config = PuroConfig.of(scope);
  if (envName != null) {
    final env = config.getEnv(envName);
    if (!env.exists) {
      if (FlutterChannel.parse(env.name) != null ||
          tryParseVersion(env.name) != null) {
        throw ArgumentError(
          'No environment named `${env.name}`\n'
          'That looks like a version, you probably meant to do `puro create my_env ${env.name}; puro use my_env`',
        );
      }
      env.ensureExists();
    }
    return env;
  }
  var env = config.tryGetProjectEnv();
  if (env == null) {
    if (config.environmentOverride != null) {
      throw ArgumentError(
        'Selected environment `${config.environmentOverride}` does not exist',
      );
    }
    final envName = await getDefaultEnvName(scope: scope);
    env = config.getEnv(envName);
    if (!env.exists) {
      throw ArgumentError(
        'No environment selected and default environment `$envName` does not exist',
      );
    }
  }
  return env;
}

Future<String> getDefaultEnvName({
  required Scope scope,
}) async {
  final prefs = await readGlobalPrefs(scope: scope);
  return prefs.hasDefaultEnvironment() ? prefs.defaultEnvironment : 'default';
}

Future<void> setDefaultEnvName({
  required Scope scope,
  required String envName,
}) async {
  ensureValidName(envName);
  await updateGlobalPrefs(
    scope: scope,
    fn: (prefs) {
      prefs.defaultEnvironment = envName;
    },
  );
}
