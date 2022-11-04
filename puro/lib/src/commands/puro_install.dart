import '../command.dart';
import '../version.dart';

class PuroInstallCommand extends PuroCommand {
  @override
  final name = 'install-puro';

  @override
  bool get hidden => true;

  @override
  final description = 'Finishes installation of the puro tool.';

  @override
  Future<CommandResult> run() async {
    final version = await getPuroVersion(scope: scope);
    return BasicMessageResult(
      success: true,
      message: 'Installed Puro $version',
    );
  }
}
