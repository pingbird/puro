import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:file/file.dart';

import '../command.dart';
import '../config.dart';
import '../git.dart';
import '../http.dart';
import '../logger.dart';
import '../progress.dart';
import '../provider.dart';
import '../terminal.dart';
import 'engine.dart';
import 'env_shims.dart';
import 'version.dart';

class EnvCreateResult extends CommandResult {
  EnvCreateResult({
    required this.success,
    required this.environment,
  });

  @override
  final bool success;
  final EnvConfig environment;

  @override
  CommandMessage get message => CommandMessage(
        (format) =>
            'Created new environment at `${environment.flutterDir.path}`',
      );
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
  String? forkRemoteUrl,
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
    if (commit != null) {
      throw ArgumentError(
        'Environment `$envName` already exists, use `puro upgrade` to switch version or `puro rm` before trying again',
      );
    }
  }

  environment.envDir.createSync(recursive: true);
  await environment.updatePrefs(
    scope: scope,
    fn: (prefs) {
      prefs.clear();
      prefs.desiredVersion = flutterVersion.toModel();
    },
  );

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
      log.d('Pre-caching engine $engineVersion');
      if (engineVersion == null) {
        return;
      }
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
    forkRemoteUrl: forkRemoteUrl,
  );

  // Replace flutter/dart with shims
  await installEnvShims(
    scope: scope,
    environment: environment,
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
    environment: environment,
  );
}

/// Clones or fetches from a remote, putting it in a shared repository.
Future<void> fetchOrCloneShared({
  required Scope scope,
  required Directory repository,
  required String remoteUrl,
}) async {
  await ProgressNode.of(scope).wrap((scope, node) async {
    final git = GitClient.of(scope);
    final terminal = Terminal.of(scope);
    if (repository.existsSync()) {
      node.description = 'Fetching $remoteUrl';
      await git.fetch(repository: repository);
    } else {
      node.description = 'Cloning $remoteUrl';
      await git.clone(
        remote: remoteUrl,
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
  String? forkRemoteUrl,
}) async {
  final git = GitClient.of(scope);
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);

  log.v('Cloning flutter with shared refs');
  log.d('repository: ${repository.path}');
  log.d('flutterVersion: $flutterVersion');

  final sharedRepository = config.sharedFlutterDir;
  if (!await isSharedFlutterCommitCached(
    scope: scope,
    commit: flutterVersion.commit,
  )) {
    await fetchOrCloneShared(
      scope: scope,
      repository: sharedRepository,
      remoteUrl: config.flutterGitUrl,
    );
  }

  await ProgressNode.of(scope).wrap((scope, node) async {
    node.description = 'Initializing repository';

    final origin = forkRemoteUrl ?? config.flutterGitUrl;
    final upstream = forkRemoteUrl == null ? null : config.flutterGitUrl;

    final remotes = {
      if (upstream != null) 'upstream': GitRemoteUrls.single(upstream),
      'origin': GitRemoteUrls.single(origin),
    };

    if (!repository.childDirectory('.git').existsSync()) {
      repository.createSync(recursive: true);
      await git.init(repository: repository);
    }
    final alternatesFile = repository
        .childDirectory('.git')
        .childDirectory('objects')
        .childDirectory('info')
        .childFile('alternates');
    final sharedObjects =
        sharedRepository.childDirectory('.git').childDirectory('objects');
    alternatesFile.writeAsStringSync('${sharedObjects.path}\n');
    await git.syncRemotes(repository: repository, remotes: remotes);

    final cacheDir = repository.childDirectory('bin').childDirectory('cache');
    // Delete the cache when we switch versions so that the new version doesn't
    // accidentally corrupt the shared engine.
    if (cacheDir.existsSync()) {
      // Not recursive because we are deleting a symlink.
      cacheDir.deleteSync();
    }

    node.description = 'Checking out $flutterVersion';

    // If the target is the master branch, attempt to track the origin. We don't
    // do this for other branches because the flutter tool might upgrade itself
    // from stable/beta and corrupt shared caches.
    final branch = flutterVersion.branch;
    if (forkRemoteUrl != null && branch == 'master') {
      await git.fetch(
        repository: repository,
        all: true,
      );
      final originCommit = await git.getCurrentCommitHash(
        repository: repository,
        branch: 'origin/$branch',
      );
      log.d('originCommit: $originCommit');
      log.d('flutterVersion.commit: ${flutterVersion.commit}');

      if (originCommit == flutterVersion.commit) {
        await git.checkout(
          repository: repository,
          ref: 'origin/$branch',
          track: true,
        );
        return;
      }

      final upstreamCommit = await git.getCurrentCommitHash(
        repository: sharedRepository,
        branch: 'origin/$branch',
      );
      log.d('upstreamCommit: $upstreamCommit');

      if (flutterVersion.commit == upstreamCommit) {
        await git.checkout(
          repository: repository,
          ref: 'origin/$branch',
          track: true,
        );
        if (originCommit != upstreamCommit) {
          await git.merge(
            repository: repository,
            fromCommit: 'upstream/$branch',
            fastForwardOnly: true,
          );
        }
        return;
      }
    }

    // Check out in a detached state.
    await git.checkout(
      repository: repository,
      ref: flutterVersion.commit,
    );
  });
}
