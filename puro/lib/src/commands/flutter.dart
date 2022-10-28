import 'dart:io';

import 'package:args/args.dart';

import '../command.dart';
import '../env/command.dart';
import '../env/default.dart';
import '../logger.dart';

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
    final log = PuroLogger.of(scope);
    final environment = await getProjectEnvOrDefault(scope: scope);
    log.v('Flutter SDK: ${environment.flutter.sdkDir.path}');
    final exitCode = await runFlutterCommand(
      scope: scope,
      environment: environment,
      args: argResults!.arguments,
      onStdout: stdout.add,
      onStderr: stderr.add,
    );
    exit(exitCode);
  }
}
