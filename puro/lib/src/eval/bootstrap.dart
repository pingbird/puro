import 'dart:convert';

import 'package:typed_data/typed_buffers.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../command_result.dart';
import '../config.dart';
import '../env/command.dart';
import '../file_lock.dart';
import '../provider.dart';

Future<void> initEvalBootstrapProject({
  required Scope scope,
  required EnvConfig environment,
  required String sdkVersion,
}) async {
  final bootstrapDir = environment.evalBootstrapDir;
  final pubspecLockFile = bootstrapDir.childFile('pubspec.lock');
  final pubspecYamlFile = bootstrapDir.childFile('pubspec.yaml');
  bootstrapDir.createSync();
  if (pubspecLockFile.existsSync() &&
      pubspecLockFile
          .lastModifiedSync()
          .isAfter(pubspecYamlFile.lastModifiedSync())) {
    return;
  }
  final yaml = YamlEditor('')
    ..update(
      [],
      wrapAsYamlNode({
        'name': 'bootstrap',
        'version': '0.0.1',
        'environment': {
          'sdk': sdkVersion,
        },
      }),
    );
  await writePassiveAtomic(
    scope: scope,
    file: pubspecYamlFile,
    content: '$yaml',
  );
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
}
