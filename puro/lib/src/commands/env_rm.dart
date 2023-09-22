import '../command.dart';
import '../command_result.dart';
import '../env/delete.dart';

class EnvRmCommand extends PuroCommand {
  EnvRmCommand() {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Delete the environment regardless of whether it is in use',
      negatable: false,
    );
  }

  @override
  final name = 'rm';

  @override
  final description = 'Deletes an environment';

  @override
  String? get argumentUsage => '<name>';

  @override
  Future<CommandResult> run() async {
    final name = unwrapSingleArgument();
    await deleteEnvironment(
      scope: scope,
      name: name,
      force: argResults!['force'] as bool,
    );
    return BasicMessageResult('Deleted environment `$name`');
  }
}
