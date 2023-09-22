import '../command_result.dart';
import '../config.dart';
import '../provider.dart';
import '../terminal.dart';

Future<void> ensureNoProjectsUsingEnv({
  required Scope scope,
  required EnvConfig environment,
}) async {
  final dotfiles = await getDotfilesUsingEnv(
    scope: scope,
    environment: environment,
  );
  if (dotfiles.isNotEmpty) {
    throw CommandError.list(
      [
        CommandMessage(
          'Environment `${environment.name}` is currently used by the following '
          'projects:\n${dotfiles.map((p) => '* ${p.parent.path}').join('\n')}',
        ),
        CommandMessage(
          'Pass `-f` to ignore this warning',
          type: CompletionType.info,
        ),
      ],
    );
  }
}

/// Deletes an environment.
Future<void> deleteEnvironment({
  required Scope scope,
  required String name,
  required bool force,
}) async {
  final config = PuroConfig.of(scope);
  final env = config.getEnv(name);
  env.ensureExists();

  if (!force) {
    await ensureNoProjectsUsingEnv(scope: scope, environment: env);
  }

  // Try deleting the lock file first so we don't delete an env being updated
  if (env.updateLockFile.existsSync()) {
    await env.updateLockFile.delete();
  }
  await env.envDir.delete(recursive: true);
}
