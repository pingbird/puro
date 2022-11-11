import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';

import '../config.dart';
import '../logger.dart';
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
  final log = PuroLogger.of(scope);
  final start = clock.now();
  await setUpFlutterTool(
    scope: scope,
    environment: environment,
  );
  log.v(
    'Setting up flutter took ${clock.now().difference(start).inMilliseconds}ms',
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
  final log = PuroLogger.of(scope);
  final start = clock.now();
  await setUpFlutterTool(
    scope: scope,
    environment: environment,
  );
  log.v(
    'Setting up dart took ${clock.now().difference(start).inMilliseconds}ms',
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
