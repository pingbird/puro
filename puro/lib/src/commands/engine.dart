import '../command.dart';
import '../command_result.dart';
import '../config.dart';
import '../engine/prepare.dart';

class EngineCommand extends PuroCommand {
  EngineCommand() {
    addSubcommand(EnginePrepareCommand());
  }

  @override
  final name = 'engine';

  @override
  final description = 'Manages Flutter engine builds';

  @override
  bool get hidden => true;
}

class EnginePrepareCommand extends PuroCommand {
  EnginePrepareCommand() {
    argParser.addOption(
      'fork',
      help:
          'The origin to use when cloning the engine, puro will set the upstream automatically.',
      valueHelp: 'url',
    );
    argParser.addFlag(
      'force',
      help: 'Forcefully upgrade the engine, erasing any unstaged changes',
      negatable: false,
    );
  }

  @override
  final name = 'prepare';

  @override
  final description = 'Prepares an environment for building the engine';

  @override
  String? get argumentUsage => '<env> [ref]';

  @override
  Future<CommandResult> run() async {
    final force = argResults!['force'] as bool;
    final fork = argResults!['fork'] as String?;
    final args = unwrapArguments(atLeast: 1, atMost: 2);
    final envName = args.first;
    final ref = args.length > 1 ? args[1] : null;

    final config = PuroConfig.of(scope);
    final env = config.getEnv(envName);
    env.ensureExists();
    if (ref != null && ref != env.flutter.engineVersion) {
      runner.addMessage(
          'Preparing a different version of the engine than what this environment expects, '
          '');
    }
    await prepareEngine(
      scope: scope,
      environment: env,
      ref: ref,
      forkRemoteUrl: fork,
      force: force,
    );
    return BasicMessageResult(
      'Engine at `${env.engine.engineSrcDir.path}` ready to build',
    );
  }
}
