import 'dart:convert';

import '../../models.dart';
import '../command_result.dart';
import '../config.dart';
import '../provider.dart';
import '../terminal.dart';

/// Deletes an environment.
Future<void> renameEnvironment({
  required Scope scope,
  required String name,
  required String newName,
}) async {
  final config = PuroConfig.of(scope);
  final env = config.getEnv(name);
  env.ensureExists();
  final newEnv = config.getEnv(newName);

  if (newEnv.exists) {
    throw CommandError(
      'Environment `$newName` already exists',
    );
  } else if (env.name == newEnv.name) {
    throw CommandError(
      'Environment `$name` is already named `$newName`',
    );
  }

  final dotfiles = await getDotfilesUsingEnv(
    scope: scope,
    environment: env,
  );

  if (env.updateLockFile.existsSync()) {
    await env.updateLockFile.delete();
  }
  await env.envDir.rename(newEnv.envDir.path);

  for (final dotfile in dotfiles) {
    final data = jsonDecode(dotfile.readAsStringSync());
    final model = PuroDotfileModel.create();
    model.mergeFromProto3Json(data);
    model.env = newName;
    dotfile.writeAsStringSync(prettyJsonEncoder.convert(model.toProto3Json()));
  }

  if (dotfiles.isNotEmpty) {
    CommandMessage(
      'Updated the following projects:\n'
      '${dotfiles.map((p) => '* ${p.parent.path}').join('\n')}',
      type: CompletionType.info,
    ).queue(scope);
  }
}
