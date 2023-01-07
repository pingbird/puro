import '../config.dart';
import '../provider.dart';

/// Deletes an environment.
Future<void> deleteEnvironment({
  required Scope scope,
  required String name,
}) async {
  final config = PuroConfig.of(scope);
  final env = config.getEnv(name);
  env.ensureExists();
  // Try deleting the lock file first so we don't delete an env being updated
  if (env.updateLockFile.existsSync()) {
    await env.updateLockFile.delete();
  }
  await env.envDir.delete(recursive: true);
}
