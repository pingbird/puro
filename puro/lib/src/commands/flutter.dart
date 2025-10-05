import 'dart:io';

import 'package:args/args.dart';

import '../command.dart';
import '../command_result.dart';
import '../env/command.dart';
import '../env/default.dart';
import '../logger.dart';
import '../terminal.dart';

class FlutterCommand extends PuroCommand {
  @override
  final name = 'flutter';

  @override
  final description =
      'Forwards arguments to flutter in the current environment';

  @override
  final argParser = ArgParser.allowAnything();

  @override
  String? get argumentUsage => '[...args]';

  @override
  Future<CommandResult> run() async {
    final log = PuroLogger.of(scope);
    final environment = await getProjectEnvOrDefault(scope: scope);
    log.v('Flutter SDK: ${environment.flutter.sdkDir.path}');
    final nonOptionArgs = argResults!.arguments
        .where((e) => !e.startsWith('-'))
        .toList();
    if (nonOptionArgs.isNotEmpty) {
      if (nonOptionArgs.first == 'upgrade') {
        runner.addMessage(
          'Using puro to upgrade flutter',
          type: CompletionType.info,
        );
        return (await runner.run(['upgrade', environment.name]))!;
      } else if (nonOptionArgs.first == 'channel' && nonOptionArgs.length > 1) {
        runner.addMessage(
          'Using puro to switch flutter channel',
          type: CompletionType.info,
        );
        return (await runner.run(['upgrade', unwrapArguments(exactly: 2)[1]]))!;
      }
    }
    final exitCode = await runFlutterCommand(
      scope: scope,
      environment: environment,
      args: argResults!.arguments,
      // inheritStdio is useful because it allows Flutter to detect the
      // terminal, otherwise it won't show any colors.
      mode: ProcessStartMode.inheritStdio,
    );
    exit(exitCode);
  }
}
