import 'dart:io';
import 'dart:math';

import 'package:http/http.dart';

import '../config.dart';
import '../git.dart';
import '../http.dart';
import '../logger.dart';
import '../process.dart';
import '../provider.dart';

enum EngineOS {
  windows,
  macOS,
  linux,
}

enum EngineArch {
  x64,
  arm64,
}

enum EngineBuildTarget {
  windowsX64(zipName: 'dart-sdk-windows-x64.zip'),
  linuxX64(zipName: 'dart-sdk-linux-x64.zip'),
  linuxArm64(zipName: 'dart-sdk-linux-arm64.zip'),
  macosX64(zipName: 'dart-sdk-darwin-x64.zip'),
  macosArm64(zipName: 'dart-sdk-darwin-arm64.zip');

  const EngineBuildTarget({required this.zipName});

  final String zipName;

  static EngineBuildTarget from(EngineOS os, EngineArch arch) {
    switch (os) {
      case EngineOS.windows:
        switch (arch) {
          case EngineArch.x64:
            return EngineBuildTarget.windowsX64;
          case EngineArch.arm64:
            break;
        }
        break;
      case EngineOS.macOS:
        switch (arch) {
          case EngineArch.x64:
            return EngineBuildTarget.macosX64;
          case EngineArch.arm64:
            return EngineBuildTarget.macosArm64;
        }
      case EngineOS.linux:
        switch (arch) {
          case EngineArch.x64:
            return EngineBuildTarget.linuxX64;
          case EngineArch.arm64:
            return EngineBuildTarget.linuxArm64;
        }
    }
    throw AssertionError('Unsupported build target: $os $arch');
  }
}

Future<Uri> getEngineReleaseZipUrl({
  required Scope scope,
  required String engineVersion,
}) async {
  final config = PuroConfig.of(scope);
  final baseUrl = config.flutterStorageBaseUrl;
  final EngineOS os;
  final EngineArch arch;
  if (Platform.isWindows) {
    os = EngineOS.windows;
    arch = EngineArch.x64;
  } else if (Platform.isMacOS) {
    os = EngineOS.macOS;
    final sysctlResult = await runProcess(
      scope,
      'sysctl',
      ['-n', 'hw.optional.arm64'],
      runInShell: true,
    );
    if (sysctlResult.exitCode != 0 || sysctlResult.stdout == '0') {
      arch = EngineArch.x64;
    } else if (sysctlResult.stdout == '1') {
      arch = EngineArch.arm64;
    } else {
      throw AssertionError(
        'Unexpected result from sysctl: `${sysctlResult.stdout}`',
      );
    }
  } else if (Platform.isLinux) {
    os = EngineOS.linux;
    final unameResult = await runProcess(
      scope,
      'uname',
      ['-m'],
      runInShell: true,
      throwOnFailure: true,
    );
    final unameStdout = unameResult.stdout as String;
    if (unameStdout.contains('arm64')) {
      arch = EngineArch.arm64;
    } else if (unameStdout.contains('x64')) {
      arch = EngineArch.x64;
    } else {
      throw AssertionError('Unrecognized architecture: `$unameStdout`');
    }
  } else {
    throw AssertionError(
      'Unrecognized operating system: ${Platform.operatingSystem}',
    );
  }

  final target = EngineBuildTarget.from(os, arch);

  return baseUrl.append(
    path: 'flutter_infra_release/flutter/$engineVersion/${target.zipName}',
  );
}

Future<void> unzip({
  required Scope scope,
  required File zipFile,
  required Directory destination,
}) async {
  destination.createSync(recursive: true);
  if (Platform.isWindows) {
    await runProcess(
      scope,
      'powershell',
      [
        'Expand-Archive',
        zipFile.path,
        '-DestinationPath',
        destination.path,
      ],
      runInShell: true,
      throwOnFailure: true,
    );
  } else {
    throw AssertionError(
      'Unrecognized operating system: ${Platform.operatingSystem}',
    );
  }
}

Future<void> setUpFlutterTool({
  required Scope scope,
  required EnvConfig environment,
}) async {
  final config = PuroConfig.of(scope);
  final git = GitClient.of(scope);
  final log = PuroLogger.of(scope);
  final flutterConfig = environment.flutter;
  final flutterCache = flutterConfig.cache;
  final httpClient = scope.read(clientProvider);
  final engineVersion = flutterConfig.engineVersion!;
  final sharedCachesDir = config.sharedCachesDir;
  final sharedCacheDir = sharedCachesDir.childDirectory(engineVersion);

  final shouldUpdateEngine = flutterCache.engineVersion != engineVersion;
  var didChangeEngine = false;

  if (shouldUpdateEngine) {
    log.v('Engine out of date, updating');

    final sharedCache = FlutterCacheConfig(sharedCacheDir);

    // Delete the current cache if it's corrupt
    if (sharedCache.exists) {
      try {
        await runProcess(
          scope,
          sharedCache.dartSdk.dartExecutable.path,
          ['--version'],
          throwOnFailure: true,
        );
      } catch (e) {
        log.w('Dart version check failed, deleting cache');
        sharedCacheDir.deleteSync(recursive: true);
      }
    }

    if (!sharedCache.exists) {
      log.v('Downloading engine');

      final engineZipUrl = await getEngineReleaseZipUrl(
        scope: scope,
        engineVersion: engineVersion,
      );
      sharedCachesDir.createSync(recursive: true);
      final zipFile = sharedCachesDir.childFile('$engineVersion.zip');
      final zipFileSink = zipFile.openWrite();

      log.v('Saving $engineZipUrl to ${zipFile.path}');

      final response = await httpClient.send(Request('GET', engineZipUrl));
      if (response.statusCode ~/ 100 != 2) {
        throw AssertionError(
          'HTTP ${response.statusCode} on GET $engineZipUrl',
        );
      }
      await response.stream.pipe(zipFileSink);

      log.v('Unzipping into $sharedCacheDir');

      await unzip(
        scope: scope,
        zipFile: zipFile,
        destination: sharedCacheDir,
      );

      zipFile.deleteSync();
      didChangeEngine = true;
    }

    sharedCache.engineVersionFile.writeAsStringSync(engineVersion);

    final cacheExists = flutterCache.exists;
    final cachePath = flutterConfig.cacheDir.path;
    final link = config.fileSystem.link(cachePath);
    final resolvedPath = cacheExists
        ? flutterConfig.cacheDir.resolveSymbolicLinksSync()
        : cachePath;
    final isLink = cachePath != resolvedPath;
    final linkNeedsUpdate = isLink && resolvedPath != sharedCache.cacheDir.path;
    if (!cacheExists || linkNeedsUpdate) {
      link.createSync(sharedCache.cacheDir.path);
    } else if (!isLink) {
      throw AssertionError(
        'Cache ${flutterConfig.cacheDir.path} already exists, was it created without puro?',
      );
    }
  }

  final flutterCommit =
      await git.getCurrentCommitHash(repository: flutterConfig.sdkDir);

  var flutterToolsStamp = '$flutterCommit:${environment.flutterToolArgs}';

  if (Platform.isWindows) {
    // Funny quirk in bin/internal/shared.bat
    flutterToolsStamp = '"$flutterToolsStamp"';
  }

  final shouldRecompileTool =
      didChangeEngine || flutterCache.flutterToolsStamp != flutterToolsStamp;

  if (shouldRecompileTool) {
    log.v('Flutter tool out of date, updating...');

    final pubEnvironment =
        '${Platform.environment['PUB_ENVIRONMENT'] ?? ''}:flutter_install:puro';

    var backoff = const Duration(seconds: 1);
    final rand = Random();
    for (var i = 0;; i++) {
      final pubProcess = await runProcess(
        scope,
        flutterCache.dartSdk.dartExecutable.path,
        [
          '__deprecated_pub',
          'upgrade',
          '--verbosity=normal',
          '--no-precompile',
        ],
        environment: {
          'PUB_ENVIRONMENT': pubEnvironment,
        },
        workingDirectory: flutterConfig.flutterToolsDir.path,
      );
      if (pubProcess.exitCode == 0) break;
      if (i == 10) {
        throw AssertionError('pub upgrade failed after 10 attempts');
      } else {
        // Exponential backoff with randomized
        final randomizedBackoff = backoff +
            Duration(
              milliseconds:
                  (backoff.inMilliseconds * rand.nextDouble() * 0.5).round(),
            );
        backoff += backoff;
        log.w(
          'pub upgrade failed, trying again in ${randomizedBackoff.inMilliseconds}ms...',
        );
        await Future<void>.delayed(randomizedBackoff);
      }
    }

    await runProcess(
      scope,
      flutterCache.dartSdk.dartExecutable.path,
      [
        '--disable-dart-dev',
        '--verbosity=error',
        '--disable-dart-dev',
        '--packages=${flutterConfig.flutterToolsPackageConfigJsonFile.path}',
        if (environment.flutterToolArgs.isNotEmpty)
          ...environment.flutterToolArgs.split(RegExp(r'\S+')),
        '--snapshot=${flutterCache.flutterToolsSnapshotFile.path}',
        '--no-enable-mirrors',
        flutterConfig.flutterToolsScriptFile.path,
      ],
      throwOnFailure: true,
    );

    flutterCache.flutterToolsStampFile.writeAsStringSync(flutterToolsStamp);
  }
}
