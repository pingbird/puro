import 'dart:convert';

import 'package:file/file.dart';

import '../../models.dart';
import '../command_result.dart';
import '../config.dart';
import '../logger.dart';
import '../progress.dart';
import '../provider.dart';
import '../terminal.dart';
import '../workspace/install.dart';

/// Deletes an environment.
Future<void> renameEnvironment({
  required Scope scope,
  required String name,
  required String newName,
}) async {
  final config = PuroConfig.of(scope);
  final env = config.getEnv(name);
  final log = PuroLogger.of(scope);
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

  final updated = <File>[];

  await ProgressNode.of(scope).wrap((scope, node) async {
    node.description = 'Switching project environments';
    for (final dotfile in dotfiles) {
      try {
        await switchEnvironment(
          scope: scope,
          envName: newName,
          projectConfig: ProjectConfig(
            parentConfig: config,
            projectDir: dotfile.parent,
            parentProjectDir: dotfile.parent,
          ),
          passive: true,
        );
        updated.add(dotfile);
      } catch (exception, stackTrace) {
        log.e('Exception while switching environment of ${dotfile.parent}');
        log.e('$exception\n$stackTrace');
      }
      final data = jsonDecode(dotfile.readAsStringSync());
      final model = PuroDotfileModel.create();
      model.mergeFromProto3Json(data);
      model.env = newName;
      dotfile
          .writeAsStringSync(prettyJsonEncoder.convert(model.toProto3Json()));
    }
  });

  if (dotfiles.isNotEmpty) {
    CommandMessage(
      'Switched the following projects:\n'
      '${dotfiles.map((p) => '* ${p.parent.path}').join('\n')}',
      type: CompletionType.info,
    ).queue(scope);
  }
}
