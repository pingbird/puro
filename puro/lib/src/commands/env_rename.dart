import '../command.dart';
import '../command_result.dart';
import '../env/rename.dart';

class EnvRenameCommand extends PuroCommand {
  @override
  final name = 'rename';

  @override
  final description = 'Renames an environment';

  @override
  String? get argumentUsage => '<name> <new name>';

  @override
  Future<CommandResult> run() async {
    final args = unwrapArguments(exactly: 2);
    final name = args[0];
    final newName = args[1];
    await renameEnvironment(scope: scope, name: name, newName: newName);
    return BasicMessageResult('Renamed environment `$name` to `$newName`');
  }
}
