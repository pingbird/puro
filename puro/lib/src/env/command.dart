import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';

import '../config.dart';
import '../logger.dart';
import '../process.dart';
import '../provider.dart';
import '../terminal.dart';
import 'default.dart';
import 'engine.dart';
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
    'Setting up flutter tool took ${clock.now().difference(start).inMilliseconds}ms',
  );
  Terminal.of(scope).flushStatus();
  final dartPath = flutterConfig.cache.dartSdk.dartExecutable.path;
  final shouldPrecompile =
      !environmentPrefs.hasPrecompileTool() || environmentPrefs.precompileTool;
  final quirks = await getToolQuirks(scope: scope, environment: environment);

  // Translate `version` to `--version` since the version command was removed
  if (quirks.noVersionCommand) {
    final nonOptionArgs = args.where((e) => !e.startsWith('-')).toList();
    if (nonOptionArgs.firstOrNull == 'version') {
      args = args.toList();
      final index = args.indexWhere((e) => e == 'version');
      args[index] = '--version';
    }
  }

  final syncCache = !args.contains('--version');
  if (syncCache) {
    await trySyncFlutterCache(scope: scope, environment: environment);
  }
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
      'PUB_CACHE': config.legacyPubCacheDir.path,
    },
    workingDirectory: workingDirectory,
    mode: mode,
    rosettaWorkaround: true,
  );

  final disposeExitSignals = _setupExitSignals(mode);

  try {
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

    if (syncCache) {
      await trySyncFlutterCache(scope: scope, environment: environment);
    }
    return exitCode;
  } finally {
    await disposeExitSignals();
  }
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
      'PUB_CACHE': config.legacyPubCacheDir.path,
    },
    workingDirectory: workingDirectory,
    mode: mode,
    rosettaWorkaround: true,
  );

  final disposeExitSignals = _setupExitSignals(mode);

  try {
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
  } finally {
    await disposeExitSignals();
  }
}

/// Capture SIGINT and SIGTERM signals. If we don't capture them, the parent
/// process will exit, so the dart command won't have a chance to handle them.
/// Some CLI apps might want to behave differently when they receive these
/// signals.
Future<void> Function() _setupExitSignals(ProcessStartMode mode) {
  StreamSubscription<ProcessSignal>? sigIntSub, sigTermSub;

  if (mode == ProcessStartMode.inheritStdio) {
    sigIntSub = ProcessSignal.sigint.watch().listen((_) {});

    // SIGTERM is not supported on Windows. Attempting to register a SIGTERM
    // handler raises an exception.
    if (!Platform.isWindows) {
      sigTermSub = ProcessSignal.sigterm.watch().listen((_) {});
    }
  }

  // Cleanup function
  return () async {
    // cleanup signal subscriptions
    await sigIntSub?.cancel();
    await sigTermSub?.cancel();
  };
}
