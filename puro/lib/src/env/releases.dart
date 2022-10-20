import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:pub_semver/pub_semver.dart';

import '../config.dart';
import '../file_lock.dart';
import '../git.dart';
import '../http.dart';
import '../progress.dart';
import '../proto/flutter_releases.pb.dart';
import '../provider.dart';

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

/// Fetches all of the available Flutter releases.
Future<FlutterReleasesModel> fetchFlutterReleases({
  required Scope scope,
}) async {
  return ProgressNode.of(scope).wrap((scope, node) async {
    final client = scope.read(clientProvider);
    final config = PuroConfig.of(scope);
    node.description = 'Fetching ${config.releasesJsonUrl}';
    final response = await client.get(config.releasesJsonUrl);
    HttpException.ensureSuccess(response);
    config.cachedReleasesJsonFile.parent.createSync(recursive: true);
    await writeFileAtomic(
      scope: scope,
      bytes: response.bodyBytes,
      file: config.cachedReleasesJsonFile,
    );
    return FlutterReleasesModel.create()
      ..mergeFromProto3Json(jsonDecode(response.body));
  });
}

/// Searches [releases] for a specific version and/or channel.
FlutterReleaseModel? searchFlutterVersions({
  required FlutterReleasesModel releases,
  Version? version,
  FlutterChannel? channel,
}) {
  if (version == null) {
    final hash = releases.currentRelease[channel ?? 'stable'];
    if (hash == null) return null;
    return releases.releases.firstWhere((r) => r.hash == hash);
  }

  FlutterReleaseModel? result;
  FlutterChannel? resultChannel;
  final versionString = '$version';
  for (final release in releases.releases) {
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

/// Finds a framework release matching [version] and/or [channel], pulling from
/// a cache when possible.
Future<FlutterReleaseModel> findFrameworkRelease({
  required Scope scope,
  Version? version,
  FlutterChannel? channel,
}) async {
  final config = PuroConfig.of(scope);

  // Default to the stable channel
  if (channel == null && version == null) {
    channel = FlutterChannel.stable;
  }

  final cachedReleasesStat = config.cachedReleasesJsonFile.statSync();
  final hasCache = cachedReleasesStat.type == FileSystemEntityType.file;
  final cacheIsFresh = hasCache &&
      clock.now().difference(cachedReleasesStat.modified).inHours < 1;
  final isChannelOnly = channel != null && version == null;

  // Don't fetch from the cache if it's stale and we are looking for the latest
  // release.
  if (!isChannelOnly || cacheIsFresh) {
    FlutterReleasesModel? cachedReleases;
    await ProgressNode.of(scope).wrap(
      (scope, node) async {
        return lockFile(
          scope,
          config.cachedReleasesJsonFile,
          (handle) async {
            final contents = await handle.read(handle.lengthSync());
            final contentsString = utf8.decode(contents);
            cachedReleases = FlutterReleasesModel.create()
              ..mergeFromProto3Json(jsonDecode(contentsString));
          },
          exclusive: false,
        );
      },
      optional: true,
    );
    if (cachedReleases != null) {
      final foundRelease = searchFlutterVersions(
        releases: cachedReleases!,
        version: version,
        channel: channel,
      );
      if (foundRelease != null) return foundRelease;
    }
  }

  // Fetch new releases as long as the cache isn't stale.
  if (!cacheIsFresh) {
    final foundRelease = searchFlutterVersions(
      releases: await fetchFlutterReleases(scope: scope),
      version: version,
      channel: channel,
    );
    if (foundRelease != null) return foundRelease;
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

/// Attempts to find the current flutter channel.
Future<FlutterChannel?> getFlutterChannel({
  required Scope scope,
  required FlutterConfig config,
}) async {
  final git = GitClient.of(scope);
  final branch = await git.getBranch(repository: config.sdkDir);
  if (branch == null) return null;
  return FlutterChannel.fromString(branch);
}
