import '../command.dart';
import '../command_result.dart';
import '../engine/build_env.dart';
import '../engine/prepare.dart';

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
    final command = unwrapArguments();

    await prepareEngineSystemDeps(scope: scope);

    final exitCode = await runBuildEnvShell(
      scope: scope,
      command: command,
    );

    await runner.exitPuro(exitCode);
  }
}
