import '../command.dart';
import '../workspace/install.dart';

class EnvUseCommand extends PuroCommand {
  @override
  final name = 'use';

  @override
  final description = 'Select an environment to use in the current project.';

  @override
  String? get argumentUsage => '<name>';

  @override
  Future<CommandResult> run() async {
    final args = unwrapArguments(atMost: 1);
    final name = args.isEmpty ? null : args.first;
    await switchEnvironment(
      scope: scope,
      name: name,
    );
    return BasicMessageResult(
      success: true,
      message: 'Switched project to `$name`',
    );
  }
}
