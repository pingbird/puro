import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:clock/clock.dart';
import 'package:path/path.dart' as path;
import 'package:typed_data/typed_buffers.dart';

import 'config.dart';
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
  final log = PuroLogger.of(scope);
  log.d('${workingDirectory ?? ''}> ${[executable, ...arguments].join(' ')}');
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
  unawaited(process.exitCode.then((exitCode) {
    final log = PuroLogger.of(scope);
    final executableName = path.basename(executable);
    log.d(
      '$executableName finished with $exitCode in ${DateTime.now().difference(start).inMilliseconds}ms',
    );
  }));
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
  log.d('${workingDirectory ?? ''}> ${[executable, ...arguments].join(' ')}');
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

  unawaited(process.exitCode.then((value) {
    exitCode = value;
    onDone();
  }));

  return completer.future;
}

class PsInfo {
  PsInfo(this.id, this.name);

  final int id;
  final String name;

  Map<String, Object> toJson() => {'id': id, 'name': name};
}

Future<List<PsInfo>> getParentProcesses({
  required Scope scope,
}) async {
  final log = PuroLogger.of(scope);
  final stack = <PsInfo>[];
  if (Platform.isWindows) {
    final result = await runProcess(scope, 'powershell', [
      '-command',
      'Get-WmiObject -Query "select Name,ParentProcessId,ProcessId from Win32_Process" | ConvertTo-Json',
    ]);
    if (result.exitCode != 0 || (result.stdout as String).isEmpty) {
      if (result.stdout != '') log.w(result.stdout as String);
      if (result.stderr != '') log.w(result.stderr as String);
      log.w('Failed to query Get-WmiObject (exit code ${result.exitCode})');
    }
    List<dynamic> processInfo;
    try {
      processInfo = jsonDecode(result.stdout as String) as List<dynamic>;
    } catch (e, bt) {
      if (result.stdout != '') log.w(result.stdout as String);
      if (result.stderr != '') log.w(result.stderr as String);
      log.w('Error parsing Get-WmiObject\n$e\n$bt');
      return [];
    }
    final parentIds = <int, int>{};
    final names = <int, String>{};
    for (final process in processInfo.cast<Map<String, dynamic>>()) {
      final id = process['ProcessId'] as int?;
      if (id == null) continue;
      final ppid = process['ParentProcessId'] as int?;
      final name = process['Name'] as String?;
      if (ppid != null) parentIds[id] = ppid;
      if (name != null) names[id] = name;
    }
    var pid = io.pid;
    for (;;) {
      final ppid = parentIds[pid];
      final name = names[pid];
      if (ppid == null || name == null) break;
      stack.add(PsInfo(pid, name));
      pid = ppid;
    }
  } else {
    var pid = io.pid;
    for (;;) {
      final result = await runProcess(scope, 'ps', [
        '--no-headers',
        '-o',
        '%P\n%c',
        '-p',
        '$pid',
      ]);
      if (result.exitCode != 0) break;
      final lines = (result.stdout as String).trim().split('\n');
      if (lines.length != 2) break;
      final ppid = int.tryParse(lines[0].trim());
      final name = lines[1].trim();
      if (ppid == null || name.isEmpty) break;
      stack.add(PsInfo(pid, name));
      pid = ppid;
    }
  }
  if (log.shouldLog(LogLevel.debug)) log.d(prettyJsonEncoder.convert(stack));
  return stack;
}
