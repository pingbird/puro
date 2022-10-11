import 'package:file/file.dart';
import 'package:puro/src/command.dart';
import 'package:puro/src/proto/puro.pb.dart';

import '../config.dart';
import '../provider.dart';

class ListEnvironmentResult extends CommandResult {
  ListEnvironmentResult({
    required this.environments,
  });

  final List<EnvConfig> environments;

  @override
  String? get description {
    if (environments.isEmpty) {
      return 'No environments, use `puro env create` to create one';
    }
    return [
      'Environments:',
      ...environments.map((e) => '[ ] ${e.name}'),
    ].join('\n');
  }

  @override
  CommandResultModel toModel() {
    return CommandResultModel(
      environmentList: EnvironmentListModel(
        environments: [
          for (final environment in environments)
            EnvironmentSummaryModel(
              name: environment.name,
              path: environment.envDir.path,
            )
        ],
      ),
    );
  }
}

/// Lists all available environments
Future<ListEnvironmentResult> listEnvironments({
  required Scope scope,
}) async {
  final config = PuroConfig.of(scope);
  return ListEnvironmentResult(
    environments: [
      for (final childEntity in config.envsDir.listSync())
        if (childEntity is Directory && isValidName(childEntity.basename))
          config.getEnv(childEntity.basename),
    ],
  );
}
