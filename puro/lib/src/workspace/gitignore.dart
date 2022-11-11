import 'dart:convert';

import 'package:file/file.dart';

import '../config.dart';
import '../logger.dart';
import '../provider.dart';

const gitIgnoredFilesForWorkspace = {PuroConfig.dotfileName};
const gitIgnoreComment = '# Managed by puro';

/// Adds the dotfile to .git/info/exclude which is a handy way to ignore it
/// without touching the working tree or global git configuration.
Future<void> updateGitignore({
  required Scope scope,
  required Directory projectDir,
  required Set<String> ignores,
}) async {
  final log = PuroLogger.of(scope);
  final gitTree = findProjectDir(projectDir, '.git');
  if (gitTree == null) return;
  final excludeFile = gitTree
      .childDirectory('.git')
      .childDirectory('info')
      .childFile('exclude');
  excludeFile.createSync(recursive: true);
  final lines = const LineSplitter().convert(excludeFile.readAsStringSync());
  final existingIgnores = <String>{};
  for (var i = 0; i < lines.length;) {
    if (lines[i] == gitIgnoreComment && i + 1 < lines.length) {
      existingIgnores.add(lines[i + 1]);
      lines.removeAt(i);
      lines.removeAt(i);
    } else {
      i++;
    }
  }
  while (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
  if (!existingIgnores.containsAll(ignores) ||
      existingIgnores.length != ignores.length) {
    log.v('Updating gitignore of ${gitTree.path}');
    excludeFile.writeAsStringSync([
      ...lines,
      '',
      for (final name in ignores) ...[gitIgnoreComment, name],
    ].join('\n'));
    if (ignores.isEmpty) {
      log.v('Removed ${PuroConfig.dotfileName} from .git/info/exclude');
    } else {
      log.v('Added ${PuroConfig.dotfileName} to .git/info/exclude');
    }
  }
}
