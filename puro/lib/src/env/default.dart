import '../config.dart';
import '../file_lock.dart';
import '../provider.dart';

Future<EnvConfig> getProjectEnvOrDefault({
  required Scope scope,
}) async {
  final config = PuroConfig.of(scope);
  final env = config.tryGetProjectEnv();
  if (env == null) {
    if (config.projectDir == null) {
      throw AssertionError(
        'Not inside a Dart project and no default environment.',
      );
    } else {
      throw AssertionError(
        'No environment selected and no default environment',
      );
    }
  }
  return env..ensureExists();
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
  await writeAtomic(
    scope: scope,
    file: config.defaultEnvNameFile,
    content: envName,
  );
}
