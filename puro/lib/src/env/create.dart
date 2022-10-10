import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:puro/src/config.dart';
import 'package:puro/src/git.dart';
import 'package:puro/src/logger.dart';
import 'package:puro/src/proto/flutter_releases.pb.dart';
import 'package:puro/src/provider.dart';

import '../../models.dart';
import '../command.dart';
import '../http.dart';

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
      ? 'Updated existing environment `${directory.basename}`.'
      : 'Created new environment `${directory.basename}` in `${directory.path}`.';
}

/// Creates a new Puro environment named [envName] and installs flutter.
Future<EnvCreateResult> createEnvironment({
  required Scope scope,
  required String envName,
  Version? version,
  FlutterChannel? channel,
}) async {
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);
  final env = config.getEnv(envName);

  log.v('Creating a new environment in ${env.envDir.path}');

  final existing = env.envDir.existsSync();
  env.envDir.createSync(recursive: true);

  // Clone flutter
  await cloneFlutterShared(
    scope: scope,
    repository: env.flutterDir,
  );

  return EnvCreateResult(
    success: true,
    existing: existing,
    directory: env.envDir,
  );
}

/// Clones or fetches from a remote, putting it in a shared repository.
Future<Directory> fetchShared({
  required Scope scope,
  required String name,
  required Uri remote,
}) async {
  final config = PuroConfig.of(scope);
  final git = GitClient.of(scope);
  final dir = config.sharedDir.childDirectory(name);

  if (dir.existsSync()) {
    await git.fetch(repository: dir);
  } else {
    await git.clone(
      remote: remote,
      repository: dir,
      shared: true,
    );
  }

  return dir;
}

enum FlutterChannel {
  master,
  dev,
  beta,
  stable;

  static FlutterChannel? fromString(String name) {
    name = name.toLowerCase();
    for (final channel in values) {
      if (channel.name == name) {
        return channel;
      }
    }
    return null;
  }
}

/// Fetches all of the available Flutter versions.
Future<FlutterReleasesModel> fetchFlutterVersions({
  required Scope scope,
  required String platform,
}) async {
  final client = scope.read(clientProvider);
  final config = PuroConfig.of(scope);
  final response = await client.get(config.releasesJsonUrl);
  HttpException.ensureSuccess(response);
  return FlutterReleasesModel.create()
    ..mergeFromProto3Json(jsonDecode(response.body));
}

/// Fetches the available Flutter versions and returns the one matching
/// [version] and [channel], if any.
Future<FlutterReleaseModel?> tryFindFrameworkRelease({
  required Scope scope,
  Version? version,
  FlutterChannel? channel,
}) async {
  final versions = await fetchFlutterVersions(
    scope: scope,
    platform: Platform.operatingSystem,
  );

  if (version == null) {
    final hash = versions.currentRelease[channel ?? 'stable'];
    if (hash == null) return null;
    return versions.releases.firstWhere((r) => r.hash == hash);
  }

  FlutterReleaseModel? result;
  FlutterChannel? resultChannel;
  final versionString = '$version';
  for (final release in versions.releases) {
    if (release.version == versionString ||
        (release.version.startsWith('v') &&
            release.version.substring(1) == versionString)) {
      final releaseChannel = FlutterChannel.fromString(release.channel)!;
      if (channel == releaseChannel) return release;
      if (result == null || releaseChannel.index < resultChannel!.index) {
        result = release;
        resultChannel = releaseChannel;
      }
    }
  }
  return result;
}

/// Same as [tryFindFrameworkRelease] but throws an assertion error if the
/// release couldn't be found.
Future<FlutterReleaseModel> findFrameworkRelease({
  required Scope scope,
  Version? version,
  FlutterChannel? channel,
}) async {
  final release = await tryFindFrameworkRelease(
    scope: scope,
    version: version,
    channel: channel,
  );

  if (release != null) {
    return release;
  }

  if (version == null) {
    channel ??= FlutterChannel.stable;
    throw AssertionError(
      'Could not find latest version of the $channel channel',
    );
  } else if (channel == null) {
    throw AssertionError(
      'Could not find version $version',
    );
  } else {
    throw AssertionError(
      'Could not find version $version in the $channel channel',
    );
  }
}

/// Finds the git ref (branch name or commit hash) corresponding to the Flutter
/// release matching [version] and [channel].
Future<String> findFrameworkRef({
  required Scope scope,
  Version? version,
  FlutterChannel? channel,
}) async {
  if (version == null) {
    return (channel ?? FlutterChannel.stable).name;
  } else {
    if (channel == FlutterChannel.master) {
      throw ArgumentError(
        'Unexpected version $version, the master channel is not versioned',
      );
    }
    final release = await findFrameworkRelease(
      scope: scope,
      version: version,
      channel: channel,
    );
    return release.hash;
  }
}

/// Clone Flutter using git objects from a shared repository.
Future<void> cloneFlutterShared({
  required Scope scope,
  required Directory repository,
  Version? version,
  FlutterChannel? channel,
}) async {
  final git = GitClient.of(scope);
  final config = PuroConfig.of(scope);

  final sharedRepository = await fetchShared(
    scope: scope,
    name: 'flutter',
    remote: config.flutterGitUrl,
  );

  final ref = await findFrameworkRef(
    scope: scope,
    version: version,
    channel: channel,
  );

  if (!repository.existsSync()) {
    await git.clone(
      remote: config.flutterGitUrl,
      repository: repository,
      reference: sharedRepository,
      checkout: false,
    );
  } else {
    await git.fetch(repository: repository);
  }

  await git.checkout(
    repository: repository,
    refname: ref,
  );
}
