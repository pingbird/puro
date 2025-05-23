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

/// Updates the engine version file, to replicate the functionality of
/// https://github.com/flutter/flutter/blob/master/bin/internal/update_engine_version.sh
/// See script details at https://github.com/flutter/flutter/issues/163896
Future<void> updateEngineVersionFile({
  required Scope scope,
  required FlutterConfig flutterConfig,
}) async {
  if (!flutterConfig.hasEngine) {
    // Not a monolithic engine, nothing to do.
    return;
  }

  final git = GitClient.of(scope);
  final remotes = await git.getRemotes(repository: flutterConfig.sdkDir);

  final String commit;

  // Check if this is a fork (has an upstream)
  if (remotes.containsKey('upstream')) {
    // Fetch, otherwise merge-base will fail on the first run
    if (!await git.checkCommitExists(
      repository: flutterConfig.sdkDir,
      commit: 'upstream/master',
    )) {
      await git.fetch(
        repository: flutterConfig.sdkDir,
        remote: 'upstream',
        all: true,
      );
    }
    commit = await git.mergeBase(
        repository: flutterConfig.sdkDir,
        ref1: 'HEAD',
        ref2: 'upstream/master');
  } else {
    commit = await git.mergeBase(
        repository: flutterConfig.sdkDir, ref1: 'HEAD', ref2: 'origin/master');
  }

  flutterConfig.engineVersionFile.writeAsStringSync('$commit\n');
}

Future<String?> getEngineVersion({
  required Scope scope,
  required FlutterConfig flutterConfig,
}) async {
  final git = GitClient.of(scope);
  final result = await git.tryCat(
    repository: flutterConfig.sdkDir,
    path: 'bin/internal/engine.version',
    ref: 'HEAD',
  );
  if (result == null) {
    await updateEngineVersionFile(scope: scope, flutterConfig: flutterConfig);
  }

  return flutterConfig.engineVersion;
}

/// Checks if a framework commit is a monorepo and has the engine in it.
Future<bool?> isCommitMonolithicEngine({
  required Scope scope,
  required String commit,
}) async {
  final config = PuroConfig.of(scope);
  final git = GitClient.of(scope);
  final http = scope.read(clientProvider);
  final sharedRepository = config.sharedFlutterDir;
  final result = await git.exists(
    repository: sharedRepository,
    path: 'engine/src/.gn',
    ref: commit,
  );
  if (result) return true;
  // 'exists' can return false if git show failed for some reason, so we also
  // check if the repository has a README.md to rule that out.
  if (await git.exists(
    repository: sharedRepository,
    path: 'README.md',
    ref: commit,
  )) {
    return false;
  }
  // Fall back to checking with HTTP
  final url = config.tryGetFlutterGitDownloadUrl(
    commit: commit,
    path: 'engine/src/.gn',
  );
  if (url == null) return null;
  final response = await http.head(url);
  if (response.statusCode == 200) return true;
  if (response.statusCode == 404) return false;
  HttpException.ensureSuccess(response);
  return null;
}

/// Attempts to get the engine version of a flutter commit. This is only used
/// for precaching the engine before cloning flutter. For an existing checkout
/// use [FlutterConfig.engineVersion] instead.
Future<String?> getEngineVersionOfCommit({
  required Scope scope,
  required String commit,
}) async {
  if (await isCommitMonolithicEngine(scope: scope, commit: commit) ?? false) {
    return commit;
  }

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
  FlutterVersion? flutterVersion,
  String? forkRemoteUrl,
  String? forkRef,
}) async {
  if ((flutterVersion == null) == (forkRemoteUrl == null)) {
    throw AssertionError(
      'Exactly one of flutterVersion and forkRemoteUrl should be provided',
    );
  }

  if (isValidVersion(envName) &&
      (flutterVersion == null ||
          flutterVersion.version == null ||
          envName != '${flutterVersion.version}')) {
    throw CommandError(
      'Cannot create environment $envName with version ${flutterVersion?.name}',
    );
  }

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
        if (flutterVersion != null) {
          prefs.desiredVersion = flutterVersion.toModel();
        }
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
          commit: flutterVersion!.commit,
        );
        log.d('Pre-caching engine $engineVersion');
        if (engineVersion == null) {
          return;
        }
        await downloadSharedEngine(
          scope: scope,
          engineCommit: engineVersion,
        );
        cacheEngineTime = clock.now();
      },
      // The user probably already has flutter cached so cloning forks will be
      // fast, no point in optimizing this.
      skip: forkRemoteUrl != null,
    );

    // Clone flutter
    await cloneFlutterWithSharedRefs(
      scope: scope,
      repository: environment.flutterDir,
      environment: environment,
      flutterVersion: flutterVersion,
      forkRemoteUrl: forkRemoteUrl,
      forkRef: forkRef,
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
  final git = GitClient.of(scope);
  if (repository.existsSync()) {
    await ProgressNode.of(scope).wrap((scope, node) async {
      node.description = 'Fetching $remoteUrl';
      await git.fetch(repository: repository);
    });
  } else {
    await git.cloneWithProgress(
      remote: remoteUrl,
      repository: repository,
      shared: true,
      checkout: false,
    );
  }
}

/// Checks out Flutter using git objects from a shared repository.
Future<void> cloneFlutterWithSharedRefs({
  required Scope scope,
  required Directory repository,
  required EnvConfig environment,
  FlutterVersion? flutterVersion,
  String? forkRemoteUrl,
  String? forkRef,
  bool force = false,
}) async {
  final git = GitClient.of(scope);
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);

  log.v('Cloning flutter with shared refs');
  log.d('repository: ${repository.path}');
  log.d('flutterVersion: $flutterVersion');
  log.d('forkRemoteUrl: $flutterVersion');
  log.d('forkRef: $forkRef');

  if ((flutterVersion == null) == (forkRemoteUrl == null)) {
    throw AssertionError(
      'Exactly one of flutterVersion and forkRemoteUrl should be provided',
    );
  }

  final sharedRepository = config.sharedFlutterDir;

  // Set the remotes, git alternates, and unlink the cache.
  Future<void> initialize() async {
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

    // Delete the cache when we switch versions so the new version doesn't
    // accidentally corrupt the shared engine.
    final cacheDir = repository.childDirectory('bin').childDirectory('cache');
    if (cacheDir.existsSync()) {
      log.d('Deleting ${cacheDir.path} from previous version');
      cacheDir.deleteSync(recursive: true);
    }
  }

  Future<void> guardCheckout(Future<void> Function() fn) async {
    // Uninstall shims so they don't interfere with merges (this technically
    // shouldn't happen with our attribute merge strategies, but w/e)
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

  // Cloning a fork is a little simpler, we don't need to reset the branch to
  // fit a specific flutter version
  if (forkRemoteUrl != null) {
    await fetchOrCloneShared(
      scope: scope,
      repository: sharedRepository,
      remoteUrl: config.flutterGitUrl,
    );

    await ProgressNode.of(scope).wrap((scope, node) async {
      node.description = 'Initializing repository';

      await initialize();

      node.description = 'Fetching $forkRef';

      await git.fetch(repository: repository);

      forkRef ??= await git.getDefaultBranch(repository: repository);

      node.description = 'Checking out $forkRef';

      await guardCheckout(() async {
        await git.checkout(
          repository: repository,
          ref: forkRef,
          force: force,
        );
      });
    });

    return;
  }

  if (!await git.checkCommitExists(
    repository: config.sharedFlutterDir,
    commit: flutterVersion!.commit,
  )) {
    await fetchOrCloneShared(
      scope: scope,
      repository: sharedRepository,
      remoteUrl: config.flutterGitUrl,
    );
  }

  await ProgressNode.of(scope).wrap((scope, node) async {
    node.description = 'Initializing repository';

    await initialize();

    node.description = 'Checking out $flutterVersion';

    await git.fetch(
      repository: repository,
      all: true,
    );

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
            // We are forcefully upgrading, ditch uncommitted changes.
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
      await guardCheckout(() async {
        // Check out in a detached state, flutter will be unable to detect its
        // version.
        await git.checkout(
          repository: repository,
          ref: flutterVersion.commit,
          force: force,
        );
      });
    }
  });
}
