import '../command.dart';
import '../command_result.dart';
import '../engine/build_env.dart';

class BuildShellCommand extends PuroCommand {
  @override
  final name = 'build-shell';

  @override
  List<String> get aliases => ['build-env', 'buildenv'];

  @override
  final description =
      'Starts a shell with the proper environment variables for building the engine';

  @override
  String? get argumentUsage => '[...command]';

  @override
  Future<CommandResult> run() async {
    final command = unwrapArguments(startingAt: 0);

    final exitCode = await runBuildEnvShell(
      scope: scope,
      command: command,
    );

    await runner.exitPuro(exitCode);
  }
}
