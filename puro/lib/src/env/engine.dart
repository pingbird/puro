import 'dart:io';

import 'package:file/file.dart';
import 'package:process/process.dart';
import 'package:pub_semver/pub_semver.dart';

import '../command_result.dart';
import '../config.dart';
import '../downloader.dart';
import '../extensions.dart';
import '../file_lock.dart';
import '../http.dart';
import '../install/profile.dart';
import '../logger.dart';
import '../process.dart';
import '../progress.dart';
import '../provider.dart';
import '../terminal.dart';
import 'gc.dart';

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
  windowsX64('dart-sdk-windows-x64.zip', EngineOS.windows, EngineArch.x64),
  linuxX64('dart-sdk-linux-x64.zip', EngineOS.linux, EngineArch.x64),
  linuxArm64('dart-sdk-linux-arm64.zip', EngineOS.linux, EngineArch.arm64),
  macosX64('dart-sdk-darwin-x64.zip', EngineOS.macOS, EngineArch.x64),
  macosArm64('dart-sdk-darwin-arm64.zip', EngineOS.macOS, EngineArch.arm64);

  const EngineBuildTarget(
    this.zipName,
    this.os,
    this.arch,
  );

  final String zipName;
  final EngineOS os;
  final EngineArch arch;

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

  static Future<EngineBuildTarget> query({
    required Scope scope,
  }) async {
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
      final stdout = (sysctlResult.stdout as String).trim();
      if (sysctlResult.exitCode != 0 || stdout == '0') {
        arch = EngineArch.x64;
      } else if (stdout == '1') {
        arch = EngineArch.arm64;
      } else {
        throw AssertionError(
          'Unexpected result from sysctl: `$stdout`',
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
      if (const ['arm64', 'aarch64', 'armv8'].any(unameStdout.contains)) {
        arch = EngineArch.arm64;
      } else if (const ['x64', 'x86_64'].any(unameStdout.contains)) {
        arch = EngineArch.x64;
      } else {
        throw AssertionError('Unrecognized architecture: `$unameStdout`');
      }
    } else {
      throw UnsupportedOSError();
    }
    return EngineBuildTarget.from(os, arch);
  }

  static final Provider<Future<EngineBuildTarget>> provider =
      Provider((scope) => query(scope: scope));
}

/// Unzips [zipFile] into [destination].
Future<void> unzip({
  required Scope scope,
  required File zipFile,
  required Directory destination,
}) async {
  destination.createSync(recursive: true);
  if (Platform.isWindows) {
    final zip = await findProgramInPath(scope: scope, name: '7z');
    if (zip.isNotEmpty) {
      await runProcess(
        scope,
        zip.first.path,
        [
          'x',
          '-y',
          '-o${destination.path}',
          zipFile.path,
        ],
        runInShell: true,
        throwOnFailure: true,
      );
    } else {
      await runProcess(
        scope,
        'powershell',
        [
          'Import-Module Microsoft.PowerShell.Archive; Expand-Archive',
          zipFile.path,
          '-DestinationPath',
          destination.path,
        ],
        runInShell: true,
        throwOnFailure: true,
      );
    }
  } else if (Platform.isLinux || Platform.isMacOS) {
    const pm = LocalProcessManager();
    if (!pm.canRun('unzip')) {
      throw CommandError.list([
        CommandMessage('unzip not found in your PATH'),
        CommandMessage(
          Platform.isLinux
              ? 'Try running `sudo apt install unzip`'
              : 'Try running `brew install unzip`',
          type: CompletionType.info,
        ),
      ]);
    }
    await runProcess(
      scope,
      'unzip',
      [
        '-o',
        '-q',
        zipFile.path,
        '-d',
        destination.path,
      ],
      runInShell: true,
      throwOnFailure: true,
    );
  } else {
    throw UnsupportedOSError();
  }
}

Future<bool> downloadSharedEngine({
  required Scope scope,
  required String engineVersion,
}) async {
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);
  final sharedCache = config.getFlutterCache(engineVersion);
  var didDownloadEngine = false;

  // Delete the current cache if it's corrupt
  if (sharedCache.exists) {
    try {
      await ProgressNode.of(scope).wrap((scope, node) async {
        node.description = 'Checking if dart works';
        await runProcess(
          scope,
          sharedCache.dartSdk.dartExecutable.path,
          ['--version'],
          throwOnFailure: true,
          environment: {
            'PUB_CACHE': config.pubCacheDir.path,
          },
        );
      });
    } catch (exception) {
      log.w('dart version check failed, deleting cache');
      sharedCache.cacheDir.deleteSync(recursive: true);
    }
  }

  if (!sharedCache.exists) {
    log.v('Downloading engine');

    final target = await scope.read(EngineBuildTarget.provider);
    final engineZipUrl = config.flutterStorageBaseUrl.append(
      path: 'flutter_infra_release/flutter/$engineVersion/${target.zipName}',
    );
    sharedCache.cacheDir.createSync(recursive: true);
    final zipFile = config.sharedCachesDir.childFile('$engineVersion.zip');
    try {
      await downloadFile(
        scope: scope,
        url: engineZipUrl,
        file: zipFile,
        description: 'Downloading engine',
      );
    } on HttpException catch (e) {
      // Flutter versions older than 3.0.0 don't have builds for M1 chips but
      // the intel ones will run fine, in the future we could check the contents
      // of shared.sh or the git tree, but this is much simpler.
      if (e.statusCode == 404 && target == EngineBuildTarget.macosArm64) {
        final engineZipUrl = config.flutterStorageBaseUrl.append(
          path: 'flutter_infra_release/flutter/$engineVersion/'
              '${EngineBuildTarget.macosX64.zipName}',
        );
        await downloadFile(
          scope: scope,
          url: engineZipUrl,
          file: zipFile,
          description: 'Downloading engine',
        );
      } else {
        rethrow;
      }
    }

    log.v('Unzipping into ${config.sharedCachesDir}');
    await ProgressNode.of(scope).wrap((scope, node) async {
      node.description = 'Unzipping engine';
      await unzip(
        scope: scope,
        zipFile: zipFile,
        destination: sharedCache.cacheDir,
      );
    });

    zipFile.deleteSync();

    didDownloadEngine = true;
  }

  if (didDownloadEngine) {
    await collectGarbage(scope: scope);
  }

  return didDownloadEngine;
}

final _dartSdkRegex = RegExp(r'Dart SDK version: (\S+)');

Future<Version> getDartSDKVersion({
  required Scope scope,
  required DartSdkConfig dartSdk,
}) async {
  final result = await runProcess(
    scope,
    dartSdk.dartExecutable.path,
    ['--version'],
    throwOnFailure: true,
  );
  final match = _dartSdkRegex.firstMatch(result.stdout as String);
  if (match == null) {
    throw AssertionError('Failed to parse `${result.stdout}`');
  }
  return Version.parse(match.group(1)!);
}

/// These files shouldn't be shared between flutter installs.
const cacheBlacklist = {
  'flutter_version_check.stamp',
  'flutter.version.json',
};

/// Syncs an environment's flutter cache with the shared cache by creating
/// symlinks to individual files / folders.
Future<void> syncFlutterCache({
  required Scope scope,
  required EnvConfig environment,
}) async {
  final log = PuroLogger.of(scope);
  final config = PuroConfig.of(scope);
  final fs = config.fileSystem;
  final engineVersion = environment.flutter.engineVersion;
  if (engineVersion == null) {
    return;
  }
  final sharedCacheDir = config.sharedCachesDir.childDirectory(engineVersion);
  if (!sharedCacheDir.existsSync()) {
    return;
  }
  final cacheDir = environment.flutter.cacheDir;

  if (fs.isLinkSync(cacheDir.path)) {
    // Old versions of puro used to create a symlink to the whole shared cache.
    log.v('Deleting old symlink to shared cache');
    cacheDir.deleteSync();
  }

  if (!cacheDir.existsSync()) {
    cacheDir.createSync(recursive: true);
  }

  // Loop through the files in the cache dir, deleting or moving any that
  // aren't symlinks to the shared cache.
  final cacheDirFiles = <String>{};
  for (final file in cacheDir.listSync()) {
    cacheDirFiles.add(file.basename);
    if (cacheBlacklist.contains(file.basename)) {
      continue;
    }
    final sharedFile = sharedCacheDir.childFile(file.basename);
    if (fs.isLinkSync(file.path)) {
      // Delete the link if it doesn't point to the file we want.
      final link = fs.link(file.path);
      if (link.targetSync() != sharedFile.path) {
        log.d('Deleting ${file.basename} symlink because it points to '
            '`${link.targetSync()}` instead of `${sharedFile.path}`');
        link.deleteSync();
      }
      continue;
    }
    final sharedPath = sharedCacheDir.childFile(file.basename).path;
    if (fs.existsSync(sharedPath)) {
      // Delete local copy and link to shared copy, perhaps we could
      // merge them instead?
      log.d('Deleting ${file.basename} because it already exists in the '
          'shared cache');
      file.deleteSync(recursive: true);
    } else {
      // Move it to the shared cache.
      log.d('Moving ${file.basename} to the shared cache');
      file.renameSync(sharedPath);
    }
  }

  final paths = <Link, String>{};

  // Loop through the files in the shared cache, creating symlinks to them
  // in the cache dir.
  for (final file in sharedCacheDir.listSync()) {
    final cachePath = cacheDir.childFile(file.basename).path;
    if (cacheBlacklist.contains(file.basename) || fs.existsSync(cachePath)) {
      continue;
    }
    paths[fs.link(cachePath)] = file.path;
    log.d('Creating symlink for ${file.basename}');
  }

  // We create the links all at once to avoid having to elevate multiple times
  // on Windows.
  await createLinks(scope: scope, paths: paths);
}

Future<void> trySyncFlutterCache({
  required Scope scope,
  required EnvConfig environment,
}) async {
  await runOptional(scope, 'Syncing flutter cache', () async {
    await syncFlutterCache(
      scope: scope,
      environment: environment,
    );
  });
}
