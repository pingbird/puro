import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'command.dart';
import 'command_result.dart';
import 'config.dart';
import 'file_lock.dart';
import 'git.dart';
import 'http.dart';
import 'logger.dart';
import 'provider.dart';
import 'terminal.dart';

const _puroVersionDefine = String.fromEnvironment('puro_version');

enum PuroInstallationType {
  distribution('Puro is installed normally'),
  standalone('Puro is a standalone executable'),
  development('Puro is a development version'),
  pub('Puro was installed with pub'),
  unknown('Could not determine installation method');

  const PuroInstallationType(this.description);

  final String description;
}

class PuroVersion {
  PuroVersion({
    required this.semver,
    required this.type,
    required this.target,
    required this.packageRoot,
    required this.puroExecutable,
  });

  final Version semver;
  final PuroInstallationType type;
  final PuroBuildTarget target;
  final Directory? packageRoot;
  final File? puroExecutable;

  bool get isUnknown => semver == unknownSemver;

  static const _fs = LocalFileSystem();

  static Directory? _getRootFromPackageConfig({
    required Scope scope,
  }) {
    final log = PuroLogger.of(scope);
    final packageConfig = Platform.packageConfig;
    if (packageConfig == null) {
      log.d('No package root: Platform.packageConfig is null');
      return null;
    }
    final packageFile = _fs.file(Uri.parse(packageConfig).toFilePath());
    if (!packageFile.existsSync()) {
      log.d('No package root: Platform.packageConfig is invalid');
      return null;
    }
    try {
      final packageData =
          jsonDecode(packageFile.readAsStringSync()) as Map<String, dynamic>;
      final packages = packageData['packages'] as List<dynamic>;
      final puroPackage = packages
          .cast<Map<String, dynamic>>()
          .firstWhere((e) => e['name'] == 'puro');
      final rootUri = Uri.parse(puroPackage['rootUri'] as String);
      var rootPath = rootUri.toFilePath();
      if (path.isRelative(rootPath)) {
        path.isRelative(rootPath);
        rootPath = path.normalize(
          path.join(path.dirname(packageFile.path), rootPath),
        );
      }
      return _fs.directory(rootPath);
    } catch (exception, stackTrace) {
      log.w('Error while parsing package config$exception\n$stackTrace');
      return null;
    }
  }

  static final provider = Provider((scope) async {
    final log = PuroLogger.of(scope);
    final config = PuroConfig.of(scope);
    final target = PuroBuildTarget.query();

    log.d('target: $target');
    log.d('Platform.executable: ${Platform.executable}');
    log.d('Platform.resolvedExecutable: ${Platform.resolvedExecutable}');
    log.d('Platform.script: ${Platform.script}');
    log.d('Platform.packageConfig: ${Platform.packageConfig}');

    final executablePath = path.canonicalize(Platform.resolvedExecutable);
    var scriptPath = Platform.script.toFilePath();
    if (path.equals(
          scriptPath,
          path.join(path.current, target.executableName),
        ) ||
        path.equals(
          scriptPath,
          path.join(path.current, 'puro'),
        )) {
      // A bug in dart gives an incorrect Platform.script :/
      // https://github.com/dart-lang/sdk/issues/45005
      scriptPath = executablePath;
    } else {
      try {
        scriptPath =
            config.fileSystem.file(scriptPath).resolveSymbolicLinksSync();
      } catch (exception, stackTrace) {
        log.w('Error while resolving Platform.script\n$exception\n$stackTrace');
      }
    }
    scriptPath = path.canonicalize(scriptPath);
    final scriptFile = config.fileSystem.file(scriptPath);
    final scriptExtension = path.extension(scriptPath);
    final scriptIsExecutable = path.equals(scriptPath, executablePath);
    var packageRoot = _getRootFromPackageConfig(scope: scope);

    if (!scriptIsExecutable && packageRoot == null) {
      final pubInstallBinDir = scriptFile.parent;
      final pubInstallPackageDir = pubInstallBinDir.parent;
      final pubInstallPubspecLockFile =
          pubInstallPackageDir.childFile('pubspec.lock');
      final pubInstallPubspecYamlFile =
          pubInstallPackageDir.childFile('pubspec.yaml');
      log.d('pubInstallBinDir: ${pubInstallBinDir.path}');
      log.d('pubInstallPackageDir: ${pubInstallPackageDir.path}');
      if (pubInstallBinDir.basename == 'bin' &&
          pubInstallPackageDir.basename == 'puro' &&
          pubInstallPackageDir.parent.basename == 'global_packages' &&
          pubInstallPubspecLockFile.existsSync() &&
          !pubInstallPubspecYamlFile.existsSync()) {
        packageRoot = pubInstallPackageDir;
      } else {
        final segments = path.split(scriptPath);
        final dartToolIndex = segments.indexOf('.dart_tool');
        if (dartToolIndex != -1) {
          packageRoot =
              _fs.directory(path.joinAll(segments.take(dartToolIndex)));
        }
      }
    }

    log.d('packageRoot: ${packageRoot?.path}');
    log.d('executablePath: $executablePath');
    log.d('scriptPath: $scriptPath');
    log.d('scriptExtension: $scriptExtension');

    var installationType = PuroInstallationType.unknown;
    File? puroExecutable;
    if (scriptFile.basename == 'puro.dart' &&
        scriptFile.parent.basename == 'bin' &&
        scriptFile.parent.parent.parent.childDirectory('.git').existsSync()) {
      installationType = PuroInstallationType.development;
      packageRoot = scriptFile.parent.parent;
    } else if (scriptExtension == '.snapshot' && packageRoot != null) {
      final projectRootDir = packageRoot.parent;
      log.d('projectRootDir: ${projectRootDir.path}');
      if (projectRootDir.basename == 'global_packages') {
        installationType = PuroInstallationType.pub;
      } else if (projectRootDir.childDirectory('.git').existsSync()) {
        installationType = PuroInstallationType.development;
      }
    } else if (scriptIsExecutable) {
      puroExecutable = config.fileSystem.file(executablePath);
      if (path.equals(
        executablePath,
        config.puroExecutableFile.path,
      )) {
        installationType = PuroInstallationType.distribution;
      } else {
        installationType = PuroInstallationType.standalone;
      }
    }

    log.d('installationType: $installationType');

    /// Attempts to find the version of puro using either the `puro_version`
    /// define or the git tag. This is a tiny bit slower in development because
    /// it has to call git a few times.
    var version = unknownSemver;
    if (_puroVersionDefine.isNotEmpty) {
      version = Version.parse(_puroVersionDefine);
    } else if (packageRoot != null) {
      if (installationType == PuroInstallationType.development) {
        final gitTagVersion = await GitTagVersion.query(
          scope: scope,
          repository: packageRoot.parent,
        );
        log.d('gitTagVersion: $gitTagVersion');
        version = gitTagVersion.toSemver();
      } else if (installationType == PuroInstallationType.pub) {
        final pubspecLockFile = packageRoot.childFile('pubspec.lock');
        try {
          final pubspecLock =
              loadYaml(pubspecLockFile.readAsStringSync()) as YamlMap;
          version = Version.parse(
            pubspecLock['packages']['puro']['version'] as String,
          );
        } catch (exception, stackTrace) {
          log.w(
              'Error while parsing ${pubspecLockFile.path}\n$exception\n$stackTrace');
        }
      }
    }

    log.d('version: $version');

    return PuroVersion(
      semver: version,
      type: installationType,
      target: target,
      packageRoot: packageRoot,
      puroExecutable: puroExecutable,
    );
  });

  static Future<PuroVersion> of(Scope scope) => scope.read(provider);
}

enum PuroBuildTarget {
  windowsX64('windows-x64', '.exe', '.bat'),
  linuxX64('linux-x64', '', ''),
  macosX64('darwin-x64', '', '');

  const PuroBuildTarget(
    this.name,
    this.exeSuffix,
    this.scriptSuffix,
  );

  final String name;
  final String exeSuffix;
  final String scriptSuffix;

  String get executableName => 'puro$exeSuffix';
  String get trampolineName => 'puro$scriptSuffix';
  String get flutterName => 'flutter$scriptSuffix';
  String get dartName => 'dart$scriptSuffix';

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
  final log = PuroLogger.of(scope);
  final config = PuroConfig.of(scope);
  final prefs = await readGlobalPrefs(scope: scope);
  if (prefs.hasEnableUpdateCheck() && !prefs.enableUpdateCheck) {
    log.d('Update check disabled');
    return null;
  }
  final puroVersion = await PuroVersion.of(scope);
  if (puroVersion.type != PuroInstallationType.distribution) {
    log.v('Not a distribution, skipping update check');
    return null;
  }
  log.v('Checking if update is available');
  final lastVersionCheck =
      prefs.hasLastUpdateCheck() ? DateTime.parse(prefs.lastUpdateCheck) : null;
  final lastNotification = prefs.hasLastUpdateNotification()
      ? DateTime.parse(prefs.lastUpdateNotification)
      : null;
  final latestVersionFile = config.puroLatestVersionFile;
  final latestVersion = latestVersionFile.existsSync()
      ? tryParseVersion(await readAtomic(scope: scope, file: latestVersionFile))
      : null;
  final isOutOfDate =
      latestVersion != null && latestVersion > puroVersion.semver;
  final now = clock.now();
  final willNotify = isOutOfDate &&
      (alwaysNotify ||
          lastNotification == null ||
          now.difference(lastNotification) > _kUpdateNotificationThreshold);
  final shouldVersionCheck = !isOutOfDate &&
      (lastVersionCheck == null ||
          now.difference(lastVersionCheck) > _kUpdateVersionCheckThreshold);
  log.d('lastNotification: $lastNotification');
  log.d('latestVersion: $latestVersion');
  log.d('isOutOfDate: $isOutOfDate');
  log.d('willNotify: $willNotify');
  log.d('shouldVersionCheck: $shouldVersionCheck');
  log.d('lastVersionCheck: $lastVersionCheck');
  if (willNotify) {
    await updateGlobalPrefs(
      scope: scope,
      fn: (prefs) async {
        prefs.lastUpdateNotification = now.toIso8601String();
      },
    );
    return CommandMessage(
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
