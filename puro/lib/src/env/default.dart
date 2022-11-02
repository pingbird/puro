import '../config.dart';
import '../file_lock.dart';
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
  final config = PuroConfig.of(scope);
  final file = config.defaultEnvNameFile;
  if (file.existsSync()) {
    final name = (await readAtomic(scope: scope, file: file)).trim();
    if (isValidName(name)) {
      return name;
    }
  }
  return 'default';
}

Future<void> setDefaultEnvName({
  required Scope scope,
  required String envName,
}) async {
  final config = PuroConfig.of(scope);
  ensureValidName(envName);
  await writeAtomic(
    scope: scope,
    file: config.defaultEnvNameFile,
    content: envName,
  );
}
