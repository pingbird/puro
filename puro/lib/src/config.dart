import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';
import 'package:protobuf/protobuf.dart';
import 'package:pub_semver/pub_semver.dart';

import '../models.dart';
import 'command_result.dart';
import 'env/dart.dart';
import 'extensions.dart';
import 'file_lock.dart';
import 'http.dart';
import 'logger.dart';
import 'provider.dart';
import 'version.dart';

Directory? findProjectDir(Directory directory, String fileName) {
  while (directory.existsSync()) {
    if (directory.fileSystem
            .statSync(directory.childFile(fileName).path)
            .type !=
        FileSystemEntityType.notFound) {
      return directory;
    }
    final parent = directory.parent;
    if (directory.path == parent.path) break;
    directory = parent;
  }
  return null;
}

class PuroConfig {
  PuroConfig({
    required this.fileSystem,
    required this.gitExecutable,
    required this.globalPrefsJsonFile,
    required Directory puroRoot,
    required this.legacyPubCacheDir,
    required this.legacyPubCache,
    required this.homeDir,
    required this.projectDir,
    required this.parentProjectDir,
    required this.flutterGitUrl,
    required this.engineGitUrl,
    required this.dartSdkGitUrl,
    required this.releasesJsonUrl,
    required this.flutterStorageBaseUrl,
    required this.environmentOverride,
    required this.puroBuildsUrl,
    required this.buildTarget,
    required this.enableShims,
    required this.shouldInstall,
    required this.shouldSkipCacheSync,
  }) : puroRoot = puroRoot.absolute;

  static Future<PuroConfig> fromCommandLine({
    required Scope scope,
    required FileSystem fileSystem,
    required String? gitExecutable,
    required Directory puroRoot,
    required Directory homeDir,
    required String? workingDir,
    required String? projectDir,
    required String? pubCache,
    required bool? legacyPubCache,
    required String? flutterGitUrl,
    required String? engineGitUrl,
    required String? dartSdkGitUrl,
    required String? releasesJsonUrl,
    required String? flutterStorageBaseUrl,
    required String? environmentOverride,
    required bool? shouldInstall,
    required bool? shouldSkipCacheSync,
    required bool firstRun,
    // Global shims break IDE auto-detection, we use symlinks now instead
    bool enableShims = false,
  }) async {
    final log = PuroLogger.of(scope);
    final globalPrefs = await readGlobalPrefs(scope: scope);

    final currentDir = workingDir == null
        ? fileSystem.currentDirectory
        : fileSystem.directory(workingDir).absolute;

    if (projectDir != null) projectDir = path.join(currentDir.path, projectDir);

    gitExecutable ??= 'git';
    if (!const LocalProcessManager().canRun(gitExecutable)) {
      final String instructions;
      if (Platform.isWindows) {
        instructions = 'getting it at https://git-scm.com/download/win';
      } else if (Platform.isLinux) {
        instructions = 'running `apt install git`';
      } else if (Platform.isMacOS) {
        instructions = 'running `brew install git`';
      } else {
        throw UnsupportedOSError();
      }
      throw CommandError(
        'Could not find git executable, consider $instructions',
      );
    }

    final absoluteProjectDir = projectDir == null
        ? null
        : fileSystem.directory(projectDir).absolute;

    var resultProjectDir =
        absoluteProjectDir ?? findProjectDir(currentDir, 'pubspec.yaml');

    // Puro looks for a suitable project root in the following order:
    //   1. Directory specified in `--project`
    //   2. Closest parent directory with a `.puro.json`
    //   3. Closest grandparent directory with a `pubspec.yaml`
    //
    // If Puro finds a grandparent and tries to access the parentProjectDir with
    // dotfileForWriting, it throws an error indicating the selection is
    // ambiguous.
    final Directory? parentProjectDir =
        absoluteProjectDir ??
        findProjectDir(currentDir, ProjectConfig.dotfileName) ??
        (resultProjectDir != null
            ? findProjectDir(resultProjectDir.parent, 'pubspec.yaml')
            : null) ??
        resultProjectDir;

    resultProjectDir ??= parentProjectDir;

    log.d('puroRootDir: $puroRoot');
    puroRoot.createSync(recursive: true);
    puroRoot = fileSystem
        .directory(puroRoot.resolveSymbolicLinksSync())
        .absolute;
    log.d('puroRoot (resolved): $puroRoot');

    if (environmentOverride == null) {
      final flutterBin = Platform.environment['PURO_FLUTTER_BIN'];
      log.d('PURO_FLUTTER_BIN: $flutterBin');
      if (flutterBin != null) {
        final flutterBinDir = fileSystem.directory(flutterBin).absolute;
        final flutterSdkDir = flutterBinDir.parent;
        final envDir = flutterSdkDir.parent;
        final envsDir = envDir.parent;
        final otherPuroRoot = envsDir.parent;
        log.d('otherPuroRoot: $otherPuroRoot');
        log.d('puroRoot: $puroRoot');
        if (otherPuroRoot.pathEquals(puroRoot)) {
          environmentOverride = envDir.basename.toLowerCase();
          log.d('environmentOverride: $environmentOverride');
        }
      }
    }

    if (flutterStorageBaseUrl == null) {
      final override = Platform.environment['FLUTTER_STORAGE_BASE_URL'];
      if (override != null && override.isNotEmpty) {
        flutterStorageBaseUrl = override;
      }
    }

    flutterStorageBaseUrl ??=
        (globalPrefs.hasFlutterStorageBaseUrl()
            ? globalPrefs.flutterStorageBaseUrl
            : null) ??
        'https://storage.googleapis.com';

    final pubCacheOverride = Platform.environment['PUB_CACHE'];
    if (pubCacheOverride != null && pubCacheOverride.isNotEmpty) {
      pubCache ??= pubCacheOverride;
    }
    pubCache ??= globalPrefs.hasPubCacheDir() ? globalPrefs.pubCacheDir : null;
    pubCache ??= puroRoot
        .childDirectory('shared')
        .childDirectory('pub_cache')
        .path;

    shouldSkipCacheSync ??=
        Platform.environment['PURO_SKIP_CACHE_SYNC']?.isNotEmpty ?? false;

    return PuroConfig(
      fileSystem: fileSystem,
      gitExecutable: fileSystem.file(gitExecutable),
      globalPrefsJsonFile: scope.read(globalPrefsJsonFileProvider),
      puroRoot: puroRoot,
      legacyPubCacheDir: fileSystem.directory(pubCache).absolute,
      legacyPubCache: legacyPubCache ?? !firstRun,
      homeDir: fileSystem.directory(homeDir),
      projectDir: resultProjectDir,
      parentProjectDir: parentProjectDir,
      flutterGitUrl:
          flutterGitUrl ??
          (globalPrefs.hasFlutterGitUrl() ? globalPrefs.flutterGitUrl : null) ??
          'https://github.com/flutter/flutter.git',
      engineGitUrl:
          engineGitUrl ??
          (globalPrefs.hasEngineGitUrl() ? globalPrefs.engineGitUrl : null) ??
          'https://github.com/flutter/engine.git',
      dartSdkGitUrl:
          dartSdkGitUrl ??
          (globalPrefs.hasDartSdkGitUrl() ? globalPrefs.dartSdkGitUrl : null) ??
          'https://github.com/dart-lang/sdk.git',
      releasesJsonUrl: Uri.parse(
        releasesJsonUrl ??
            (globalPrefs.hasReleasesJsonUrl()
                ? globalPrefs.releasesJsonUrl
                : null) ??
            '$flutterStorageBaseUrl/flutter_infra_release/releases/releases_${Platform.operatingSystem}.json',
      ),
      flutterStorageBaseUrl: Uri.parse(flutterStorageBaseUrl),
      environmentOverride: environmentOverride,
      puroBuildsUrl: Uri.parse(
        (globalPrefs.hasPuroBuildsUrl() ? globalPrefs.puroBuildsUrl : null) ??
            'https://puro.dev/builds',
      ),
      buildTarget: globalPrefs.hasPuroBuildTarget()
          ? PuroBuildTarget.fromString(globalPrefs.puroBuildTarget)
          : PuroBuildTarget.query(),
      enableShims: enableShims,
      shouldInstall:
          shouldInstall ??
          (!globalPrefs.hasShouldInstall() || globalPrefs.shouldInstall),
      shouldSkipCacheSync: shouldSkipCacheSync,
    );
  }

  static Directory getHomeDir({
    required Scope scope,
    required FileSystem fileSystem,
  }) {
    final String homeDir;
    if (Platform.isWindows) {
      homeDir = Platform.environment['UserProfile']!;
    } else {
      homeDir = Platform.environment['HOME']!;
    }
    return fileSystem.directory(homeDir);
  }

  static Directory getPuroRoot({
    required Scope scope,
    required FileSystem fileSystem,
    required Directory homeDir,
  }) {
    final log = PuroLogger.of(scope);
    final envPuroRoot = Platform.environment['PURO_ROOT'];
    log.d('envPuroRoot: $envPuroRoot');

    final Directory? binPuroRoot = () {
      final flutterBin = Platform.environment['PURO_FLUTTER_BIN'];
      if (flutterBin == null) {
        return null;
      }
      final flutterBinDir = fileSystem.directory(flutterBin).absolute;
      final flutterSdkDir = flutterBinDir.parent;
      final envDir = flutterSdkDir.parent;
      final envsDir = envDir.parent;
      return envsDir.parent;
    }();
    log.d('binPuroRoot: $binPuroRoot');

    if (binPuroRoot != null) {
      return binPuroRoot;
    }
    if (envPuroRoot?.isNotEmpty ?? false) {
      return fileSystem.directory(envPuroRoot);
    }
    return homeDir.childDirectory('.puro');
  }

  final FileSystem fileSystem;
  final File gitExecutable;
  final File globalPrefsJsonFile;
  final Directory puroRoot;
  final Directory legacyPubCacheDir;
  final Directory homeDir;
  final Directory? projectDir;
  final Directory? parentProjectDir;
  final String flutterGitUrl;
  final String engineGitUrl;
  final String dartSdkGitUrl;
  final Uri releasesJsonUrl;
  final Uri flutterStorageBaseUrl;
  final String? environmentOverride;
  final Uri puroBuildsUrl;
  final PuroBuildTarget buildTarget;
  final bool enableShims;
  final bool shouldInstall;
  final bool shouldSkipCacheSync;
  final bool legacyPubCache;

  late final Directory envsDir = puroRoot.childDirectory('envs');
  late final Directory binDir = puroRoot.childDirectory('bin');
  late final Directory sharedDir = puroRoot.childDirectory('shared');
  late final Directory sharedFlutterDir = sharedDir.childDirectory('flutter');
  late final Directory sharedEngineDir = sharedDir.childDirectory('engine');
  late final Directory sharedDartSdkDir = sharedDir.childDirectory('dart-sdk');
  late final Directory sharedDartReleaseDir = sharedDir.childDirectory(
    'dart-release',
  );
  late final Directory sharedCachesDir = sharedDir.childDirectory('caches');
  late final Directory sharedGClientDir = sharedDir.childDirectory('gclient');
  late final Directory pubCacheBinDir = legacyPubCacheDir.childDirectory('bin');
  late final Directory sharedFlutterToolsDir = sharedDir.childDirectory(
    'flutter_tools',
  );
  late final File puroExecutableFile = binDir.childFile(
    buildTarget.executableName,
  );
  late final File puroTrampolineFile = binDir.childFile(
    buildTarget.trampolineName,
  );
  late final File puroDartShimFile = binDir.childFile(buildTarget.dartName);
  late final File puroFlutterShimFile = binDir.childFile(
    buildTarget.flutterName,
  );
  late final File puroExecutableTempFile = binDir.childFile(
    '${buildTarget.executableName}.tmp',
  );
  late final File cachedReleasesJsonFile = puroRoot.childFile(
    releasesJsonUrl.pathSegments.last,
  );
  late final File cachedDartReleasesJsonFile = puroRoot.childFile(
    'dart_releases.json',
  );
  late final File defaultEnvNameFile = puroRoot.childFile('default_env');
  late final Link defaultEnvLink = envsDir.childLink('default');
  late final Uri puroLatestVersionUrl = puroBuildsUrl.append(path: 'latest');
  late final File puroLatestVersionFile = puroRoot.childFile('latest_version');
  late final Directory depotToolsDir = puroRoot.childDirectory('depot_tools');

  late List<String> desiredEnvPaths = [
    binDir.path,
    pubCacheBinDir.path,
    getEnv('default', resolve: false).flutter.binDir.path,
  ];

  EnvConfig getEnv(String name, {bool resolve = true}) {
    if (resolve && name == 'default') {
      if (defaultEnvLink.existsSync()) {
        final target = fileSystem.directory(defaultEnvLink.targetSync());
        name = target.basename;
      } else {
        name = 'stable';
      }
    }
    name = name.toLowerCase();
    ensureValidEnvName(name);
    return EnvConfig(parentConfig: this, envDir: envsDir.childDirectory(name));
  }

  late final ProjectConfig project = ProjectConfig(
    parentConfig: this,
    projectDir: projectDir,
    parentProjectDir: parentProjectDir,
  );

  EnvConfig? tryGetProjectEnv() {
    if (environmentOverride != null) {
      final result = getEnv(environmentOverride!);
      return result.exists ? result : null;
    }
    return project.tryGetProjectEnv();
  }

  Directory? findVSCodeWorkspaceDir(Directory projectDir) {
    final dir = findProjectDir(projectDir, '.vscode');
    if (dir != null && dir.pathEquals(homeDir)) {
      return null;
    }
    return dir;
  }

  FlutterCacheConfig getFlutterCache(
    String engineCommit, {
    required bool patched,
  }) {
    if (!isValidCommitHash(engineCommit)) {
      throw ArgumentError.value(
        engineCommit,
        'engineVersion',
        'Invalid commit hash',
      );
    }
    if (patched) {
      return FlutterCacheConfig(
        sharedCachesDir.childDirectory('${engineCommit}_patched'),
      );
    } else {
      return FlutterCacheConfig(sharedCachesDir.childDirectory(engineCommit));
    }
  }

  DartSdkConfig getDartRelease(DartRelease release) {
    return DartSdkConfig(
      sharedDartReleaseDir
          .childDirectory(release.name)
          .childDirectory('dart-sdk'),
    );
  }

  Uri? tryGetFlutterGitDownloadUrl({
    required String commit,
    required String path,
  }) {
    const httpPrefix = 'https://github.com/';
    const sshPrefix = 'git@github.com:';
    final isHttp = flutterGitUrl.startsWith(httpPrefix);
    if ((isHttp || flutterGitUrl.startsWith(sshPrefix)) &&
        flutterGitUrl.endsWith('.git')) {
      return Uri.https(
        'raw.githubusercontent.com',
        '${flutterGitUrl.substring(isHttp ? httpPrefix.length : sshPrefix.length, flutterGitUrl.length - 4)}/$commit/$path',
      );
    }
    return null;
  }

  Uri? tryGetEngineGitDownloadUrl({
    required String commit,
    required String path,
  }) {
    const httpPrefix = 'https://github.com/';
    const sshPrefix = 'git@github.com:';
    final isHttp = engineGitUrl.startsWith(httpPrefix);
    if ((isHttp || engineGitUrl.startsWith(sshPrefix)) &&
        engineGitUrl.endsWith('.git')) {
      return Uri.https(
        'raw.githubusercontent.com',
        '${engineGitUrl.substring(isHttp ? httpPrefix.length : sshPrefix.length, engineGitUrl.length - 4)}/$commit/$path',
      );
    }
    return null;
  }

  String shortenHome(String path) {
    if (path.startsWith(homeDir.path)) {
      return '~' + path.substring(homeDir.path.length);
    }
    return path;
  }

  @override
  String toString() {
    return 'PuroConfig(\n'
        '  gitExecutable: $gitExecutable,\n'
        '  puroRoot: $puroRoot,\n'
        '  pubCacheDir: $legacyPubCacheDir,\n'
        '  homeDir: $homeDir,\n'
        '  projectDir: $projectDir,\n'
        '  parentProjectDir: $parentProjectDir,\n'
        '  flutterGitUrl: $flutterGitUrl,\n'
        '  engineGitUrl: $engineGitUrl,\n'
        '  dartSdkGitUrl: $dartSdkGitUrl,\n'
        '  releasesJsonUrl: $releasesJsonUrl,\n'
        '  flutterStorageBaseUrl: $flutterStorageBaseUrl,\n'
        '  environmentOverride: $environmentOverride,\n'
        '  puroBuildsUrl: $puroBuildsUrl,\n'
        '  buildTarget: $buildTarget,\n'
        '  enableShims: $enableShims,\n'
        '  shouldInstall: $shouldInstall,\n'
        '  legacyPubCache: $legacyPubCache,\n'
        ')';
  }

  static final provider = Provider<PuroConfig>.late();
  static PuroConfig of(Scope scope) => scope.read(provider);
}

class ProjectConfig {
  ProjectConfig({
    required this.parentConfig,
    required this.projectDir,
    required this.parentProjectDir,
  });

  final PuroConfig parentConfig;
  final Directory? projectDir;
  final Directory? parentProjectDir;

  late final File? pubspecYamlFile = projectDir?.childFile('pubspec.yaml');
  late final File? puroDotfile = projectDir?.childFile(dotfileName);
  late final File? parentPuroDotfile = parentProjectDir?.childFile(dotfileName);

  static const dotfileName = '.puro.json';

  Directory ensureParentProjectDir() {
    final dir = parentProjectDir;
    if (dir == null) {
      throw CommandError(
        'Could not find a dart project in the current directory and no '
        'path selected with --project',
      );
    }
    return dir;
  }

  EnvConfig? tryGetProjectEnv() {
    if (parentPuroDotfile?.existsSync() != true) return null;
    final dotfile = readDotfile();
    if (!dotfile.hasEnv()) return null;
    final result = parentConfig.getEnv(dotfile.env);
    return result.exists ? result : null;
  }

  File get dotfileForWriting {
    if (!(projectDir?.pathEquals(parentProjectDir!) ?? true)) {
      throw CommandError(
        'Found projects in both `${projectDir?.path}` and `${parentProjectDir?.path}`,'
        ' run this command in the parent directory or use `--project '
        '${path.relative(projectDir!.path, from: path.current)}'
        '` to switch regardless\n'
        "This check is done to make sure nested projects aren't using a different "
        'Flutter version as their parent',
      );
    }
    if (puroDotfile == null) ensureParentProjectDir();
    return puroDotfile!;
  }

  PuroDotfileModel readDotfile() {
    final model = PuroDotfileModel.create();
    if (parentPuroDotfile?.existsSync() ?? false) {
      model.mergeFromProto3Json(
        jsonDecode(parentPuroDotfile!.readAsStringSync()),
      );
    }
    return model;
  }

  PuroDotfileModel readDotfileForWriting() {
    final model = PuroDotfileModel.create();
    if (dotfileForWriting.existsSync()) {
      model.mergeFromProto3Json(
        jsonDecode(dotfileForWriting.readAsStringSync()),
      );
    }
    return model;
  }

  Future<void> writeDotfile(Scope scope, PuroDotfileModel dotfile) async {
    final log = PuroLogger.of(scope);
    final file = dotfileForWriting;
    final jsonStr = prettyJsonEncoder.convert(dotfile.toProto3Json());
    log.d(() => 'Writing dotfile ${file.path}\n$jsonStr');
    file.writeAsStringSync(jsonStr);
    await registerDotfile(scope: scope, dotfile: file);
  }
}

class EnvConfig {
  EnvConfig({required this.parentConfig, required this.envDir});

  final PuroConfig parentConfig;
  final Directory envDir;

  late final String name = envDir.basename;
  late final Directory recipeDir = envDir.childDirectory('recipe');
  late final Directory engineRootDir = envDir.childDirectory('engine');
  late final EngineConfig engine = EngineConfig(engineRootDir);
  late final Directory flutterDir = envDir.childDirectory('flutter');
  late final FlutterConfig flutter = FlutterConfig(flutterDir);
  late final File prefsJsonFile = envDir.childFile('prefs.json');
  late final File updateLockFile = envDir.childFile('update.lock');
  late final Directory evalDir = envDir.childDirectory('eval');
  late final Directory evalBootstrapDir = evalDir.childDirectory('bootstrap');
  late final File evalBootstrapPackagesFile = evalBootstrapDir
      .childDirectory('.dart_tool')
      .childFile('package_config.json');

  bool get exists => envDir.existsSync();

  void ensureExists([String? message]) {
    if (!exists) {
      throw CommandError(message ?? 'Environment `$name` does not exist');
    }
  }

  // TODO(ping): Maybe support changing this in the future, the flutter tool
  // lets you change it with an environment variable
  String get flutterToolArgs => '';

  Future<PuroEnvPrefsModel> readPrefs({required Scope scope}) async {
    final model = PuroEnvPrefsModel();
    if (prefsJsonFile.existsSync()) {
      final contents = await readAtomic(scope: scope, file: prefsJsonFile);
      model.mergeFromProto3Json(jsonDecode(contents));
    }
    return model;
  }

  Future<PuroEnvPrefsModel> updatePrefs({
    required Scope scope,
    required FutureOr<void> Function(PuroEnvPrefsModel prefs) fn,
    bool background = false,
  }) {
    return lockFile(scope, prefsJsonFile, (handle) async {
      final model = PuroEnvPrefsModel();
      String? contents;
      if (handle.lengthSync() > 0) {
        contents = handle.readAllAsStringSync();
        model.mergeFromProto3Json(jsonDecode(contents));
      }
      await fn(model);
      final newContents = prettyJsonEncoder.convert(model.toProto3Json());
      if (contents != newContents) {
        handle.writeAllStringSync(newContents);
      }
      return model;
    }, mode: FileMode.append);
  }
}

class FlutterConfig {
  FlutterConfig(this.sdkDir);

  final Directory sdkDir;

  late final Directory binDir = sdkDir.childDirectory('bin');
  late final Directory packagesDir = sdkDir.childDirectory('packages');
  late final File flutterScript = binDir.childFile(
    Platform.isWindows ? 'flutter.bat' : 'flutter',
  );
  late final File dartScript = binDir.childFile(
    Platform.isWindows ? 'dart.bat' : 'dart',
  );
  late final Directory binInternalDir = binDir.childDirectory('internal');
  late final Directory cacheDir = binDir.childDirectory('cache');
  late final FlutterCacheConfig cache = FlutterCacheConfig(cacheDir);
  late final File engineVersionFile = binInternalDir.childFile(
    'engine.version',
  );
  late final Directory flutterToolsDir = packagesDir.childDirectory(
    'flutter_tools',
  );
  late final File flutterToolsScriptFile = flutterToolsDir
      .childDirectory('bin')
      .childFile('flutter_tools.dart');
  late final File flutterToolsPubspecYamlFile = flutterToolsDir.childFile(
    'pubspec.yaml',
  );
  late final File flutterToolsPubspecLockFile = flutterToolsDir.childFile(
    'pubspec.lock',
  );
  late final File flutterToolsPackageConfigJsonFile = flutterToolsDir
      .childDirectory('.dart_tool')
      .childFile('package_config.json');
  late final File flutterToolsLegacyPackagesFile = flutterToolsDir.childFile(
    '.packages',
  );
  late final File legacyVersionFile = sdkDir.childFile('version');

  String? get engineVersion => engineVersionFile.existsSync()
      ? engineVersionFile.readAsStringSync().trim()
      : null;

  bool get hasEngine => sdkDir
      .childDirectory('engine')
      .childDirectory('src')
      .childFile('.gn')
      .existsSync();
}

class FlutterCacheConfig {
  FlutterCacheConfig(this.cacheDir);

  final Directory cacheDir;

  late final Directory dartSdkDir = cacheDir.childDirectory('dart-sdk');
  late final DartSdkConfig dartSdk = DartSdkConfig(dartSdkDir);

  late final File flutterToolsStampFile = cacheDir.childFile(
    'flutter_tools.stamp',
  );
  late final File engineStampFile = cacheDir.childFile('engine.stamp');
  late final File engineRealmFile = cacheDir.childFile('engine.realm');
  late final File engineVersionFile = cacheDir.childFile(
    'engine-dart-sdk.stamp',
  );
  String? get engineVersion => engineVersionFile.existsSync()
      ? engineVersionFile.readAsStringSync().trim()
      : null;
  String? get flutterToolsStamp => flutterToolsStampFile.existsSync()
      ? flutterToolsStampFile.readAsStringSync().trim()
      : null;
  late final File versionJsonFile = cacheDir.childFile('flutter.version.json');

  bool get exists => cacheDir.existsSync();
}

class DartSdkConfig {
  DartSdkConfig(this.sdkDir);

  final Directory sdkDir;

  late final Directory binDir = sdkDir.childDirectory('bin');

  late final File dartExecutable = binDir.childFile(
    Platform.isWindows ? 'dart.exe' : 'dart',
  );

  // This no longer exists on recent versions of Dart where we instead use
  // `dart pub`.
  late final File oldPubExecutable = binDir.childFile(
    Platform.isWindows ? 'pub.bat' : 'pub',
  );

  late final Directory libDir = sdkDir.childDirectory('lib');
  late final Directory internalLibDir = libDir.childDirectory('_internal');
  late final File librariesJsonFile = libDir.childFile('libraries.json');
  late final File internalLibrariesDartFile = internalLibDir
      .childDirectory('sdk_library_metadata')
      .childDirectory('lib')
      .childFile('libraries.dart');
  late final File revisionFile = sdkDir.childFile('revision');
  late final File versionFile = sdkDir.childFile('version');
  late final File versionJsonFile = sdkDir.childFile('version.json');
  late final commitHash = revisionFile.readAsStringSync().trim();
}

class EngineConfig {
  EngineConfig(this.rootDir);

  final Directory rootDir;

  late final File gclientFile = rootDir.childFile('.gclient');
  late final Directory srcDir = rootDir.childDirectory('src');
  late final Directory engineSrcDir = srcDir.childDirectory('flutter');

  bool get exists => rootDir.existsSync();

  void ensureExists([String? message]) {
    if (!exists) {
      throw CommandError(
        message ??
            'Environment `${rootDir.parent.basename}` does not have a custom engine, '
                'use `puro engine prepare ${rootDir.parent.basename}` to create one',
      );
    }
  }
}

final _nameRegex = RegExp(r'^[_\-a-z][_\-a-z0-9]*$');
bool isValidName(String name) {
  return _nameRegex.hasMatch(name);
}

bool isValidVersion(String name) {
  final version = tryParseVersion(name);
  return version != null && name == '$version';
}

bool isValidEnvName(String name) {
  return isValidName(name) || isValidVersion(name);
}

final _commitHashRegex = RegExp(r'^[0-9a-f]{5,40}$');
bool isValidCommitHash(String commit) {
  return _commitHashRegex.hasMatch(commit);
}

Version? tryParseVersion(String text) {
  try {
    text = text.trim();
    return Version.parse(text.startsWith('v') ? text.substring(1) : text);
  } catch (exception) {
    return null;
  }
}

void ensureValidEnvName(String name) {
  if (isValidVersion(name)) return;
  for (var i = 0; i < name.length; i++) {
    final char = name[i];
    final codeUnit = char.codeUnitAt(0);
    if (char == '-' ||
        char == '_' ||
        (i != 0 && codeUnit >= 0x30 && codeUnit <= 0x39) ||
        (codeUnit >= 0x61 && codeUnit <= 0x7a)) {
      continue;
    }
    throw CommandError(
      'Unexpected `$char` at index $i of name `$name`\n'
      'Names must match pattern [_\\-a-z][_\\-a-z0-9]* or be a valid version',
    );
  }
  if (!isValidName(name)) {
    throw CommandError('Not a valid name: `$name`');
  }
}

const prettyJsonEncoder = JsonEncoder.withIndent('  ');

Future<PuroGlobalPrefsModel> _readGlobalPrefs({required Scope scope}) async {
  final model = PuroGlobalPrefsModel();
  final file = scope.read(globalPrefsJsonFileProvider);
  if (file.existsSync()) {
    final contents = await readAtomic(scope: scope, file: file);
    model.mergeFromProto3Json(jsonDecode(contents));
  }
  return model;
}

Future<PuroGlobalPrefsModel> _updateGlobalPrefs({
  required Scope scope,
  required FutureOr<void> Function(PuroGlobalPrefsModel prefs) fn,
  bool background = false,
}) {
  final file = scope.read(globalPrefsJsonFileProvider);
  file.parent.createSync(recursive: true);
  return lockFile(scope, file, (handle) async {
    final model = PuroGlobalPrefsModel();
    String? contents;
    if (handle.lengthSync() > 0) {
      contents = handle.readAllAsStringSync();
      model.mergeFromProto3Json(jsonDecode(contents));
    }
    await fn(model);
    if (!model.hasLegacyPubCache()) {
      model.legacyPubCache = !scope.read(isFirstRunProvider);
    }
    final newContents = prettyJsonEncoder.convert(model.toProto3Json());
    if (contents != newContents) {
      handle.writeAllStringSync(newContents);
    }
    return model;
  }, mode: FileMode.append);
}

final globalPrefsJsonFileProvider = Provider<File>.late();
final isFirstRunProvider = Provider<bool>.late();
final globalPrefsProvider = Provider<Future<PuroGlobalPrefsModel>>(
  (scope) => _readGlobalPrefs(scope: scope),
);

Future<PuroGlobalPrefsModel> readGlobalPrefs({required Scope scope}) {
  return scope.read(globalPrefsProvider);
}

Future<PuroGlobalPrefsModel> updateGlobalPrefs({
  required Scope scope,
  required FutureOr<void> Function(PuroGlobalPrefsModel prefs) fn,
  bool background = false,
}) async {
  await scope.read(globalPrefsProvider);
  final result = await _updateGlobalPrefs(
    scope: scope,
    fn: fn,
    background: background,
  );
  scope.replace(globalPrefsProvider, Future.value(result));
  return result;
}

Future<void> registerDotfile({
  required Scope scope,
  required File dotfile,
}) async {
  final prefs = await readGlobalPrefs(scope: scope);
  final canonical = dotfile.resolveIfExists().path;
  if (!prefs.projectDotfiles.contains(canonical)) {
    await updateGlobalPrefs(
      scope: scope,
      fn: (prefs) {
        prefs.projectDotfiles.add(canonical);
      },
    );
  }
}

Future<void> cleanDotfiles({required Scope scope}) {
  final config = PuroConfig.of(scope);
  return updateGlobalPrefs(
    scope: scope,
    fn: (prefs) {
      for (final path in prefs.projectDotfiles.toList()) {
        final canonical = config.fileSystem.file(path).resolveIfExists().path;
        if (config.fileSystem.statSync(path).type ==
            FileSystemEntityType.notFound) {
          prefs.projectDotfiles.remove(path);
        } else if (canonical != path) {
          prefs.projectDotfiles.remove(path);
          prefs.projectDotfiles.add(canonical);
        }
      }
    },
  );
}

Future<Map<String, List<File>>> getAllDotfiles({required Scope scope}) async {
  final log = PuroLogger.of(scope);
  final config = PuroConfig.of(scope);
  final prefs = await readGlobalPrefs(scope: scope);
  final result = <String, Set<String>>{};
  var needsClean = false;
  for (final path in prefs.projectDotfiles) {
    final dotfile = config.fileSystem.file(path);
    if (!dotfile.existsSync()) {
      needsClean = true;
      continue;
    }
    try {
      final data = jsonDecode(dotfile.readAsStringSync());
      final model = PuroDotfileModel.create();
      model.mergeFromProto3Json(data);
      if (model.hasEnv()) {
        result
            .putIfAbsent(model.env, () => {})
            .add(dotfile.resolveSymbolicLinksSync());
      }
    } catch (exception, stackTrace) {
      log.w('Error while reading $path');
      log.w('$exception\n$stackTrace');
    }
  }
  log.d(() => 'all dotfiles: $result');
  if (needsClean) {
    await cleanDotfiles(scope: scope);
  }
  return result.map(
    (key, value) =>
        MapEntry(key, value.map((e) => config.fileSystem.file(e)).toList()),
  );
}

Future<List<File>> getDotfilesUsingEnv({
  required Scope scope,
  required EnvConfig environment,
}) async {
  return (await getAllDotfiles(scope: scope))[environment.name] ?? [];
}

class PuroInternalPrefsVars {
  PuroInternalPrefsVars({required this.scope, required this.config});

  final Scope scope;
  final PuroConfig config;
  PuroGlobalPrefsModel? prefs;

  static final _fieldInfo = PuroGlobalPrefsModel.getDefault().info_.fieldInfo;
  static final _fields = {
    for (final field in _fieldInfo.values) field.name: field,
  };

  Future<dynamic> readVar(String key) async {
    if (!_fields.containsKey(key)) {
      throw 'No such key ${jsonEncode(key)}, valid keys: ${_fields.keys.toList()}';
    }
    prefs ??= await readGlobalPrefs(scope: scope);
    final data = prefs!.toProto3Json() as Map<String, dynamic>;
    return data[key];
  }

  Future<void> writeVar(String key, String value) async {
    final field = _fields[key];
    if (field == null) {
      throw 'No such key ${jsonEncode(key)}, valid keys: ${_fields.keys.toList()}';
    }
    await updateGlobalPrefs(
      scope: scope,
      fn: (prefs) {
        final data = prefs.toProto3Json() as Map<String, dynamic>;

        if (value == 'null') {
          data.remove(key);
        } else {
          // If the field is a string, and the value does not start with ", just use
          // that literal value, otherwise we interpret it as json.
          if (field.type & PbFieldType.OS == PbFieldType.OS &&
              !value.startsWith('"')) {
            data[key] = value;
          } else {
            data[key] = jsonDecode(value);
          }
          prefs = prefs;
        }

        prefs.clear();
        prefs.mergeFromProto3Json(data);
      },
    );
  }
}
