import '../command.dart';
import '../env/list.dart';

class EnvLsCommand extends PuroCommand {
  EnvLsCommand() {
    argParser.addFlag(
      'projects',
      abbr: 'p',
      help: 'Whether to show projects using each environment',
      negatable: false,
    );
    argParser.addFlag(
      'dart',
      abbr: 'd',
      help: 'Whether to show the dart version of flutter environments',
      negatable: false,
    );
  }

  @override
  final name = 'ls';

  @override
  final description =
      'Lists available environments\nHighlights the current environment with a * and the global environment with a ~';

  @override
  Future<ListEnvironmentResult> run() async {
    return listEnvironments(
      scope: scope,
      showProjects: argResults!['projects'] as bool,
      showDartVersion: argResults!['dart'] as bool,
    );
  }
}
