import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:file/file.dart';
import 'package:pub_semver/pub_semver.dart';

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
import 'releases.dart';

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
  String? get description => existing
      ? 'Updated existing environment `${directory.basename}`'
      : 'Created new environment `${directory.basename}` in `${directory.path}`';
}

class FlutterVersion {
  FlutterVersion({
    required this.commit,
    this.version,
    this.branch,
    this.tag,
  });

  final String commit;
  final Version? version;
  final String? branch;
  final String? tag;

  @override
  String toString() {
    if (tag != null) {
      return 'tags/$tag';
    } else if (version != null) {
      if (branch != null) {
        return '$branch/$version';
      } else {
        return '$version';
      }
    } else {
      return commit;
    }
  }

  FlutterChannel? get channel =>
      branch == null ? null : FlutterChannel.parse(branch!);

  static Future<FlutterVersion> query({
    required Scope scope,
    String? version,
    String? channel,
  }) async {
    if (version == null) {
      if (channel != null) {
        version = channel;
        channel = null;
      } else {
        version = 'stable';
      }
    }

    final config = PuroConfig.of(scope);
    final git = GitClient.of(scope);

    FlutterChannel? parsedChannel;

    if (channel != null) {
      parsedChannel = FlutterChannel.parse(channel);
      if (parsedChannel == null) {
        final allChannels = FlutterChannel.values.map((e) => e.name).join(', ');
        throw ArgumentError(
          'Invalid Flutter channel "$channel", valid channels: $allChannels',
        );
      }
    } else {
      parsedChannel = FlutterChannel.parse(version);
    }

    final parsedVersion = tryParseVersion(version);

    // Check the official releases if a version or channel was given.
    if (parsedVersion != null || parsedChannel != null) {
      if (parsedVersion != null && parsedChannel == FlutterChannel.master) {
        throw ArgumentError(
          'Unexpected version $version, the master channel is not versioned',
        );
      }
      final release = await findFrameworkRelease(
        scope: scope,
        version: parsedVersion,
        channel: parsedChannel,
      );
      return FlutterVersion(
        commit: release.hash,
        version: Version.parse(release.version),
        branch: release.channel,
      );
    }

    Future<FlutterVersion?> checkCache() async {
      // Check if it's a branch
      final repository = config.sharedFlutterDir;
      var result = await git.tryRevParseSingle(
        repository: repository,
        arg: 'origin/$version', // look at origin since it may be untracked
      );
      if (result != null) {
        final isBranch = await git.checkBranchExists(branch: version!);
        return FlutterVersion(
          commit: result,
          branch: isBranch ? version : null,
        );
      }

      // Check if it's a tag
      result = await git.tryRevParseSingle(
        repository: repository,
        arg: 'tags/$version',
      );
      if (result != null) {
        return FlutterVersion(
          commit: result,
          tag: version,
        );
      }

      // Check if it's a commit
      result = await git.tryRevParseSingle(
        repository: repository,
        arg: '$version^{commit}',
      );
      if (result == version) {
        return FlutterVersion(commit: version!);
      }

      return null;
    }

    // Check existing cache
    var cacheResult = await checkCache();
    if (cacheResult != null) return cacheResult;

    // Fetch the framework to scan it
    final sharedRepository = config.sharedFlutterDir;
    await fetchOrCloneShared(
      scope: scope,
      repository: sharedRepository,
      remote: config.flutterGitUrl,
    );

    // Check again after fetching
    cacheResult = await checkCache();
    if (cacheResult != null) return cacheResult;

    throw ArgumentError(
      'Could not find flutter version `$version`, expected a valid commit, branch, tag, or version.',
    );
  }
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
  final environment = config.getEnv(envName);

  log.v('Creating a new environment in ${environment.envDir.path}');

  final existing = environment.envDir.existsSync();
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
    await git.checkout(
      repository: repository,
      ref: flutterVersion.commit,
    );
  });
}
