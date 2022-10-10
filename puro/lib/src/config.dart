import 'dart:io';

import 'package:file/file.dart';
import 'package:process/process.dart';
import 'package:puro/src/provider.dart';

Directory? findProjectDir(Directory directory) {
  while (directory.existsSync()) {
    if (directory.childFile('pubspec.yaml').existsSync()) {
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
    required this.gitExecutable,
    required Directory puroRoot,
    required this.projectDir,
    required this.flutterGitUrl,
    required this.engineGitUrl,
    required this.releasesJsonUrl,
  }) : puroRoot = puroRoot.absolute;

  factory PuroConfig.fromCommandLine({
    required FileSystem fileSystem,
    required String? gitExecutable,
    required String? puroRoot,
    required String? workingDir,
    required String? flutterGitUrl,
    required String? engineGitUrl,
    required String? releasesJsonUrl,
  }) {
    gitExecutable ??= 'git';
    if (!LocalProcessManager().canRun(gitExecutable)) {
      throw ArgumentError('Git executable not found');
    }

    final String homeDir;
    if (Platform.isWindows) {
      homeDir = Platform.environment['UserProfile']!;
    } else {
      homeDir = Platform.environment['HOME']!;
    }

    return PuroConfig(
      gitExecutable: fileSystem.file(gitExecutable),
      puroRoot: puroRoot != null
          ? fileSystem.directory(puroRoot)
          : fileSystem.directory(homeDir).childDirectory('.puro'),
      projectDir: findProjectDir(
        workingDir == null
            ? fileSystem.currentDirectory
            : fileSystem.directory(workingDir),
      ),
      flutterGitUrl: Uri.parse(
        flutterGitUrl ?? 'https://github.com/flutter/flutter.git',
      ),
      engineGitUrl: Uri.parse(
        engineGitUrl ?? 'https://github.com/flutter/engine.git',
      ),
      releasesJsonUrl: Uri.parse(
        releasesJsonUrl ??
            'https://storage.googleapis.com/flutter_infra_release/releases/releases_${Platform.operatingSystem}.json',
      ),
    );
  }

  final File gitExecutable;
  final Directory puroRoot;
  final Directory? projectDir;
  final Uri flutterGitUrl;
  final Uri engineGitUrl;
  final Uri releasesJsonUrl;

  late final File pubspecYamlFile = projectDir!.childFile('pubspec.yaml');
  late final File puroYamlFile = projectDir!.childFile('.puro');
  late final Directory envsDir = puroRoot.childDirectory('envs');
  late final Directory sharedDir = puroRoot.childDirectory('shared');

  PuroEnvConfig getEnv(String name) {
    ensureValidName(name);
    return PuroEnvConfig(envDir: envsDir.childDirectory(name));
  }

  static final provider = Provider<PuroConfig>.late();
  static PuroConfig of(Scope scope) => scope.read(provider);
}

class PuroEnvConfig {
  PuroEnvConfig({
    required this.envDir,
  });

  final Directory envDir;

  bool get exists => envDir.existsSync();

  late final String name = envDir.basename;
  late final Directory recipeDir = envDir.childDirectory('recipe');
  late final Directory engineDir = envDir.childDirectory('engine');
  late final Directory dartSdkDir = envDir.childDirectory('dart');
  late final Directory flutterDir = envDir.childDirectory('flutter');
  late final PuroFlutterConfig flutterConfig = PuroFlutterConfig(flutterDir);
}

class PuroFlutterConfig {
  PuroFlutterConfig(this.sdkDir);

  final Directory sdkDir;

  late final Directory binDir = sdkDir.childDirectory('bin');
  late final Directory binInternalDir = binDir.childDirectory('internal');
  late final Directory cacheDir = binDir.childDirectory('cache');
  late final Directory dartSdkDir = cacheDir.childDirectory('dart-sdk');
  late final File engineVersionFile =
      binInternalDir.childFile('engine.version');

  late final File flutterExecutable = Platform.isWindows
      ? binDir.childFile('flutter.bat')
      : binDir.childFile('flutter');

  late final File dartExecutable = Platform.isWindows
      ? binDir.childFile('dart.bat')
      : binDir.childFile('dart');

  late final String engineVersion = engineVersionFile.readAsStringSync().trim();
}

final _nameRegex = RegExp(
  r'^[_\-\p{L}][_\-\p{L}\p{N}]+?$',
  unicode: true,
);
bool isValidName(String name) {
  return _nameRegex.hasMatch(name);
}

void ensureValidName(String name) {
  if (!isValidName(name)) {
    throw ArgumentError('Not a valid name: `$name`');
  }
}
