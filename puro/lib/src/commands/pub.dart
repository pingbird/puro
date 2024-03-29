import 'dart:io';

import 'package:args/args.dart';

import '../command.dart';
import '../command_result.dart';
import '../env/command.dart';
import '../env/default.dart';

class PubCommand extends PuroCommand {
  @override
  final name = 'pub';

  @override
  final description = 'Forwards arguments to pub in the current environment';

  @override
  final argParser = ArgParser.allowAnything();

  @override
  String? get argumentUsage => '[...args]';

  @override
  Future<CommandResult> run() async {
    final environment = await getProjectEnvOrDefault(scope: scope);
    final exitCode = await runFlutterCommand(
      scope: scope,
      environment: environment,
      args: ['pub', ...argResults!.arguments],
      mode: ProcessStartMode.inheritStdio,
    );
    await runner.exitPuro(exitCode);
  }
}
