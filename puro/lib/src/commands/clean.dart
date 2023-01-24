import '../command.dart';
import '../command_result.dart';
import '../workspace/clean.dart';

class CleanCommand extends PuroCommand {
  @override
  final name = 'clean';

  @override
  final description =
      'Deletes puro configuration files from the current project and restores IDE settings';

  @override
  bool get takesArguments => false;

  @override
  Future<CommandResult> run() async {
    await cleanWorkspace(scope: scope);
    return BasicMessageResult('Removed puro from current project');
  }
}
