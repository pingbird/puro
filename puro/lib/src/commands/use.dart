import '../command.dart';
import '../env/install.dart';

class EnvUseCommand extends PuroCommand {
  @override
  final name = 'use';

  @override
  final description = 'Select an environment to use in the current project.';

  @override
  String? get argumentUsage => '<name>';

  @override
  Future<CommandResult> run() async {
    final name = unwrapSingleArgument();
    await useEnvironment(
      scope: scope,
      name: name,
    );
    return BasicMessageResult(
      success: true,
      message: 'Now using environment `$name` for the current project',
    );
  }
}
