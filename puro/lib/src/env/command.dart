import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';

import '../config.dart';
import '../logger.dart';
import '../process.dart';
import '../provider.dart';
import '../terminal.dart';
import 'default.dart';
import 'flutter_tool.dart';

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
  final environmentPrefs = await environment.readPrefs(scope: scope);
  final toolInfo = await setUpFlutterTool(
    scope: scope,
    environment: environment,
    environmentPrefs: environmentPrefs,
  );
  log.v(
    'Setting up flutter took ${clock.now().difference(start).inMilliseconds}ms',
  );
  Terminal.of(scope).flushStatus();
  final dartPath = flutterConfig.cache.dartSdk.dartExecutable.path;
  final shouldPrecompile =
      !environmentPrefs.hasPrecompileTool() || environmentPrefs.precompileTool;
  final quirks = await getToolQuirks(scope: scope, environment: environment);
  final flutterProcess = await startProcess(
    scope,
    dartPath,
    [
      if (quirks.disableDartDev) '--disable-dart-dev',
      '--packages=${flutterConfig.flutterToolsPackageConfigJsonFile.path}',
      if (environment.flutterToolArgs.isNotEmpty)
        ...environment.flutterToolArgs.split(RegExp(r'\S+')),
      if (shouldPrecompile)
        toolInfo.snapshotFile!.path
      else
        flutterConfig.flutterToolsScriptFile.path,
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
  final environmentPrefs = await environment.readPrefs(scope: scope);
  await setUpFlutterTool(
    scope: scope,
    environment: environment,
    environmentPrefs: environmentPrefs,
  );
  log.v(
    'Setting up dart took ${clock.now().difference(start).inMilliseconds}ms',
  );
  final nonOptionArgs = args.where((e) => !e.startsWith('-')).toList();
  if (nonOptionArgs.length >= 2 &&
      nonOptionArgs[0] == 'pub' &&
      nonOptionArgs[1] == 'global') {
    final defaultEnvName = await getDefaultEnvName(scope: scope);
    if (environment.name != defaultEnvName) {
      log.w(
        'Warning: `pub global` should only be used with the default environment `$defaultEnvName`, '
        'your current environment is `${environment.name}`\n'
        'Due to a limitation in Dart, globally activated scripts can only use the default dart runtime',
      );
    }
  }
  Terminal.of(scope).flushStatus();
  final dartProcess = await startProcess(
    scope,
    flutterConfig.cache.dartSdk.dartExecutable.path,
    args,
    environment: {
      'FLUTTER_ROOT': flutterConfig.sdkDir.path,
      'PUB_CACHE': config.pubCacheDir.path,
    },
    workingDirectory: workingDirectory,
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
