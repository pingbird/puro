import '../command.dart';
import '../workspace/install.dart';

class EnvUseCommand extends PuroCommand {
  EnvUseCommand() {
    argParser.addFlag(
      'vscode',
      help: 'Enable or disable generation of VSCode configs',
    );
    argParser.addFlag(
      'intellij',
      help:
          'Enable or disable generation of IntelliJ (and Android Studio) configs',
    );
  }

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
      vscode: argResults!.wasParsed('vscode')
          ? argResults!['vscode'] as bool
          : null,
      intellij: argResults!.wasParsed('intellij')
          ? argResults!['intellij'] as bool
          : null,
    );
    return BasicMessageResult(
      success: true,
      message: 'Switched to environment `$name`',
    );
  }
}
