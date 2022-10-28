import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:file/file.dart';

import '../../models.dart';
import '../command.dart';
import '../config.dart';
import '../git.dart';
import '../http.dart';
import '../logger.dart';
import '../progress.dart';
import '../provider.dart';
import '../terminal.dart';
import 'engine.dart';
import 'version.dart';

class EnvCreateResult extends CommandResult {
  EnvCreateResult({
    required this.success,
    required this.existing,
    required this.directory,
  });

  final bool success;
  final bool existing;
  final Directory directory;

  @override
  CommandResultModel toModel() {
    return CommandResultModel(success: success);
  }

  @override
  String description(OutputFormatter format) => existing
      ? 'Re-created existing environment `${directory.basename}`'
      : 'Created environment `${directory.basename}` in `${directory.path}`';
}

/// Attempts to get the engine version of a flutter commit.
Future<String?> getEngineVersionOfCommit({
  required Scope scope,
  required String commit,
}) async {
  final config = PuroConfig.of(scope);
  final git = GitClient.of(scope);
  final http = scope.read(clientProvider);
  final sharedRepository = config.sharedFlutterDir;
  final result = await git.tryCat(
    repository: sharedRepository,
    path: 'bin/internal/engine.version',
    ref: commit,
  );
  if (result != null) {
    return utf8.decode(result).trim();
  }
  final url = config.tryGetFlutterGitDownloadUrl(
    commit: commit,
    path: 'bin/internal/engine.version',
  );
  if (url == null) return null;
  final response = await http.get(url);
  HttpException.ensureSuccess(response);
  return response.body.trim();
}

/// Creates a new Puro environment named [envName] and installs flutter.
Future<EnvCreateResult> createEnvironment({
  required Scope scope,
  required String envName,
  required FlutterVersion flutterVersion,
}) async {
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);
  final git = GitClient.of(scope);
  final environment = config.getEnv(envName);

  log.v('Creating a new environment in ${environment.envDir.path}');

  final existing = environment.envDir.existsSync();

  if (existing && environment.flutterDir.existsSync()) {
    final commit = await git.tryGetCurrentCommitHash(
      repository: environment.flutterDir,
    );
    if (commit != null && commit != flutterVersion.commit) {
      throw ArgumentError(
        'Environment `$envName` already exists, use `puro upgrade` to switch version',
      );
    }
  }

  environment.envDir.createSync(recursive: true);

  final startTime = clock.now();
  DateTime? cacheEngineTime;

  final engineTask = runOptional(
    scope,
    'Pre-caching engine',
    () async {
      final engineVersion = await getEngineVersionOfCommit(
        scope: scope,
        commit: flutterVersion.commit,
      );
      if (engineVersion == null) return;
      await downloadSharedEngine(
        scope: scope,
        engineVersion: engineVersion,
      );
      cacheEngineTime = clock.now();
    },
  );

  // Clone flutter
  await cloneFlutterWithSharedRefs(
    scope: scope,
    repository: environment.flutterDir,
    flutterVersion: flutterVersion,
  );

  final cloneTime = clock.now();

  await engineTask;

  if (cacheEngineTime != null) {
    final wouldveTaken = (cloneTime.difference(startTime)) +
        (cacheEngineTime!.difference(startTime));
    final took = clock.now().difference(startTime);
    log.v(
      'Saved ${(wouldveTaken - took).inMilliseconds}ms by pre-caching engine',
    );
  }

  // Set up engine and compile tool
  await setUpFlutterTool(
    scope: scope,
    environment: environment,
  );

  return EnvCreateResult(
    success: true,
    existing: existing,
    directory: environment.envDir,
  );
}

/// Clones or fetches from a remote, putting it in a shared repository.
Future<void> fetchOrCloneShared({
  required Scope scope,
  required Directory repository,
  required String remote,
}) async {
  await ProgressNode.of(scope).wrap((scope, node) async {
    final git = GitClient.of(scope);
    final terminal = Terminal.of(scope);
    if (repository.existsSync()) {
      node.description = 'Fetching $remote';
      await git.fetch(repository: repository);
    } else {
      node.description = 'Cloning $remote';
      await git.clone(
        remote: remote,
        repository: repository,
        shared: true,
        checkout: false,
        onProgress: terminal.enableStatus ? node.onCloneProgress : null,
      );
    }
  });
}

/// Checks if the specified commit exists in the shared cache.
Future<bool> isSharedFlutterCommitCached({
  required Scope scope,
  required String commit,
}) async {
  final git = GitClient.of(scope);
  final config = PuroConfig.of(scope);
  final sharedRepository = config.sharedFlutterDir;
  if (!sharedRepository.existsSync()) return false;
  final result = await git.tryRevParseSingle(
    repository: sharedRepository,
    arg: commit,
  );
  return result == commit;
}

/// Clone Flutter using git objects from a shared repository.
Future<void> cloneFlutterWithSharedRefs({
  required Scope scope,
  required Directory repository,
  required FlutterVersion flutterVersion,
}) async {
  final git = GitClient.of(scope);
  final config = PuroConfig.of(scope);

  final sharedRepository = config.sharedFlutterDir;
  if (!await isSharedFlutterCommitCached(
    scope: scope,
    commit: flutterVersion.commit,
  )) {
    await fetchOrCloneShared(
      scope: scope,
      repository: sharedRepository,
      remote: config.flutterGitUrl,
    );
  }

  await ProgressNode.of(scope).wrap((scope, node) async {
    node.description = 'Checking out $flutterVersion from cache';
    if (!repository.childDirectory('.git').existsSync()) {
      repository.createSync(recursive: true);
      await git.init(repository: repository);
      final alternatesFile = repository
          .childDirectory('.git')
          .childDirectory('objects')
          .childDirectory('info')
          .childFile('alternates');
      final sharedObjects =
          sharedRepository.childDirectory('.git').childDirectory('objects');
      alternatesFile.writeAsStringSync('${sharedObjects.path}\n');
      await git.addRemote(
        repository: repository,
        remote: config.flutterGitUrl,
        fetch: true,
      );
    } else {
      await git.fetch(repository: repository);
    }

    final cacheDir = repository.childDirectory('bin').childDirectory('cache');
    // Delete the cache when we switch versions so that the new version doesn't
    // accidentally corrupt the shared engine.
    if (cacheDir.existsSync()) {
      // Not recursive because we are deleting a symlink.
      cacheDir.deleteSync();
    }

    await git.checkout(
      repository: repository,
      ref: flutterVersion.commit,
    );
  });
}
