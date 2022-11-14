import 'dart:math';

import 'package:file/file.dart';
import 'package:neoansi/neoansi.dart';

import '../command_result.dart';
import '../config.dart';
import '../proto/puro.pb.dart';
import '../provider.dart';
import '../terminal.dart';
import 'default.dart';
import 'version.dart';

class EnvironmentInfoResult {
  EnvironmentInfoResult(this.environment, this.version);

  final EnvConfig environment;
  final FlutterVersion? version;

  EnvironmentInfoModel toModel() {
    return EnvironmentInfoModel(
      name: environment.name,
      path: environment.envDir.path,
      version: version?.toModel(),
    );
  }
}

class ListEnvironmentResult extends CommandResult {
  ListEnvironmentResult({
    required this.results,
    required this.selectedEnvironment,
  });

  final List<EnvironmentInfoResult> results;
  final String? selectedEnvironment;

  @override
  bool get success => true;

  @override
  CommandMessage get message {
    return CommandMessage(
      (format) {
        if (results.isEmpty) {
          return 'No environments, use `puro create` to create one';
        }
        final lines = <String>[];

        for (final result in results) {
          final name = result.environment.name;
          if (name == selectedEnvironment) {
            lines.add(
              format.color(
                '* $name',
                foregroundColor: Ansi8BitColor.green,
                bold: true,
              ),
            );
          } else {
            lines.add('  $name');
          }
        }

        final linePadding =
            lines.fold<int>(0, (v, e) => max(v, stripAnsiEscapes(e).length));

        return [
          'Environments:',
          for (var i = 0; i < lines.length; i++)
            lines[i].padRight(linePadding) +
                format.color(
                  ' (${results[i].version ?? 'unknown'})',
                  foregroundColor: Ansi8BitColor.grey,
                ),
          '',
          'Use `puro create <name>` to create an environment, or `puro use <name>` to switch',
        ].join('\n');
      },
      type: CompletionType.info,
    );
  }

  @override
  late final model = CommandResultModel(
    environmentList: EnvironmentListModel(
      environments: [
        for (final info in results) info.toModel(),
      ],
      selectedEnvironment: selectedEnvironment,
    ),
  );
}

/// Lists all available environments
Future<ListEnvironmentResult> listEnvironments({
  required Scope scope,
}) async {
  final config = PuroConfig.of(scope);
  final results = <EnvironmentInfoResult>[];

  if (config.envsDir.existsSync()) {
    for (final childEntity in config.envsDir.listSync()) {
      if (childEntity is! Directory || !isValidName(childEntity.basename)) {
        continue;
      }
      final environment = config.getEnv(childEntity.basename);
      final version = await getEnvironmentFlutterVersion(
        scope: scope,
        environment: environment,
      );
      results.add(EnvironmentInfoResult(environment, version));
    }
  }
  return ListEnvironmentResult(
    results: results,
    selectedEnvironment: config.tryGetProjectEnv()?.name ??
        await getDefaultEnvName(scope: scope),
  );
}
