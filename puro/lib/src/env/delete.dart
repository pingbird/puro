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
  await env.envDir.delete(recursive: true);
}
