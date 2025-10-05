import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:pub_semver/pub_semver.dart';

import '../config.dart';
import '../downloader.dart';
import '../extensions.dart';
import '../file_lock.dart';
import '../http.dart';
import '../logger.dart';
import '../process.dart';
import '../progress.dart';
import '../provider.dart';
import 'engine.dart';

enum DartChannel { stable, beta, dev }

enum DartOS {
  windows,
  macOS,
  linux;

  static final DartOS current = Platform.isWindows
      ? DartOS.windows
      : Platform.isMacOS
      ? DartOS.macOS
      : Platform.isLinux
      ? DartOS.linux
      : throw UnsupportedError('Unsupported platform');
}

enum DartArch {
  ia32,
  x64,
  arm,
  arm64,
  riscv64;

  static final DartArch current = DartArch.values.singleWhere(
    (e) => '${ffi.Abi.current()}'.endsWith('_${e.name}'),
  );
}

class DartRelease {
  const DartRelease(this.os, this.arch, this.channel, this.version);

  final DartOS os;
  final DartArch arch;
  final DartChannel channel;
  final Version version;

  Uri get downloadUrl => Uri.parse(
    'https://storage.googleapis.com/dart-archive/channels/${channel.name}/release/$version/sdk/dartsdk-${os.name.toLowerCase()}-${arch.name}-release.zip',
  );

  Uri get versionUrl => Uri.parse(
    'https://storage.googleapis.com/storage/v1/b/dart-archive/o/channels%2F${channel.name}%2Frelease%2F$version%2FVERSION?alt=media',
  );

  String get name => '${channel.name}-$version-${os.name}-${arch.name}';
}

class DartReleases {
  DartReleases(this.releases);
  final Map<DartChannel, List<Version>> releases;
  Map<String, dynamic> toJson() => {
    for (final channel in releases.keys)
      channel.name: releases[channel]!.map((v) => '$v').toList(),
  };
  factory DartReleases.fromJson(Map<String, dynamic> json) => DartReleases({
    for (final channel in json.keys)
      DartChannel.values.singleWhere(
        (e) => e.name == channel,
      ): (json[channel] as List)
          .map((v) => Version.parse(v as String))
          .toList(),
  });
}

/// Fetches all of the available Dart releases.
Future<DartReleases> fetchDartReleases({required Scope scope}) async {
  final config = PuroConfig.of(scope);
  return ProgressNode.of(scope).wrap((scope, node) async {
    final releases = <DartChannel, List<Version>>{};
    final client = scope.read(clientProvider);
    for (final channel in DartChannel.values) {
      final url = Uri.parse(
        'https://www.googleapis.com/storage/v1/b/dart-archive/o?prefix=channels/${channel.name}/release/&delimiter=/',
      );
      node.description = 'Fetching $url';
      final result = await client.get(url);
      HttpException.ensureSuccess(result);
      final data = jsonDecode(result.body);
      releases[channel] = [];
      for (final prefix in data['prefixes'] as List) {
        final version = tryParseVersion(
          (prefix as String).split('/').lastWhere((e) => e.isNotEmpty),
        );
        if (version == null) continue;
        releases[channel]!.add(version);
      }
    }
    final result = DartReleases(releases);
    await writeBytesAtomic(
      scope: scope,
      bytes: utf8.encode(prettyJsonEncoder.convert(result)),
      file: config.cachedDartReleasesJsonFile,
    );
    return result;
  });
}

Future<DartReleases?> getCachedDartReleases({
  required Scope scope,
  bool unlessStale = false,
}) async {
  final config = PuroConfig.of(scope);
  final stat = config.cachedDartReleasesJsonFile.statSync();
  if (stat.type == FileSystemEntityType.notFound ||
      (unlessStale &&
          clock.now().difference(stat.modified) > const Duration(hours: 1))) {
    return null;
  }
  final content = await readAtomic(
    scope: scope,
    file: config.cachedDartReleasesJsonFile,
  );
  return DartReleases.fromJson(jsonDecode(content) as Map<String, dynamic>);
}

/// Gets all of the available Dart releases, checking the cache first.
Future<DartReleases> getDartReleases({required Scope scope}) async {
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);

  final cachedReleasesStat = config.cachedDartReleasesJsonFile.statSync();
  final hasCache = cachedReleasesStat.type == FileSystemEntityType.file;
  var cacheIsFresh =
      hasCache &&
      clock.now().difference(cachedReleasesStat.modified).inHours < 1;

  // Don't read from the cache if it's stale.
  if (hasCache && cacheIsFresh) {
    DartReleases? cachedReleases;
    await lockFile(scope, config.cachedDartReleasesJsonFile, (handle) async {
      final contents = await handle.readAllAsString();
      try {
        cachedReleases = DartReleases.fromJson(
          jsonDecode(contents) as Map<String, dynamic>,
        );
      } catch (exception, stackTrace) {
        log.w('Error while parsing cached releases');
        log.w('$exception\n$stackTrace');
        cacheIsFresh = false;
      }
    });
    if (cachedReleases != null) {
      return cachedReleases!;
    }
  }

  return await fetchDartReleases(scope: scope);
}

Future<void> downloadSharedDartRelease({
  required Scope scope,
  required DartRelease release,
  bool check = true,
}) async {
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);
  final dartSdk = config.getDartRelease(release);
  final client = scope.read(clientProvider);

  // Delete the current cache if it's corrupt
  if (dartSdk.sdkDir.existsSync() && check) {
    try {
      await ProgressNode.of(scope).wrap((scope, node) async {
        node.description = 'Checking if dart works';
        await runProcess(
          scope,
          dartSdk.dartExecutable.path,
          ['--version'],
          throwOnFailure: true,
          environment: {'PUB_CACHE': config.legacyPubCacheDir.path},
        );
      });
    } catch (exception) {
      log.w('dart version check failed, deleting cache');
      dartSdk.sdkDir.deleteSync(recursive: true);
    }
  }

  if (!dartSdk.sdkDir.existsSync()) {
    log.v('Downloading dart');

    if (!config.sharedDartReleaseDir.existsSync()) {
      config.sharedDartReleaseDir.createSync(recursive: true);
    }
    final zipFile = config.sharedDartReleaseDir.childFile(
      '${release.name}.zip',
    );

    await downloadFile(
      scope: scope,
      url: release.downloadUrl,
      file: zipFile,
      description: 'Downloading dart',
    );

    log.v('Unzipping into ${dartSdk.sdkDir.parent}');
    await ProgressNode.of(scope).wrap((scope, node) async {
      node.description = 'Unzipping dart';
      if (!dartSdk.sdkDir.parent.existsSync()) {
        dartSdk.sdkDir.parent.createSync(recursive: true);
      }
      await unzip(
        scope: scope,
        zipFile: zipFile,
        destination: dartSdk.sdkDir.parent,
      );
    });

    zipFile.deleteSync();
  }

  if (!dartSdk.versionJsonFile.existsSync()) {
    await ProgressNode.of(scope).wrap((scope, node) async {
      node.description = 'Getting dart version info';
      final response = await client.get(release.versionUrl);
      HttpException.ensureSuccess(response);
      dartSdk.versionJsonFile.writeAsStringSync(response.body);
    });
  }
}
