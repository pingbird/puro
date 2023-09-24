import '../command.dart';
import '../env/list.dart';

class EnvLsCommand extends PuroCommand {
  @override
  final name = 'ls';

  @override
  final description =
      'Lists available environments\nHighlights the current environment with a * and the global environment with a ~';

  @override
  Future<ListEnvironmentResult> run() async {
    return listEnvironments(scope: scope);
  }
}
