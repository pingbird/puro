import 'package:file/file.dart';

import '../config.dart';
import '../git.dart';
import '../logger.dart';
import '../provider.dart';

Future<int> collectGarbage({
  required Scope scope,
  int maxUnusedCaches = 5,
  int maxUnusedFlutterTools = 5,
}) async {
  final log = PuroLogger.of(scope);
  final config = PuroConfig.of(scope);
  final git = GitClient.of(scope);
  final sharedCacheDirs = config.sharedCachesDir.existsSync()
      ? config.sharedCachesDir.listSync()
      : [];
  final flutterToolDirs = config.sharedFlutterToolsDir.existsSync()
      ? config.sharedFlutterToolsDir.listSync()
      : [];
  if (sharedCacheDirs.length < maxUnusedCaches &&
      flutterToolDirs.length < maxUnusedFlutterTools) {
    // Don't bother cleaning up if there are less than maxUnusedCaches
    return 0;
  }
  final usedCaches = <String>{};
  final usedCommits = <String>{};
  for (final dir in config.envsDir.listSync()) {
    if (dir is! Directory || !isValidEnvName(dir.basename)) {
      continue;
    }
    final environment = config.getEnv(dir.basename);
    final engineVersion = environment.flutter.engineVersion;
    if (engineVersion != null) {
      usedCaches.add(engineVersion);
    }

    final commit = await git.tryGetCurrentCommitHash(
      repository: environment.flutterDir,
    );
    if (commit != null) {
      usedCommits.add(commit);
    }
  }

  final unusedCaches = <Directory, DateTime>{};
  for (final dir in sharedCacheDirs) {
    if (dir is! Directory ||
        !isValidCommitHash(dir.basename) ||
        usedCaches.contains(dir.basename))
      continue;
    final config = FlutterCacheConfig(dir);
    final versionFile = config.engineVersionFile;
    if (versionFile.existsSync()) {
      unusedCaches[dir] = config.engineVersionFile.lastAccessedSync();
    } else {
      // Perhaps a delete was incomplete? The cache is invalid without an
      // engine version file regardless.
      unusedCaches[dir] = DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  final unusedFlutterTools = <Directory, DateTime>{};
  for (final dir in flutterToolDirs) {
    if (dir is! Directory ||
        !isValidCommitHash(dir.basename) ||
        usedCommits.contains(dir.basename))
      continue;
    final snapshotFile = dir.childFile('flutter_tool.snapshot');
    if (snapshotFile.existsSync()) {
      unusedFlutterTools[dir] = snapshotFile.lastAccessedSync();
    } else {
      unusedCaches[dir] = DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  Future<int> deleteRecursive(FileSystemEntity entity) async {
    final stat = entity.statSync();
    if (stat.type == FileSystemEntityType.notFound) {
      return 0;
    }
    var size = stat.size;
    if (entity is Directory && stat.type == FileSystemEntityType.directory) {
      await for (final child in entity.list()) {
        size += await deleteRecursive(child);
      }
    }
    // This shouldn't need to be recursive but I saw a "Directory not empty"
    // error in the wild.
    entity.deleteSync(recursive: true);
    return size;
  }

  var reclaimed = 0;

  // In theory this should be the access times in ascending order but I never
  // tested it (famous last words)
  var entries = unusedCaches.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  for (var i = 0; i < entries.length - maxUnusedCaches; i++) {
    final dir = entries[i].key;
    log.v('Deleting ${dir.path}');
    reclaimed += await deleteRecursive(dir);
  }

  // Same thing for snapshot files
  entries = unusedFlutterTools.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  for (var i = 0; i < entries.length - maxUnusedFlutterTools; i++) {
    final dir = entries[i].key;
    log.v('Deleting ${dir.path}');
    reclaimed += await deleteRecursive(dir);
  }

  for (final zipFile in sharedCacheDirs) {
    if (zipFile is! File || !zipFile.basename.endsWith('.zip')) continue;
    reclaimed += await deleteRecursive(zipFile);
  }

  return reclaimed;
}
