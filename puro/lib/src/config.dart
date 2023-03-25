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
    required this.enableShims,
    required this.shouldInstall,
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
    required bool? shouldInstall,
  }) {
    final log = PuroLogger.of(scope);

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

    final String homeDir;
    if (Platform.isWindows) {
      homeDir = Platform.environment['UserProfile']!;
    } else {
      homeDir = Platform.environment['HOME']!;
    }

    final absoluteProjectDir =
        projectDir == null ? null : fileSystem.directory(projectDir).absolute;

    var resultProjectDir = absoluteProjectDir ??
        findProjectDir(
          currentDir,
          'pubspec.yaml',
        );

    // Puro looks for a suitable project root in the following order:
    //   1. Directory specified in `--project`
    //   2. Closest parent directory with a `.puro.json`
    //   3. Closest grandparent directory with a `pubspec.yaml`
    //
    // If Puro finds a grandparent and tries to access the parentProjectDir with
    // dotfileForWriting, it throws an error indicating the selection is
    // ambiguous.
    final Directory? parentProjectDir = absoluteProjectDir ??
        findProjectDir(
          currentDir,
          dotfileName,
        ) ??
        (resultProjectDir != null
            ? findProjectDir(
                resultProjectDir.parent,
                'pubspec.yaml',
              )
            : null) ??
        resultProjectDir;

    resultProjectDir ??= parentProjectDir;

    final envPuroRoot = Platform.environment['PURO_ROOT'];

    var puroRootDir = puroRoot != null
        ? fileSystem.directory(puroRoot)
        : envPuroRoot?.isNotEmpty ?? false
            ? fileSystem.directory(envPuroRoot)
            : fileSystem.directory(homeDir).childDirectory('.puro');

    puroRootDir.createSync(recursive: true);
    puroRootDir =
        fileSystem.directory(puroRootDir.resolveSymbolicLinksSync()).absolute;

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

    if (flutterStorageBaseUrl == null) {
      final override = Platform.environment['FLUTTER_STORAGE_BASE_URL'];
      if (override != null && override.isNotEmpty) {
        flutterStorageBaseUrl = override;
      }
    }

    flutterStorageBaseUrl ??= 'https://storage.googleapis.com';

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
            '$flutterStorageBaseUrl/flutter_infra_release/releases/releases_${Platform.operatingSystem}.json',
      ),
      flutterStorageBaseUrl: Uri.parse(flutterStorageBaseUrl),
      environmentOverride: environmentOverride,
      puroBuildsUrl: Uri.parse('https://puro.dev/builds'),
      buildTarget: PuroBuildTarget.query(),
      enableShims: false,
      shouldInstall: shouldInstall ?? true,
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
  final bool enableShims;
  final bool shouldInstall;

  static const dotfileName = '.puro.json';

  late final File? pubspecYamlFile = projectDir?.childFile('pubspec.yaml');
  late final File? puroDotfile = projectDir?.childFile(dotfileName);
  late final File? parentPuroDotfile = parentProjectDir?.childFile(dotfileName);
  late final Directory envsDir = puroRoot.childDirectory('envs');
  late final Directory binDir = puroRoot.childDirectory('bin');
  late final Directory sharedDir = puroRoot.childDirectory('shared');
  late final Directory sharedFlutterDir = sharedDir.childDirectory('flutter');
  late final Directory sharedEngineDir = sharedDir.childDirectory('engine');
  late final Directory sharedCachesDir = sharedDir.childDirectory('caches');
  late final Directory sharedDartPkgDir = sharedDir.childDirectory('dart_pkg');
  late final Directory sharedGClientDir = sharedDir.childDirectory('gclient');
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
  late final Link defaultEnvLink = envsDir.childLink('default');
  late final Uri puroLatestVersionUrl = puroBuildsUrl.append(path: 'latest');
  late final File globalPrefsJsonFile = puroRoot.childFile('prefs.json');
  late final File puroLatestVersionFile = puroRoot.childFile('latest_version');
  late final Directory depotToolsDir = puroRoot.childDirectory('depot_tools');

  late List<String> desiredEnvPaths = [
    binDir.path,
    pubCacheBinDir.path,
    getEnv('default', resolve: false).flutter.binDir.path,
  ];

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
    final result = getEnv(dotfile.env);
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

  Directory? findVSCodeWorkspaceDir(Directory projectDir) {
    final dir = findProjectDir(projectDir, '.vscode');
    if (dir != null && dir.pathEquals(homeDir)) {
      return null;
    }
    return dir;
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
        '  puroBuildsUrl: $puroBuildsUrl,\n'
        '  buildTarget: $buildTarget,\n'
        '  enableShims: $enableShims,\n'
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

  // This no longer exists on recent versions of Dart where we instead use
  // `dart pub`.
  late final File oldPubExecutable =
      binDir.childFile(Platform.isWindows ? 'pub.bat' : 'pub');

  late final Directory libDir = sdkDir.childDirectory('lib');
  late final Directory internalLibDir = libDir.childDirectory('_internal');
  late final File librariesJsonFile = libDir.childFile('libraries.json');
  late final File internalLibrariesDartFile = internalLibDir
      .childDirectory('sdk_library_metadata')
      .childDirectory('lib')
      .childFile('libraries.dart');
  late final File revisionFile = sdkDir.childFile('revision');
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
    throw CommandError(
      'Unexpected `$char` at index $i of name `$name`\n'
      'Names must match pattern [_\\-a-z][_\\-a-z0-9]*',
    );
  }
  if (!isValidName(name)) {
    throw CommandError('Not a valid name: `$name`');
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
  config.globalPrefsJsonFile.parent.createSync(recursive: true);
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
