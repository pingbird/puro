import 'dart:io';
import 'dart:math';

import '../../models.dart';
import '../config.dart';
import '../extensions.dart';
import '../file_lock.dart';
import '../git.dart';
import '../logger.dart';
import '../process.dart';
import '../progress.dart';
import '../provider.dart';
import 'engine.dart';

class FlutterToolInfo {
  FlutterToolInfo({
    required this.environment,
    required this.commit,
    required this.snapshotFile,
    required this.didUpdateEngine,
    required this.didUpdateTool,
  });

  final EnvConfig environment;
  final String commit;
  final File? snapshotFile;
  final bool didUpdateEngine;
  final bool didUpdateTool;
}

Future<FlutterToolInfo> setUpFlutterTool({
  required Scope scope,
  required EnvConfig environment,
  PuroEnvPrefsModel? environmentPrefs,
}) async {
  final config = PuroConfig.of(scope);
  final git = GitClient.of(scope);
  final log = PuroLogger.of(scope);
  final flutterConfig = environment.flutter;
  final flutterCache = flutterConfig.cache;
  final desiredEngineVersion = flutterConfig.engineVersion;

  if (desiredEngineVersion == null) {
    throw AssertionError(
      'Flutter installation corrupt: Could not find engine version at ${flutterConfig.engineVersionFile.path}',
    );
  }

  log.d('flutterCache.engineVersion: ${flutterCache.engineVersion}');
  log.d('flutterConfig.engineVersion: $desiredEngineVersion');

  var didUpdateEngine = false;
  await checkAtomic(
    scope: scope,
    file: environment.updateLockFile,
    condition: () async => flutterCache.engineVersion == desiredEngineVersion,
    onFail: () async {
      log.v('Engine out of date');
      didUpdateEngine = await downloadSharedEngine(
        scope: scope,
        engineVersion: desiredEngineVersion,
      );
      final sharedCache = config.getFlutterCache(desiredEngineVersion);
      sharedCache.engineVersionFile.writeAsStringSync(desiredEngineVersion);
      final cacheExists = flutterCache.exists;
      final cachePath = flutterConfig.cacheDir.path;
      final link = config.fileSystem.link(cachePath);
      final resolvedPath = cacheExists
          ? flutterConfig.cacheDir.resolveSymbolicLinksSync()
          : cachePath;
      final isLink = cachePath != resolvedPath;
      final linkNeedsUpdate =
          isLink && resolvedPath != sharedCache.cacheDir.path;
      log.d('cacheExists: $cacheExists');
      log.d('cachePath: $cachePath');
      log.d('resolvedPath: $resolvedPath');
      log.d('isLink: $isLink');
      log.d('linkNeedsUpdate: $linkNeedsUpdate');
      if (!cacheExists || linkNeedsUpdate) {
        if (link.existsSync()) link.deleteSync();
        link.createSync(sharedCache.cacheDir.path);
        didUpdateEngine = true;
      } else if (!isLink) {
        throw AssertionError(
          'Cache ${flutterConfig.cacheDir.path} already exists, was it created without puro?',
        );
      }
    },
  );

  final commit =
      await git.getCurrentCommitHash(repository: flutterConfig.sdkDir);
  log.d('flutterCommit: $commit');

  final pubspecLockFile = environment.flutter.flutterToolsPubspecLockFile;
  final pubspecYamlFile = environment.flutter.flutterToolsPubspecYamlFile;

  var didUpdateTool = false;

  environmentPrefs ??= await environment.readPrefs(scope: scope);
  final shouldPrecompile =
      !environmentPrefs.hasPrecompileTool() || environmentPrefs.precompileTool;

  Future<void> updateTool() async {
    await ProgressNode.of(scope).wrap((scope, node) async {
      final pubEnvironment =
          '${Platform.environment['PUB_ENVIRONMENT'] ?? ''}:flutter_install:puro';
      var backoff = const Duration(seconds: 1);
      final rand = Random();
      for (var i = 0;; i++) {
        node.description = 'Updating flutter tool';
        final oldPubExecutable = flutterCache.dartSdk.oldPubExecutable;
        final usePubExecutable = oldPubExecutable.existsSync();

        final pubProcess = await runProcess(
          scope,
          usePubExecutable
              ? oldPubExecutable.path
              : flutterCache.dartSdk.dartExecutable.path,
          [
            if (!usePubExecutable) '__deprecated_pub',
            'upgrade',
            '--verbosity=normal',
            '--no-precompile',
          ],
          environment: {
            'PUB_ENVIRONMENT': pubEnvironment,
            'PUB_CACHE': config.pubCacheDir.path,
          },
          workingDirectory: flutterConfig.flutterToolsDir.path,
        );
        if (pubProcess.exitCode == 0) break;
        if (i == 10) {
          throw AssertionError('pub upgrade failed after 10 attempts');
        } else {
          // Exponential backoff with randomization
          final randomizedBackoff = backoff +
              Duration(
                milliseconds:
                    (backoff.inMilliseconds * rand.nextDouble() * 0.5).round(),
              );
          backoff += backoff;
          log.w(
            'Pub upgrade failed, trying again in ${randomizedBackoff.inMilliseconds}ms...',
          );
          node.description =
              'Pub upgrade failed, waiting a little before trying again';
          await Future<void>.delayed(randomizedBackoff);
        }
      }
    });
  }

  final snapshotFile = config.sharedFlutterToolsDir
      .childDirectory(commit)
      .childFile('flutter_tools.snapshot');

  if (shouldPrecompile) {
    final tempSnapshotFile = config.sharedFlutterToolsDir
        .childDirectory(commit)
        .childFile('flutter_tools.snapshot.tmp');

    await checkAtomic(
      scope: scope,
      file: environment.updateLockFile,
      // Recompile flutter tool if any:
      // * Tool snapshot does not exist
      // * Tool pubspec lock does not exist
      // * Pubspec is out of date
      condition: () async => snapshotFile.existsSync(),
      onFail: () async {
        log.v('Flutter tool out of date');

        await updateTool();

        snapshotFile.parent.createSync(recursive: true);

        await ProgressNode.of(scope).wrap((scope, node) async {
          node.description = 'Compiling flutter tool';
          await runProcess(
            scope,
            flutterCache.dartSdk.dartExecutable.path,
            [
              '--disable-dart-dev',
              '--verbosity=error',
              '--packages=${flutterConfig.flutterToolsPackageConfigJsonFile.path}',
              if (environment.flutterToolArgs.isNotEmpty)
                ...environment.flutterToolArgs.split(RegExp(r'\S+')),
              '--snapshot=${tempSnapshotFile.path}',
              '--no-enable-mirrors',
              flutterConfig.flutterToolsScriptFile.path,
            ],
            environment: {
              'PUB_CACHE': config.pubCacheDir.path,
            },
            throwOnFailure: true,
          );
        });

        snapshotFile.deleteOrRenameSync();
        tempSnapshotFile.copySync(snapshotFile.path);

        didUpdateTool = true;
      },
    );
  } else {
    await checkAtomic(
      scope: scope,
      file: environment.updateLockFile,
      condition: () async =>
          pubspecLockFile.existsSync() &&
          pubspecLockFile
              .lastModifiedSync()
              .isAfter(pubspecYamlFile.lastModifiedSync()),
      onFail: () async {
        log.v('Flutter tool out of date');
        await updateTool();
      },
    );
  }

  // Explicitly set the last accessed time so `puro gc` can figure out which
  // engines are less frequently used.
  flutterCache.engineVersionFile.setLastAccessedSync(DateTime.now());

  return FlutterToolInfo(
    environment: environment,
    commit: commit,
    snapshotFile: shouldPrecompile ? snapshotFile : null,
    didUpdateEngine: didUpdateEngine,
    didUpdateTool: didUpdateTool,
  );
}
