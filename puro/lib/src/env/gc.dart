import 'package:file/file.dart';

import '../config.dart';
import '../logger.dart';
import '../provider.dart';

Future<int> collectGarbage({
  required Scope scope,
  int maxUnusedCaches = 0,
}) async {
  final log = PuroLogger.of(scope);
  final config = PuroConfig.of(scope);
  final sharedCacheDirs = config.sharedCachesDir.listSync();
  if (sharedCacheDirs.length < maxUnusedCaches) {
    // Don't bother cleaning up if there are less than maxUnusedCaches
    return 0;
  }
  final usedCaches = <String>{};
  for (final dir in config.envsDir.listSync()) {
    if (dir is! Directory || !isValidName(dir.basename)) {
      continue;
    }
    final environment = config.getEnv(dir.basename);
    final engineVersion = environment.flutter.engineVersion;
    if (engineVersion != null) {
      usedCaches.add(engineVersion);
    }
  }
  final unusedCaches = <Directory, DateTime>{};
  for (final dir in sharedCacheDirs) {
    if (dir is! Directory ||
        !isValidCommitHash(dir.basename) ||
        usedCaches.contains(dir.basename)) continue;
    final config = FlutterCacheConfig(dir);
    unusedCaches[dir] = config.engineVersionFile.lastAccessedSync();
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
  final entries = unusedCaches.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  for (var i = 0; i < entries.length - maxUnusedCaches; i++) {
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
