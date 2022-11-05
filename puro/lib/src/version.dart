import 'dart:io';

import 'package:file/file.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'config.dart';
import 'git.dart';
import 'provider.dart';

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

/// Attempts to find the version of puro using either the `puro_version` define
/// or the git tag.
Future<Version> getPuroVersion({
  required Scope scope,
  bool withCommit = true,
}) async {
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
}

enum PuroBuildTarget {
  windowsX64('windows-x64', 'puro.exe'),
  linuxX64('linux-x64', 'puro'),
  macosX64('darwin-x64', 'puro');

  const PuroBuildTarget(this.name, this.executable);

  final String name;
  final String executable;

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
