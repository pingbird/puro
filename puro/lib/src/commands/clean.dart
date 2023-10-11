import '../command.dart';
import '../command_result.dart';
import '../config.dart';
import '../workspace/clean.dart';

class CleanCommand extends PuroCommand {
  @override
  final name = 'clean';

  @override
  final description =
      'Deletes Puro configuration files from the current project and restores IDE settings';

  @override
  bool get takesArguments => false;

  @override
  Future<CommandResult> run() async {
    final config = PuroConfig.of(scope);
    await cleanWorkspace(scope: scope, projectConfig: config.project);
    return BasicMessageResult('Removed puro from current project');
  }
}
