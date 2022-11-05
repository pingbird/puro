import 'dart:io';

import 'package:clock/clock.dart';
import 'package:file/file.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'command.dart';
import 'config.dart';
import 'file_lock.dart';
import 'git.dart';
import 'http.dart';
import 'logger.dart';
import 'provider.dart';
import 'terminal.dart';

const _puroVersionDefine = String.fromEnvironment('puro_version');

Future<Directory?> getPuroDevelopmentRepository({
  required Scope scope,
}) async {
  final config = PuroConfig.of(scope);
  final scriptUri = Platform.script;
  final scriptFile = config.fileSystem.file(scriptUri.toFilePath()).absolute;
  final puroPackage = findProjectDir(scriptFile.parent, 'pubspec.yaml');
  if (puroPackage == null) return null;
  final repository = findProjectDir(scriptFile.parent, '.git');
  if (repository?.path != puroPackage.parent.path) return null;
  final pubspecFile = puroPackage.childFile('pubspec.yaml');
  final dynamic pubspecData = loadYaml(await pubspecFile.readAsString());
  if (pubspecData['name'] != 'puro') return null;
  return repository;
}

Future<Version>? _cachedVersion;

/// Attempts to find the version of puro using either the `puro_version` define
/// or the git tag. This is a tiny bit slower in development because it has to
/// call git a few times.
Future<Version> getPuroVersion({
  required Scope scope,
}) async {
  if (_cachedVersion != null) return _cachedVersion!;
  final future = () async {
    if (_puroVersionDefine.isNotEmpty) {
      return Version.parse(_puroVersionDefine);
    }
    final repository = await getPuroDevelopmentRepository(scope: scope);
    if (repository == null) {
      return GitTagVersion.unknown.toSemver();
    }
    final version = await GitTagVersion.query(
      scope: scope,
      repository: repository,
    );
    return version.toSemver();
  }();
  _cachedVersion = future;
  return future;
}

enum PuroBuildTarget {
  windowsX64('windows-x64', 'puro.exe', 'dart.bat', 'flutter.bat'),
  linuxX64('linux-x64', 'puro', 'dart', 'flutter'),
  macosX64('darwin-x64', 'puro', 'dart', 'flutter');

  const PuroBuildTarget(
    this.name,
    this.executableName,
    this.dartName,
    this.flutterName,
  );

  final String name;
  final String executableName;
  final String dartName;
  final String flutterName;

  static PuroBuildTarget query() {
    if (Platform.isWindows) {
      return PuroBuildTarget.windowsX64;
    } else if (Platform.isLinux) {
      return PuroBuildTarget.linuxX64;
    } else if (Platform.isMacOS) {
      return PuroBuildTarget.macosX64;
    } else {
      throw AssertionError(
        'Unrecognized operating system: ${Platform.operatingSystem}',
      );
    }
  }
}

const _kUpdateVersionCheckThreshold = Duration(days: 1);
const _kUpdateNotificationThreshold = Duration(days: 1);

Future<void> _fetchLatestVersionInBackground({
  required Scope scope,
}) async {
  final log = PuroLogger.of(scope);
  final config = PuroConfig.of(scope);
  final httpClient = scope.read(clientProvider);
  log.v('Fetching latest version from ${config.puroLatestVersionUrl}');
  final response = await httpClient.get(config.puroLatestVersionUrl);
  HttpException.ensureSuccess(response);
  final body = response.body.trim();
  Version.parse(body);
  log.v('Latest version:');
  await writeAtomic(
    scope: scope,
    file: config.puroLatestVersionFile,
    content: body,
  );
}

Future<CommandMessage?> checkIfUpdateAvailable({
  required Scope scope,
  required PuroCommandRunner runner,
  bool alwaysNotify = false,
}) async {
  if (runner.isJson) {
    // Don't bother telling a bot to update.
    return null;
  }
  final config = PuroConfig.of(scope);
  final prefs = await readGlobalPrefs(scope: scope);
  if (prefs.hasEnableUpdateCheck() && !prefs.enableUpdateCheck) {
    return null;
  }
  final lastVersionCheck =
      prefs.hasLastUpdateCheck() ? DateTime.parse(prefs.lastUpdateCheck) : null;
  final lastNotification = prefs.hasLastUpdateNotification()
      ? DateTime.parse(prefs.lastUpdateNotification)
      : null;
  final currentVersion = await getPuroVersion(scope: scope);
  final latestVersionFile = config.puroLatestVersionFile;
  final latestVersion = latestVersionFile.existsSync()
      ? tryParseVersion(await readAtomic(scope: scope, file: latestVersionFile))
      : null;
  final isOutOfDate = latestVersion != null && latestVersion > currentVersion;
  final now = clock.now();
  final willNotify = isOutOfDate &&
      (alwaysNotify ||
          lastNotification == null ||
          now.difference(lastNotification) > _kUpdateNotificationThreshold);
  final shouldVersionCheck = !isOutOfDate &&
      (lastVersionCheck == null ||
          now.difference(lastVersionCheck) > _kUpdateVersionCheckThreshold);
  if (willNotify) {
    await updateGlobalPrefs(
      scope: scope,
      fn: (prefs) async {
        prefs.lastUpdateNotification = now.toIso8601String();
      },
    );
    return CommandMessage(
      (format) =>
          'A new version of Puro is available, run `puro upgrade-puro` to upgrade',
      type: CompletionType.info,
    );
  } else if (shouldVersionCheck) {
    await updateGlobalPrefs(
      scope: scope,
      fn: (writePrefs) async {
        // An update might have happened between us calling readGlobalPrefs and
        // updateGlobalPrefs.
        if (writePrefs.lastUpdateCheck != prefs.lastUpdateCheck) {
          return;
        }
        writePrefs.lastUpdateCheck = now.toIso8601String();
        runner.startInBackground(
          name: 'checking latest version',
          task: () => _fetchLatestVersionInBackground(scope: scope),
        );
      },
    );
  }
  return null;
}
