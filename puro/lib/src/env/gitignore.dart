import 'dart:convert';

import '../config.dart';
import '../logger.dart';
import '../provider.dart';

const ignoredFiles = {PuroConfig.dotfileName};
const ignoreComment = '# Managed by puro';

Future<void> installGitignore({required Scope scope}) async {
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);
  final projectDir = config.projectDir;
  if (projectDir == null) return;
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
    if (lines[i] == ignoreComment && i + 1 < lines.length) {
      existingIgnores.add(lines[i + 1]);
      lines.removeAt(i);
      lines.removeAt(i);
    } else {
      i++;
    }
  }
  while (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
  if (!existingIgnores.containsAll(ignoredFiles)) {
    log.v('Updating gitignore of ${gitTree.path}');
    excludeFile.writeAsStringSync([
      ...lines,
      '',
      for (final name in ignoredFiles) ...[ignoreComment, name],
    ].join('\n'));
    log.v('Added ${PuroConfig.dotfileName} to .git/info/exclude');
  }
}
