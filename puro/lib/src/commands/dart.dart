import 'dart:io';

import 'package:args/args.dart';

import '../command.dart';
import '../env/command.dart';
import '../env/default.dart';

class DartCommand extends PuroCommand {
  @override
  final name = 'dart';

  @override
  final description = 'Forwards arguments to dart in the current environment.';

  @override
  final argParser = ArgParser.allowAnything();

  @override
  String? get argumentUsage => '[...args]';

  @override
  Future<CommandResult> run() async {
    final environment = await getProjectEnvOrDefault(scope: scope);
    final exitCode = await runDartCommand(
      scope: scope,
      environment: environment,
      args: argResults!.arguments,
      onStdout: stdout.add,
      onStderr: stderr.add,
    );
    exit(exitCode);
  }
}
