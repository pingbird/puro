import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:puro/src/logger.dart';
import 'package:typed_data/typed_buffers.dart';

import 'provider.dart';

Future<Process> startProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
  ProcessStartMode mode = ProcessStartMode.normal,
}) {
  return Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    mode: mode,
  );
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
  final resultStdout = result.stdout as String;
  final resultStderr = result.stderr as String;
  if (result.exitCode != 0) {
    final message =
        '$executable subprocess failed with exit code ${result.exitCode}';
    if (throwOnFailure) {
      if (resultStdout.isNotEmpty) log.v('$executable: $resultStdout');
      if (resultStderr.isNotEmpty) log.e('$executable: $resultStderr');
      throw AssertionError(message);
    } else {
      if (resultStdout.isNotEmpty) log.v('$executable: $resultStdout');
      if (resultStderr.isNotEmpty) log.v('$executable: $resultStderr');
      log.v(message);
    }
  } else {
    if (resultStdout.isNotEmpty) log.d('$executable: $resultStdout');
    if (resultStderr.isNotEmpty) log.v('$executable: $resultStderr');
  }
  return result;
}

Future<ProcessResult?> runProcessWithTimeout(
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
