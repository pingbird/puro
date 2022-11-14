import 'dart:io';

import '../command_result.dart';
import '../config.dart';
import '../downloader.dart';
import '../http.dart';
import '../logger.dart';
import '../process.dart';
import '../progress.dart';
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
  } else if (Platform.isLinux || Platform.isMacOS) {
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
    final engineZipUrl = await getEngineReleaseZipUrl(
      scope: scope,
      engineVersion: engineVersion,
    );
    sharedCache.cacheDir.createSync(recursive: true);
    final zipFile = config.sharedCachesDir.childFile('$engineVersion.zip');
    await downloadFile(
      scope: scope,
      url: engineZipUrl,
      file: zipFile,
      description: 'Downloading engine',
    );

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

  return didDownloadEngine;
}
