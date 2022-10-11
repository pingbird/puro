import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:path/path.dart' as path;
import 'package:typed_data/typed_buffers.dart';

import 'logger.dart';
import 'provider.dart';

Future<Process> startProcess(
  Scope scope,
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
  ProcessStartMode mode = ProcessStartMode.normal,
}) async {
  final start = clock.now();
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    mode: mode,
  );
  process.exitCode.then((exitCode) {
    final log = PuroLogger.of(scope);
    final executableName = path.basename(executable);
    log.d(
      '$executableName finished in ${DateTime.now().difference(start).inMilliseconds}ms',
    );
  });
  return process;
}

Future<ProcessResult> runProcess(
  Scope scope,
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
  bool throwOnFailure = false,
}) async {
  final start = clock.now();
  final executableName = path.basename(executable);
  final log = PuroLogger.of(scope);
  log.v('${workingDirectory ?? ''}> ${[executable, ...arguments].join(' ')}');
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
  );
  log.d(
    '$executableName finished in ${DateTime.now().difference(start).inMilliseconds}ms',
  );
  final resultStdout = result.stdout as String;
  final resultStderr = result.stderr as String;
  if (result.exitCode != 0) {
    final message =
        '$executable subprocess failed with exit code ${result.exitCode}';
    if (throwOnFailure) {
      if (resultStdout.isNotEmpty) log.v('$executableName: $resultStdout');
      if (resultStderr.isNotEmpty) log.e('$executableName: $resultStderr');
      throw AssertionError(message);
    } else {
      if (resultStdout.isNotEmpty) log.v('$executableName: $resultStdout');
      if (resultStderr.isNotEmpty) log.v('$executableName: $resultStderr');
      log.v(message);
    }
  } else {
    if (resultStdout.isNotEmpty) log.d('$executableName: $resultStdout');
    if (resultStderr.isNotEmpty) log.v('$executableName: $resultStderr');
  }
  return result;
}

Future<ProcessResult?> runProcessWithTimeout(
  Scope scope,
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
  Encoding? stdoutEncoding = systemEncoding,
  Encoding? stderrEncoding = systemEncoding,
  required Duration timeout,
  ProcessSignal timeoutSignal = ProcessSignal.sigkill,
}) async {
  final process = await startProcess(
    scope,
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
  );

  final completer = Completer<ProcessResult?>();

  final stdout = Uint8Buffer();
  final stderr = Uint8Buffer();

  var stdoutDone = false;
  var stderrDone = false;
  int? exitCode;

  final timer = Timer(
    timeout,
    () {
      process.kill(timeoutSignal);
      completer.complete(null);
    },
  );

  void onDone() {
    if (!stdoutDone ||
        !stderrDone ||
        exitCode == null ||
        completer.isCompleted) {
      return;
    }
    timer.cancel();
    completer.complete(
      ProcessResult(
        process.pid,
        exitCode!,
        stdoutEncoding?.decode(stdout) ?? stdout,
        stderrEncoding?.decode(stderr) ?? stderr,
      ),
    );
  }

  process.stdout.listen(
    stdout.addAll,
    onDone: () {
      stdoutDone = true;
      onDone();
    },
  );

  process.stderr.listen(
    stderr.addAll,
    onDone: () {
      stderrDone = true;
      onDone();
    },
  );

  process.exitCode.then((value) {
    exitCode = value;
    onDone();
  });

  return completer.future;
}
