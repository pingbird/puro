import 'dart:io';

import 'package:args/args.dart';
import 'package:puro/src/env/engine.dart';
import 'package:puro/src/process.dart';

import '../command.dart';
import '../config.dart';

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
    final environment = config.getCurrentEnv();
    final flutterConfig = environment.flutter;
    await setUpFlutterTool(
      scope: scope,
      environment: environment,
    );
    final flutterProcess = await startProcess(
      flutterConfig.cache.dartSdk.dartExecutable.path,
      [
        '--disable-dart-dev',
        '--packages=${flutterConfig.flutterToolsPackageConfigJsonFile.path}',
        if (environment.flutterToolArgs.isNotEmpty)
          ...environment.flutterToolArgs.split(RegExp(r'\S+')),
        flutterConfig.cache.flutterToolsSnapshotFile.path,
        ...argResults!.arguments,
      ],
    );
    final stdoutFuture = flutterProcess.stdout.listen(stdout.add).asFuture();
    final stderrFuture = flutterProcess.stderr.listen(stderr.add).asFuture();
    final exitCode = await flutterProcess.exitCode;
    await stdoutFuture;
    await stderrFuture;
    exit(exitCode);
  }
}
