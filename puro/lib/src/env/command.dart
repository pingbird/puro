import 'dart:async';
import 'dart:io';

import '../config.dart';
import '../process.dart';
import '../provider.dart';
import '../terminal.dart';
import 'engine.dart';

Future<int> runFlutterCommand({
  required Scope scope,
  required EnvConfig environment,
  required List<String> args,
  Stream<List<int>>? stdin,
  void Function(List<int>)? onStdout,
  void Function(List<int>)? onStderr,
  String? workingDirectory,
  ProcessStartMode mode = ProcessStartMode.normal,
}) async {
  final config = PuroConfig.of(scope);
  final flutterConfig = environment.flutter;
  await setUpFlutterTool(
    scope: scope,
    environment: environment,
  );
  Terminal.of(scope).flushStatus();
  final dartPath = flutterConfig.cache.dartSdk.dartExecutable.path;
  final snapshotPath = flutterConfig.cache.flutterToolsSnapshotFile.path;
  final flutterProcess = await startProcess(
    scope,
    dartPath,
    [
      '--disable-dart-dev',
      '--packages=${flutterConfig.flutterToolsPackageConfigJsonFile.path}',
      if (environment.flutterToolArgs.isNotEmpty)
        ...environment.flutterToolArgs.split(RegExp(r'\S+')),
      snapshotPath,
      ...args,
    ],
    environment: {
      'FLUTTER_ROOT': flutterConfig.sdkDir.path,
      'PUB_CACHE': config.pubCacheDir.path,
    },
    workingDirectory: workingDirectory,
    mode: mode,
  );
  if (stdin != null) {
    unawaited(flutterProcess.stdin.addStream(stdin));
  }
  final stdoutFuture = onStdout == null
      ? null
      : flutterProcess.stdout.listen(onStdout).asFuture<void>();
  final stderrFuture = onStderr == null
      ? null
      : flutterProcess.stderr.listen(onStderr).asFuture<void>();
  final exitCode = await flutterProcess.exitCode;
  await stdoutFuture;
  await stderrFuture;
  return exitCode;
}

Future<int> runDartCommand({
  required Scope scope,
  required EnvConfig environment,
  required List<String> args,
  Stream<List<int>>? stdin,
  void Function(List<int>)? onStdout,
  void Function(List<int>)? onStderr,
  String? workingDirectory,
  ProcessStartMode mode = ProcessStartMode.normal,
}) async {
  final config = PuroConfig.of(scope);
  final flutterConfig = environment.flutter;
  await setUpFlutterTool(
    scope: scope,
    environment: environment,
  );
  Terminal.of(scope).flushStatus();
  final dartProcess = await startProcess(
    scope,
    flutterConfig.cache.dartSdk.dartExecutable.path,
    args,
    environment: {
      'PUB_CACHE': config.pubCacheDir.path,
    },
    mode: mode,
  );
  if (stdin != null) {
    unawaited(dartProcess.stdin.addStream(stdin));
  }
  final stdoutFuture = onStdout == null
      ? null
      : dartProcess.stdout.listen(onStdout).asFuture<void>();
  final stderrFuture = onStderr == null
      ? null
      : dartProcess.stderr.listen(onStderr).asFuture<void>();
  final exitCode = await dartProcess.exitCode;
  await stdoutFuture;
  await stderrFuture;
  return exitCode;
}
