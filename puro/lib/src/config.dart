import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';
import 'package:pub_semver/pub_semver.dart';

import '../models.dart';
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
    required Directory puroRoot,
    required this.homeDir,
    required this.projectDir,
    required this.parentProjectDir,
    required this.flutterGitUrl,
    required this.engineGitUrl,
    required this.releasesJsonUrl,
    required this.flutterStorageBaseUrl,
    required this.environmentOverride,
    required this.puroBuildsUrl,
    required this.buildTarget,
  }) : puroRoot = puroRoot.absolute;

  factory PuroConfig.fromCommandLine({
    required Scope scope,
    required FileSystem fileSystem,
    required String? gitExecutable,
    required String? puroRoot,
    required String? workingDir,
    required String? projectDir,
    required String? flutterGitUrl,
    required String? engineGitUrl,
    required String? releasesJsonUrl,
    required String? flutterStorageBaseUrl,
    required String? environmentOverride,
  }) {
    final log = PuroLogger.of(scope);

    final currentDir = workingDir == null
        ? fileSystem.currentDirectory
        : fileSystem.directory(workingDir).absolute;

    if (projectDir != null) projectDir = path.join(currentDir.path, projectDir);

    gitExecutable ??= 'git';
    if (!const LocalProcessManager().canRun(gitExecutable)) {
      throw ArgumentError('Git executable not found');
    }

    final String homeDir;
    if (Platform.isWindows) {
      homeDir = Platform.environment['UserProfile']!;
    } else {
      homeDir = Platform.environment['HOME']!;
    }

    final absoluteProjectDir =
        projectDir == null ? null : fileSystem.directory(projectDir).absolute;

    final resultProjectDir = absoluteProjectDir ??
        findProjectDir(
          currentDir,
          'pubspec.yaml',
        );

    final parentProjectDir = absoluteProjectDir ??
        findProjectDir(
          currentDir,
          dotfileName,
        ) ??
        resultProjectDir;

    final puroRootDir = puroRoot != null
        ? fileSystem.directory(puroRoot)
        : fileSystem.directory(homeDir).childDirectory('.puro');

    if (environmentOverride == null) {
      final flutterBin = Platform.environment['FLUTTER_BIN'];
      log.d('FLUTTER_BIN: $flutterBin');
      if (flutterBin != null) {
        final flutterBinDir = fileSystem.directory(flutterBin).absolute;
        final flutterSdkDir = flutterBinDir.parent;
        final envDir = flutterSdkDir.parent;
        final envsDir = envDir.parent;
        final otherPuroRootDir = envsDir.parent;
        log.d('otherPuroRootDir: $otherPuroRootDir');
        log.d('puroRootDir: $puroRootDir');
        if (otherPuroRootDir.pathEquals(puroRootDir)) {
          environmentOverride = envDir.basename.toLowerCase();
          log.d('environmentOverride: $environmentOverride');
        }
      }
    }

    return PuroConfig(
      fileSystem: fileSystem,
      gitExecutable: fileSystem.file(gitExecutable),
      puroRoot: puroRootDir,
      homeDir: fileSystem.directory(homeDir),
      projectDir: resultProjectDir,
      parentProjectDir: parentProjectDir,
      flutterGitUrl: flutterGitUrl ?? 'https://github.com/flutter/flutter.git',
      engineGitUrl: engineGitUrl ?? 'https://github.com/flutter/engine.git',
      releasesJsonUrl: Uri.parse(
        releasesJsonUrl ??
            'https://storage.googleapis.com/flutter_infra_release/releases/releases_${Platform.operatingSystem}.json',
      ),
      flutterStorageBaseUrl: Uri.parse(
        flutterStorageBaseUrl ?? 'https://storage.googleapis.com',
      ),
      environmentOverride: environmentOverride,
      puroBuildsUrl: Uri.parse('https://puro.dev/builds'),
      buildTarget: PuroBuildTarget.query(),
    );
  }

  final FileSystem fileSystem;
  final File gitExecutable;
  final Directory puroRoot;
  final Directory homeDir;
  final Directory? projectDir;
  final Directory? parentProjectDir;
  final String flutterGitUrl;
  final String engineGitUrl;
  final Uri releasesJsonUrl;
  final Uri flutterStorageBaseUrl;
  final String? environmentOverride;
  final Uri puroBuildsUrl;
  final PuroBuildTarget buildTarget;

  static const dotfileName = '.puro.json';

  late final File? pubspecYamlFile = projectDir?.childFile('pubspec.yaml');
  late final File? puroDotfile = projectDir?.childFile(dotfileName);
  late final File? parentPuroDotfile = parentProjectDir?.childFile(dotfileName);
  late final Directory envsDir = puroRoot.childDirectory('envs');
  late final Directory binDir = puroRoot.childDirectory('bin');
  late final Directory sharedDir = puroRoot.childDirectory('shared');
  late final Directory sharedFlutterDir = sharedDir.childDirectory('flutter');
  late final Directory sharedCachesDir = sharedDir.childDirectory('caches');
  late final Directory pubCacheDir = sharedDir.childDirectory('pub_cache');
  late final Directory pubCacheBinDir = pubCacheDir.childDirectory('bin');
  late final Directory sharedFlutterToolsDir =
      sharedDir.childDirectory('flutter_tools');
  late final File puroExecutableFile =
      binDir.childFile(buildTarget.executableName);
  late final File puroTrampolineFile =
      binDir.childFile(buildTarget.trampolineName);
  late final File puroDartShimFile = binDir.childFile(buildTarget.dartName);
  late final File puroFlutterShimFile =
      binDir.childFile(buildTarget.flutterName);
  late final File puroExecutableTempFile =
      binDir.childFile('${buildTarget.executableName}.tmp');
  late final File cachedReleasesJsonFile =
      puroRoot.childFile(releasesJsonUrl.pathSegments.last);
  late final File defaultEnvNameFile = puroRoot.childFile('default_env');
  late final Uri puroLatestVersionUrl = puroBuildsUrl.append(path: 'latest');
  late final File globalPrefsJsonFile = puroRoot.childFile('prefs.json');
  late final File puroLatestVersionFile = puroRoot.childFile('latest_version');

  Directory ensureParentProjectDir() {
    final dir = parentProjectDir;
    if (dir == null) {
      throw AssertionError('No Dart project in current directory');
    }
    return dir;
  }

  FlutterCacheConfig getFlutterCache(String engineVersion) {
    if (!isValidCommitHash(engineVersion)) {
      throw ArgumentError.value(
        engineVersion,
        'engineVersion',
        'Invalid commit hash',
      );
    }
    return FlutterCacheConfig(sharedCachesDir.childDirectory(engineVersion));
  }

  EnvConfig getEnv(String name) {
    name = name.toLowerCase();
    ensureValidName(name);
    return EnvConfig(parentConfig: this, envDir: envsDir.childDirectory(name));
  }

  EnvConfig? tryGetProjectEnv() {
    if (environmentOverride != null) {
      final result = getEnv(environmentOverride!);
      return result.exists ? result : null;
    }
    if (parentPuroDotfile?.existsSync() != true) return null;
    final dotfile = readDotfile();
    if (!dotfile.hasEnv()) return null;
    return getEnv(dotfile.env);
  }

  File get dotfileForWriting {
    if (projectDir?.path != parentProjectDir?.path) {
      throw AssertionError(
        'Ambiguous project selection between `$projectDir` and `$parentProjectDir`,'
        ' run this command in parent directory or use --project to disambiguate.',
      );
    }
    if (puroDotfile == null) {
      throw AssertionError('Could not find project root');
    }
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

  void writeDotfile(PuroDotfileModel dotfile) {
    dotfileForWriting.writeAsStringSync(
      prettyJsonEncoder.convert(
        dotfile.toProto3Json(),
      ),
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
        '${flutterGitUrl.substring(
          isHttp ? httpPrefix.length : sshPrefix.length,
          flutterGitUrl.length - 4,
        )}/$commit/$path',
      );
    }
    return null;
  }

  @override
  String toString() {
    return 'PuroConfig(\n'
        '  gitExecutable: $gitExecutable,\n'
        '  puroRoot: $puroRoot,\n'
        '  homeDir: $homeDir,\n'
        '  projectDir: $projectDir,\n'
        '  parentProjectDir: $parentProjectDir,\n'
        '  flutterGitUrl: $flutterGitUrl,\n'
        '  engineGitUrl: $engineGitUrl,\n'
        '  releasesJsonUrl: $releasesJsonUrl,\n'
        '  flutterStorageBaseUrl: $flutterStorageBaseUrl,\n'
        '  environmentOverride: $environmentOverride,\n'
        ')';
  }

  static final provider = Provider<PuroConfig>.late();
  static PuroConfig of(Scope scope) => scope.read(provider);
}

class EnvConfig {
  EnvConfig({
    required this.parentConfig,
    required this.envDir,
  });

  final PuroConfig parentConfig;
  final Directory envDir;

  late final String name = envDir.basename;
  late final Directory recipeDir = envDir.childDirectory('recipe');
  late final Directory engineDir = envDir.childDirectory('engine');
  late final Directory flutterDir = envDir.childDirectory('flutter');
  late final FlutterConfig flutter = FlutterConfig(flutterDir);
  late final File prefsJsonFile = envDir.childFile('prefs.json');
  late final File updateLockFile = envDir.childFile('update.lock');

  bool get exists => envDir.existsSync();

  void ensureExists() {
    if (!exists) {
      throw ArgumentError('No such environment `$name`');
    }
  }

  // TODO(ping): Maybe support changing this in the future, the flutter tool
  // lets you change it with an environment variable
  String get flutterToolArgs => '';

  Future<PuroEnvPrefsModel> readPrefs({
    required Scope scope,
  }) async {
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
    return lockFile(
      scope,
      prefsJsonFile,
      (handle) async {
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
      },
      mode: FileMode.append,
    );
  }
}

class FlutterConfig {
  FlutterConfig(this.sdkDir);

  final Directory sdkDir;

  late final Directory binDir = sdkDir.childDirectory('bin');
  late final Directory packagesDir = sdkDir.childDirectory('packages');
  late final File flutterScript =
      binDir.childFile(Platform.isWindows ? 'flutter.bat' : 'flutter');
  late final File dartScript =
      binDir.childFile(Platform.isWindows ? 'dart.bat' : 'dart');
  late final Directory binInternalDir = binDir.childDirectory('internal');
  late final Directory cacheDir = binDir.childDirectory('cache');
  late final FlutterCacheConfig cache = FlutterCacheConfig(cacheDir);
  late final File engineVersionFile =
      binInternalDir.childFile('engine.version');
  late final Directory flutterToolsDir =
      packagesDir.childDirectory('flutter_tools');
  late final File flutterToolsScriptFile =
      flutterToolsDir.childDirectory('bin').childFile('flutter_tools.dart');
  late final File flutterToolsPubspecYamlFile =
      flutterToolsDir.childFile('pubspec.yaml');
  late final File flutterToolsPubspecLockFile =
      flutterToolsDir.childFile('pubspec.lock');
  late final File flutterToolsPackageConfigJsonFile = flutterToolsDir
      .childDirectory('.dart_tool')
      .childFile('package_config.json');
  late final File versionFile = sdkDir.childFile('version');

  String? get engineVersion => engineVersionFile.existsSync()
      ? engineVersionFile.readAsStringSync().trim()
      : null;
}

class FlutterCacheConfig {
  FlutterCacheConfig(this.cacheDir);

  final Directory cacheDir;

  late final Directory dartSdkDir = cacheDir.childDirectory('dart-sdk');
  late final DartSdkConfig dartSdk = DartSdkConfig(dartSdkDir);

  late final File flutterToolsStampFile =
      cacheDir.childFile('flutter_tools.stamp');
  late final File engineVersionFile =
      cacheDir.childFile('engine-dart-sdk.stamp');
  String? get engineVersion => engineVersionFile.existsSync()
      ? engineVersionFile.readAsStringSync().trim()
      : null;
  String? get flutterToolsStamp => flutterToolsStampFile.existsSync()
      ? flutterToolsStampFile.readAsStringSync().trim()
      : null;

  bool get exists => cacheDir.existsSync();
}

class DartSdkConfig {
  DartSdkConfig(this.sdkDir);

  final Directory sdkDir;

  late final Directory binDir = sdkDir.childDirectory('bin');
  late final File dartExecutable =
      binDir.childFile(Platform.isWindows ? 'dart.exe' : 'dart');
  late final Directory libDir = sdkDir.childDirectory('lib');
  late final Directory internalLibDir = libDir.childDirectory('_internal');
  late final File librariesJsonFile = libDir.childFile('libraries.json');
  late final File internalLibrariesDartFile = internalLibDir
      .childDirectory('sdk_library_metadata')
      .childDirectory('lib')
      .childFile('libraries.dart');
}

final _nameRegex = RegExp(r'^[_\-a-z][_\-a-z0-9]*$');
bool isValidName(String name) {
  return _nameRegex.hasMatch(name);
}

final _commitHashRegex = RegExp(r'^[0-9a-f]{5,40}$');
bool isValidCommitHash(String commit) {
  return _commitHashRegex.hasMatch(commit);
}

Version? tryParseVersion(String text) {
  try {
    text = text.trim();
    return Version.parse(text.startsWith('v') ? text.substring(1) : text);
  } catch (_) {
    return null;
  }
}

void ensureValidName(String name) {
  for (var i = 0; i < name.length; i++) {
    final char = name[i];
    final codeUnit = char.codeUnitAt(0);
    if (char == '-' ||
        char == '_' ||
        (i != 0 && codeUnit >= 0x30 && codeUnit <= 0x39) ||
        (codeUnit >= 0x61 && codeUnit <= 0x7a)) {
      continue;
    }
    throw ArgumentError(
      'Unexpected `$char` at index $i of name `$name`\nNames must match pattern [_\\-a-z][_\\-a-z0-9]*',
    );
  }
  if (!isValidName(name)) {
    throw ArgumentError('Not a valid name: `$name`');
  }
}

const prettyJsonEncoder = JsonEncoder.withIndent('  ');

Future<PuroGlobalPrefsModel> readGlobalPrefs({
  required Scope scope,
}) async {
  final model = PuroGlobalPrefsModel();
  final config = PuroConfig.of(scope);
  final file = config.globalPrefsJsonFile;
  if (file.existsSync()) {
    final contents = await readAtomic(scope: scope, file: file);
    model.mergeFromProto3Json(jsonDecode(contents));
  }
  return model;
}

Future<PuroGlobalPrefsModel> updateGlobalPrefs({
  required Scope scope,
  required FutureOr<void> Function(PuroGlobalPrefsModel prefs) fn,
  bool background = false,
}) {
  final config = PuroConfig.of(scope);
  return lockFile(
    scope,
    config.globalPrefsJsonFile,
    (handle) async {
      final model = PuroGlobalPrefsModel();
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
    },
    mode: FileMode.append,
  );
}
