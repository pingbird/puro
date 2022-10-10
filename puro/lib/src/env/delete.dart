import '../config.dart';
import '../provider.dart';

/// Deletes an environment.
Future<void> deleteEnvironment({
  required Scope scope,
  required String name,
}) async {
  final config = PuroConfig.of(scope);
  final env = config.getEnv(name);
  if (!env.exists) {
    throw ArgumentError('No such environment `$name`');
  }
  await env.envDir.delete(recursive: true);
}
