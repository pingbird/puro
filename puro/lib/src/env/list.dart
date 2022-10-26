import 'package:file/file.dart';
import 'package:neoansi/neoansi.dart';

import '../command.dart';
import '../config.dart';
import '../proto/puro.pb.dart';
import '../provider.dart';
import '../terminal.dart';

class ListEnvironmentResult extends CommandResult {
  ListEnvironmentResult({
    required this.environments,
    required this.selectedEnvironment,
  });

  final List<EnvConfig> environments;
  final String? selectedEnvironment;

  @override
  CompletionType? get type => CompletionType.info;

  @override
  String description(OutputFormatter format) {
    if (environments.isEmpty) {
      return 'No environments, use `puro create` to create one';
    }
    return [
      'Environments:',
      ...environments.map(
        (e) {
          if (e.name == selectedEnvironment) {
            return format.color(
                  '* ',
                  foregroundColor: Ansi8BitColor.green,
                  bold: true,
                ) +
                format.color(e.name, bold: true);
          } else {
            return '  ${e.name}';
          }
        },
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
      if (config.envsDir.existsSync())
        for (final childEntity in config.envsDir.listSync())
          if (childEntity is Directory && isValidName(childEntity.basename))
            config.getEnv(childEntity.basename),
    ],
    selectedEnvironment: config.tryGetProjectEnv()?.name,
  );
}
