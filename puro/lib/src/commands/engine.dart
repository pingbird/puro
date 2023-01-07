import '../command.dart';
import '../command_result.dart';

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
  @override
  final name = 'prepare';

  @override
  final description = 'Prepares an environment for building the engine';

  @override
  String? get argumentUsage => '<env>';

  @override
  Future<CommandResult> run() async {
    return BasicMessageResult('Ready to build');
  }
}
