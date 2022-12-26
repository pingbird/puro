import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:file/file.dart';

import '../command_result.dart';
import '../config.dart';
import '../file_lock.dart';
import '../git.dart';
import '../http.dart';
import '../logger.dart';
import '../progress.dart';
import '../provider.dart';
import '../terminal.dart';
import 'default.dart';
import 'engine.dart';
import 'env_shims.dart';
import 'flutter_tool.dart';
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
      throw CommandError(
        'Environment `$envName` already exists, use `puro upgrade` to switch '
        'version or `puro rm` before trying again',
      );
    }
  }

  environment.updateLockFile.parent.createSync(recursive: true);
  await lockFile(scope, environment.updateLockFile, (lockHandle) async {
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
      environment: environment,
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
  });

  // In case we are creating the default environment
  await updateDefaultEnvSymlink(scope: scope);

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
  required EnvConfig environment,
  required FlutterVersion flutterVersion,
  String? forkRemoteUrl,
  bool force = false,
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
      // Not recursive because cacheDir is a symlink.
      cacheDir.deleteSync();
    }

    node.description = 'Checking out $flutterVersion';

    await git.fetch(
      repository: repository,
      all: true,
    );

    Future<void> guardCheckout(Future<void> Function() fn) async {
      // Uninstall shims so they don't interfere with merges
      await uninstallEnvShims(scope: scope, environment: environment);
      try {
        await fn();
      } catch (exception, stackTrace) {
        throw CommandError.list([
          CommandMessage(
            'To overwrite local changes, try passing --force',
            type: CompletionType.info,
          ),
          CommandMessage('$exception\n$stackTrace'),
        ]);
      } finally {
        await installEnvShims(scope: scope, environment: environment);
      }
    }

    final branch = flutterVersion.branch;
    if (branch != null) {
      // Unstage changes, excluded files may have been added by accident.
      await git.reset(repository: repository);

      final currentBranch = await git.getBranch(repository: repository);

      if (branch == currentBranch) {
        // Reset the current branches commit to the target commit, attempt to
        // merge uncomitted changes.
        if (force) {
          if (!await git.tryReset(
            repository: repository,
            ref: flutterVersion.commit,
            merge: true,
          )) {
            // We are forcefully upgrading, ditch uncomitted changes.
            await git.reset(
              repository: repository,
              ref: flutterVersion.commit,
              hard: true,
            );
          }
        } else {
          await guardCheckout(() async {
            await git.reset(
              repository: repository,
              ref: flutterVersion.commit,
              merge: true,
            );
          });
        }
      } else {
        // Delete the target branch if it exists (unless we are on a fork).
        if (await git.checkBranchExists(
              repository: repository,
              branch: branch,
            ) &&
            forkRemoteUrl == null) {
          await git.deleteBranch(repository: repository, branch: branch);
        }

        await guardCheckout(() async {
          // Reset branch to current commit, this allows flutter to correctly detect
          // its version and feature flags.
          await git.checkout(
            repository: repository,
            newBranch: branch,
            ref: flutterVersion.commit,
            force: force,
          );
        });
      }

      await git.branch(
        repository: repository,
        setUpstream: 'origin/$branch',
        branch: branch,
      );
    } else {
      // Check out in a detached state, flutter will be unable to detect its
      // version.
      await git.checkout(
        repository: repository,
        ref: flutterVersion.commit,
      );
    }
  });
}
