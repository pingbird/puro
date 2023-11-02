import 'dart:convert';
import 'dart:typed_data';

import '../config.dart';
import '../env/create.dart';
import '../git.dart';
import '../http.dart';
import '../provider.dart';

Future<String> getEngineDartCommit({
  required Scope scope,
  required String engineCommit,
}) async {
  final config = PuroConfig.of(scope);
  final git = GitClient.of(scope);
  final http = scope.read(clientProvider);
  final sharedRepository = config.sharedEngineDir;

  String parseDEPS(Uint8List result) {
    final lines = utf8.decode(result).split('\n');
    for (final line in lines) {
      if (line.startsWith('  "dart_revision":')) {
        return line.split('"')[3];
      }
    }
    throw AssertionError('Failed to parse DEPS for $engineCommit');
  }

  if (sharedRepository.existsSync()) {
    var result = await git.tryCat(repository: sharedRepository, path: 'DEPS');
    if (result != null) {
      return parseDEPS(result);
    }
    await git.fetch(repository: sharedRepository);
    result = await git.tryCat(repository: sharedRepository, path: 'DEPS');
    if (result != null) {
      return parseDEPS(result);
    }
  }

  final depsUrl = config.tryGetEngineGitDownloadUrl(
    commit: engineCommit,
    path: 'DEPS',
  );

  if (depsUrl != null) {
    final response = await http.get(depsUrl);
    HttpException.ensureSuccess(response);
    return parseDEPS(response.bodyBytes);
  }

  await fetchOrCloneShared(
    scope: scope,
    repository: sharedRepository,
    remoteUrl: config.engineGitUrl,
  );

  // Try again after cloning the repository
  return getEngineDartCommit(
    scope: scope,
    engineCommit: engineCommit,
  );
}
