import '../config.dart';
import '../process.dart';
import '../provider.dart';
import 'engine.dart';

Future<int> runFlutterCommand({
  required Scope scope,
  required EnvConfig environment,
  required List<String> args,
  required void Function(List<int>) onStdout,
  required void Function(List<int>) onStderr,
  String? workingDirectory,
}) async {
  final flutterConfig = environment.flutter;
  await setUpFlutterTool(
    scope: scope,
    environment: environment,
  );
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
    },
    workingDirectory: workingDirectory,
  );
  final stdoutFuture = flutterProcess.stdout.listen(onStdout).asFuture<void>();
  final stderrFuture = flutterProcess.stderr.listen(onStderr).asFuture<void>();
  final exitCode = await flutterProcess.exitCode;
  await stdoutFuture;
  await stderrFuture;
  return exitCode;
}

Future<int> runDartCommand({
  required Scope scope,
  required EnvConfig environment,
  required List<String> args,
  required void Function(List<int>) onStdout,
  required void Function(List<int>) onStderr,
  String? workingDirectory,
}) async {
  final flutterConfig = environment.flutter;
  await setUpFlutterTool(
    scope: scope,
    environment: environment,
  );
  final dartProcess = await startProcess(
    scope,
    flutterConfig.cache.dartSdk.dartExecutable.path,
    args,
  );
  final stdoutFuture = dartProcess.stdout.listen(onStdout).asFuture<void>();
  final stderrFuture = dartProcess.stderr.listen(onStderr).asFuture<void>();
  final exitCode = await dartProcess.exitCode;
  await stdoutFuture;
  await stderrFuture;
  return exitCode;
}
