import 'package:file/file.dart';

import '../command.dart';
import '../config.dart';
import '../proto/puro.pb.dart';
import '../provider.dart';

class ListEnvironmentResult extends CommandResult {
  ListEnvironmentResult({
    required this.environments,
    required this.selectedEnvironment,
  });

  final List<EnvConfig> environments;
  final String? selectedEnvironment;

  @override
  String? get description {
    if (environments.isEmpty) {
      return 'No environments, use `puro create` to create one';
    }
    return [
      'Environments:',
      ...environments.map(
        (e) => '  [${selectedEnvironment == e.name ? '*' : ' '}] ${e.name}',
      ),
      '',
      'Use `puro use <name>` to switch, or `puro create <name>` to create new environments',
    ].join('\n');
  }

  @override
  CommandResultModel toModel() {
    return CommandResultModel(
      success: true,
      environmentList: EnvironmentListModel(
        environments: [
          for (final environment in environments)
            EnvironmentSummaryModel(
              name: environment.name,
              path: environment.envDir.path,
            )
        ],
        selectedEnvironment: selectedEnvironment,
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
    selectedEnvironment: config.tryGetCurrentEnv()?.name,
  );
}
