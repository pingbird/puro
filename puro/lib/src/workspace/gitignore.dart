import 'dart:convert';

import 'package:file/file.dart';

import '../config.dart';
import '../extensions.dart';
import '../logger.dart';
import '../provider.dart';

const gitIgnoredFilesForWorkspace = {ProjectConfig.dotfileName};
const gitConfigComment = '# Managed by puro';

Future<void> updateConfigLines({
  required Scope scope,
  required File file,
  required Set<String> lines,
}) async {
  file.createSync(recursive: true);
  final log = PuroLogger.of(scope);
  final result = const LineSplitter().convert(file.readAsStringSync());
  final existingLines = <String>{};
  for (var i = 0; i < result.length;) {
    if (result[i] == gitConfigComment && i + 1 < result.length) {
      existingLines.add(result[i + 1]);
      result.removeAt(i);
      result.removeAt(i);
    } else {
      i++;
    }
  }
  while (result.isNotEmpty && result.last.isEmpty) result.removeLast();
  if (!existingLines.containsAll(lines) ||
      existingLines.length != lines.length) {
    log.v('Updating config at ${file.path}');
    file.writeAsStringSync(<String>[
      ...result,
      '',
      for (final name in lines) ...[gitConfigComment, name],
    ].join('\n'));
    for (final line in lines) {
      if (!existingLines.contains(line)) {
        log.v('Added "$line"');
      }
    }
    for (final line in existingLines) {
      if (!lines.contains(line)) {
        log.v('Removed "$line"');
      }
    }
  }
}

Directory? findGitDir(Directory projectDir) {
  final fileSystem = projectDir.fileSystem;
  final gitTree = findProjectDir(projectDir, '.git');
  if (gitTree == null) return null;
  final gitDir = gitTree.childDirectory('.git');
  if (fileSystem.statSync(gitDir.path).type == FileSystemEntityType.file) {
    final match = RegExp(r'gitdir: (.+)')
        .firstMatch(fileSystem.file(gitDir.path).readAsStringSync().trim());
    if (match != null) {
      final gitTree2 =
          findProjectDir(fileSystem.directory(match.group(1)!), '.git');
      if (gitTree2 != null) {
        return gitTree2.childDirectory('.git').resolve();
      }
    }
    return null;
  } else {
    return gitDir.resolve();
  }
}

/// Adds the dotfile to .git/info/exclude which is a handy way to ignore it
/// without touching the working tree or global git configuration.
Future<void> updateGitignore({
  required Scope scope,
  required Directory projectDir,
  required Set<String> ignores,
}) async {
  final gitDir = findGitDir(projectDir);
  if (gitDir == null) return;
  final log = PuroLogger.of(scope);
  log.v('Updating ${gitDir.path}/info/exclude');
  await updateConfigLines(
    scope: scope,
    file: gitDir.childDirectory('info').childFile('exclude'),
    lines: ignores,
  );
}

Future<void> updateGitAttributes({
  required Scope scope,
  required Directory projectDir,
  required Map<String, String> attributes,
}) async {
  final gitTree = findProjectDir(projectDir, '.git');
  if (gitTree == null) return;
  await updateConfigLines(
    scope: scope,
    file: gitTree
        .childDirectory('.git')
        .childDirectory('info')
        .childFile('attributes'),
    lines: {
      for (final entry in attributes.entries) '${entry.key} ${entry.value}',
    },
  );
}
