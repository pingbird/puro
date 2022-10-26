import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'config.dart';
import 'git.dart';
import 'provider.dart';

const _puroVersionDefine = String.fromEnvironment('puro_version');

/// Attempts to find the version of puro, returning either the puro_version
/// dart define or the version in pubspec.yaml with commit appended.
Future<Version?> getPuroVersion({
  required Scope scope,
  bool withCommit = true,
}) async {
  final config = PuroConfig.of(scope);
  final git = GitClient.of(scope);
  if (_puroVersionDefine.isNotEmpty) return Version.parse(_puroVersionDefine);
  final scriptUri = Platform.script;
  final scriptFile = config.fileSystem.file(scriptUri.toFilePath()).absolute;
  final puroPackage = findProjectDir(scriptFile.parent, 'pubspec.yaml');
  if (puroPackage == null) return null;
  final pubspecFile = puroPackage.childFile('pubspec.yaml');
  final dynamic pubspecData = loadYaml(await pubspecFile.readAsString());
  if (pubspecData['name'] != 'puro') return null;
  final version = Version.parse(pubspecData['version'] as String);
  if (!withCommit) {
    return version;
  }
  final commit = await git.getCurrentCommitHash(
    repository: puroPackage,
    short: true,
  );
  return Version(
    version.major,
    version.minor,
    version.patch,
    build: commit,
  );
}
