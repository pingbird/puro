import 'dart:io';

import 'package:args/args.dart';

import '../command.dart';
import '../config.dart';
import '../env/engine.dart';
import '../logger.dart';
import '../process.dart';

class FlutterCommand extends PuroCommand {
  @override
  final name = 'flutter';

  @override
  final description =
      'Forwards arguments to flutter in the current environment.';

  @override
  final argParser = ArgParser.allowAnything();

  @override
  String? get argumentUsage => '[...args]';

  @override
  Future<CommandResult> run() async {
    final config = PuroConfig.of(scope);
    final log = PuroLogger.of(scope);
    final environment = config.getCurrentEnv();
    final flutterConfig = environment.flutter;
    await setUpFlutterTool(
      scope: scope,
      environment: environment,
    );
    final dartPath = flutterConfig.cache.dartSdk.dartExecutable.path;
    final snapshotPath = flutterConfig.cache.flutterToolsSnapshotFile.path;
    log.v('Root: ${flutterConfig.sdkDir.path}');
    final flutterProcess = await startProcess(
      scope,
      dartPath,
      [
        '--disable-dart-dev',
        '--packages=${flutterConfig.flutterToolsPackageConfigJsonFile.path}',
        if (environment.flutterToolArgs.isNotEmpty)
          ...environment.flutterToolArgs.split(RegExp(r'\S+')),
        snapshotPath,
        ...argResults!.arguments,
      ],
      environment: {
        'FLUTTER_ROOT': flutterConfig.sdkDir.path,
      },
    );
    final stdoutFuture =
        flutterProcess.stdout.listen(stdout.add).asFuture<void>();
    final stderrFuture =
        flutterProcess.stderr.listen(stderr.add).asFuture<void>();
    final exitCode = await flutterProcess.exitCode;
    await stdoutFuture;
    await stderrFuture;
    exit(exitCode);
  }
}
