import 'dart:convert';

import 'package:pub_semver/pub_semver.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../command_result.dart';
import '../config.dart';
import '../env/command.dart';
import '../file_lock.dart';
import '../provider.dart';

Future<bool> updateEvalBootstrapProject({
  required Scope scope,
  required EnvConfig environment,
  required String sdkVersion,
  required Map<String, VersionConstraint?> packages,
}) async {
  final bootstrapDir = environment.evalBootstrapDir;
  final pubspecLockFile = bootstrapDir.childFile('pubspec.lock');
  final pubspecYamlFile = bootstrapDir.childFile('pubspec.yaml');
  final updateLockFile = bootstrapDir.childFile('update.lock');
  bootstrapDir.createSync();

  return await lockFile(scope, updateLockFile, (handle) async {
    var satisfied = false;
    if (pubspecLockFile.existsSync()) {
      final yamlData = loadYaml(pubspecLockFile.readAsStringSync()) as YamlMap;
      final existingPackages = <String, Version>{};
      for (final package in (yamlData['packages'] as YamlMap).entries) {
        final name = package.key as String;
        final version = Version.parse(package.value['version'] as String);
        existingPackages[name] = version;
      }
      for (final entry in packages.entries) {
        final hasPackage = existingPackages.containsKey(entry.key);
        if ((hasPackage == (entry.value == VersionConstraint.empty)) ||
            (hasPackage &&
                !(entry.value ?? VersionConstraint.any)
                    .allows(existingPackages[entry.key]!))) {
          satisfied = false;
          break;
        }
      }
    }

    if (satisfied) return false;

    final yaml = YamlEditor(
      pubspecYamlFile.existsSync()
          ? await readAtomic(scope: scope, file: pubspecYamlFile)
          : '{}',
    );

    bool exists(Iterable<Object?> path) =>
        yaml.parseAt(path, orElse: () => YamlScalar.wrap(null)).value != null;

    yaml.update(['name'], 'bootstrap');
    yaml.update(['version'], '0.0.1');
    yaml.update(['environment'], {'sdk': sdkVersion});

    if (!exists(['dependencies'])) {
      yaml.update(['dependencies'], YamlMap());
    }

    for (final entry in packages.entries) {
      final key = ['dependencies', entry.key];
      if (entry.value == null) {
        if (!exists(key)) {
          yaml.update(key, 'any');
        }
      } else if (entry.value == VersionConstraint.empty) {
        yaml.remove(key);
      } else {
        yaml.update(key, '${entry.value}');
      }
    }

    pubspecYamlFile.writeAsStringSync('$yaml');

    final stdoutBuffer = Uint8Buffer();
    final stderrBuffer = Uint8Buffer();
    final result = await runDartCommand(
      scope: scope,
      environment: environment,
      args: ['pub', 'get'],
      workingDirectory: bootstrapDir.path,
      onStdout: stdoutBuffer.addAll,
      onStderr: stderrBuffer.addAll,
    );
    if (result != 0 || !pubspecLockFile.existsSync()) {
      throw CommandError(
        'pub get failed in `${bootstrapDir.path}`\n'
        '${utf8.decode(stdoutBuffer)}${utf8.decode(stderrBuffer)}',
      );
    }

    return true;
  });
}
