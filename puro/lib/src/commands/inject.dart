import '../command.dart';
import '../command_result.dart';
import '../dart/packages.dart';
import '../env/default.dart';

class InjectCommand extends PuroCommand {
  @override
  final name = '_inject';

  @override
  bool get hidden => true;

  @override
  Future<CommandResult> run() async {
    final environment = await getProjectEnvOrDefault(scope: scope);
    final dartCommit = environment.flutter.cache.dartSdk.commitHash;
    await getDartSdkPackages(
      scope: scope,
      commit: dartCommit,
      packageName: 'kernel',
    );
    throw UnimplementedError();
  }
}
