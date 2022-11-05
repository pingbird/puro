import '../command.dart';
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
    return BasicMessageResult(
      success: true,
      message: 'Cleaned up current project',
    );
  }
}
