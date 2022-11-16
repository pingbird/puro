import '../command_result.dart';
import '../config.dart';
import '../provider.dart';
import 'create.dart';
import 'releases.dart';
import 'version.dart';

Future<EnvConfig> getProjectEnvOrDefault({
  required Scope scope,
  String? envName,
}) async {
  final config = PuroConfig.of(scope);
  if (envName != null) {
    final environment = config.getEnv(envName);
    if (!environment.exists) {
      if (pseudoEnvironmentNames.contains(environment.name)) {
        await createEnvironment(
          scope: scope,
          envName: environment.name,
          flutterVersion: await FlutterVersion.query(
            scope: scope,
            version: environment.name,
          ),
        );
      } else if (FlutterChannel.parse(environment.name) != null ||
          tryParseVersion(environment.name) != null) {
        throw CommandError(
          'No environment named `${environment.name}`\n'
          'That looks like a version, to create a new environment '
          'use `puro create my_env ${environment.name}; puro use my_env`',
        );
      }
      environment.ensureExists();
    }
    return environment;
  }
  var env = config.tryGetProjectEnv();
  if (env == null) {
    if (config.environmentOverride != null) {
      throw CommandError(
        'Selected environment `${config.environmentOverride}` does not exist',
      );
    }
    final envName = await getDefaultEnvName(scope: scope);
    env = config.getEnv(envName);
    if (!env.exists) {
      throw CommandError(
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
  return prefs.hasDefaultEnvironment() ? prefs.defaultEnvironment : 'stable';
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
