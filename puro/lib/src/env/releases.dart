import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:pub_semver/pub_semver.dart';

import '../command_result.dart';
import '../config.dart';
import '../extensions.dart';
import '../file_lock.dart';
import '../git.dart';
import '../http.dart';
import '../logger.dart';
import '../progress.dart';
import '../proto/flutter_releases.pb.dart';
import '../provider.dart';
import 'version.dart';

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
    await writeBytesAtomic(
      scope: scope,
      bytes: response.bodyBytes,
      file: config.cachedReleasesJsonFile,
    );
    return FlutterReleasesModel.create()
      ..mergeFromProto3Json(jsonDecode(response.body));
  });
}

Future<FlutterReleasesModel?> getCachedFlutterReleases({
  required Scope scope,
  bool unlessStale = false,
}) async {
  final config = PuroConfig.of(scope);
  final stat = config.cachedReleasesJsonFile.statSync();
  if (stat.type == FileSystemEntityType.notFound ||
      (unlessStale &&
          clock.now().difference(stat.modified) > const Duration(hours: 1))) {
    return null;
  }
  final content = await readAtomic(
    scope: scope,
    file: config.cachedReleasesJsonFile,
  );
  return FlutterReleasesModel.create()
    ..mergeFromProto3Json(jsonDecode(content));
}

/// Searches [releases] for a specific version and/or channel.
FlutterReleaseModel? searchFlutterVersions({
  required FlutterReleasesModel releases,
  Version? version,
  FlutterChannel? channel,
}) {
  if (version == null) {
    final hash = releases.currentRelease[channel?.name ?? 'stable'];
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
      final releaseChannel = FlutterChannel.parse(release.channel)!;
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
  final log = PuroLogger.of(scope);

  // Default to the stable channel
  if (channel == null && version == null) {
    channel = FlutterChannel.stable;
  }

  final cachedReleasesStat = config.cachedReleasesJsonFile.statSync();
  final hasCache = cachedReleasesStat.type == FileSystemEntityType.file;
  var cacheIsFresh = hasCache &&
      clock.now().difference(cachedReleasesStat.modified).inHours < 1;
  final isChannelOnly = channel != null && version == null;

  // Don't fetch from the cache if it's stale and we are looking for the latest
  // release.
  if (hasCache && (!isChannelOnly || cacheIsFresh)) {
    FlutterReleasesModel? cachedReleases;
    await lockFile(
      scope,
      config.cachedReleasesJsonFile,
      (handle) async {
        final contents = await handle.readAllAsString();
        try {
          cachedReleases = FlutterReleasesModel.create()
            ..mergeFromProto3Json(jsonDecode(contents));
        } catch (exception, stackTrace) {
          log.w('Error while parsing cached releases');
          log.w('$exception\n$stackTrace');
          cacheIsFresh = false;
        }
      },
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

  // Fetch new releases as long as the cache isn't already fresh.
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
    throw CommandError(
      'Could not find latest version of the ${channel.name} channel',
    );
  } else if (channel == null) {
    throw CommandError(
      'Could not find version $version',
    );
  } else {
    throw CommandError(
      'Could not find version $version in the $channel channel',
    );
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
  return FlutterChannel.parse(branch);
}

const pseudoEnvironmentNames = {'stable', 'beta', 'main'};
