import 'dart:math';

import 'package:file/file.dart';
import 'package:neoansi/neoansi.dart';

import '../command_result.dart';
import '../config.dart';
import '../logger.dart';
import '../proto/puro.pb.dart';
import '../provider.dart';
import '../terminal.dart';
import 'default.dart';
import 'releases.dart';
import 'version.dart';

class EnvironmentInfoResult {
  EnvironmentInfoResult(
    this.environment,
    this.version,
    this.projects,
  );

  final EnvConfig environment;
  final FlutterVersion? version;
  final List<Directory> projects;

  EnvironmentInfoModel toModel() {
    return EnvironmentInfoModel(
      name: environment.name,
      path: environment.envDir.path,
      version: version?.toModel(),
      projects: projects.map((e) => e.path).toList(),
    );
  }
}

class ListEnvironmentResult extends CommandResult {
  ListEnvironmentResult({
    required this.config,
    required this.results,
    required this.projectEnvironment,
    required this.globalEnvironment,
    required this.showProjects,
  });

  final PuroConfig config;
  final List<EnvironmentInfoResult> results;
  final String? projectEnvironment;
  final String? globalEnvironment;
  final bool showProjects;

  @override
  bool get success => true;

  @override
  CommandMessage get message {
    return CommandMessage.format(
      (format) {
        if (results.isEmpty) {
          return 'No environments, use `puro create` to create one';
        }
        final lines = <List<String>>[];

        for (final result in results) {
          final name = result.environment.name;
          final resultLines = <String>[];
          if (name == projectEnvironment) {
            resultLines.add(
              format.color(
                '* $name',
                foregroundColor: Ansi8BitColor.green,
                bold: true,
              ),
            );
          } else if (name == globalEnvironment && projectEnvironment == null) {
            resultLines.add(
              format.color(
                '~ $name',
                foregroundColor: Ansi8BitColor.green,
                bold: true,
              ),
            );
          } else if (name == globalEnvironment) {
            resultLines.add('~ $name');
          } else {
            resultLines.add('  $name');
          }
          if (showProjects && result.projects.isNotEmpty) {
            for (final project in result.projects) {
              resultLines.add('    ${config.shortenHome(project.path)}');
            }
          }
          lines.add(resultLines);
        }

        final linePadding =
            lines.fold<int>(0, (v, e) => max(v, stripAnsiEscapes(e[0]).length));

        return [
          'Environments:',
          for (var i = 0; i < lines.length; i++) ...[
            padRightColored(lines[i][0], linePadding) +
                format.color(
                  ' (${results[i].environment.exists ? results[i].version ?? 'unknown' : 'not installed'})',
                  foregroundColor: Ansi8BitColor.grey,
                ),
            ...lines[i].skip(1),
          ],
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
      projectEnvironment: projectEnvironment,
      globalEnvironment: globalEnvironment,
    ),
  );
}

/// Lists all available environments
Future<ListEnvironmentResult> listEnvironments({
  required Scope scope,
  bool showProjects = false,
}) async {
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);
  final results = <EnvironmentInfoResult>[];
  final allDotfiles = await getAllDotfiles(scope: scope);

  log.d('listEnvironments');

  for (final name in pseudoEnvironmentNames) {
    final environment = config.getEnv(name);
    FlutterVersion? version;
    final projects =
        (allDotfiles[environment.name] ?? []).map((e) => e.parent).toList();
    if (environment.exists) {
      version = await getEnvironmentFlutterVersion(
        scope: scope,
        environment: environment,
      );
    }
    results.add(EnvironmentInfoResult(environment, version, projects));
  }

  if (config.envsDir.existsSync()) {
    for (final childEntity in config.envsDir.listSync()) {
      if (childEntity is! Directory ||
          !(isValidName(childEntity.basename) ||
              isValidVersion(childEntity.basename)) ||
          childEntity.basename == 'default') {
        continue;
      }
      final environment = config.getEnv(childEntity.basename);
      if (pseudoEnvironmentNames.contains(environment.name)) continue;
      final version = await getEnvironmentFlutterVersion(
        scope: scope,
        environment: environment,
      );
      results.add(EnvironmentInfoResult(environment, version, []));
    }
  }

  log.d('done listEnvironments');

  return ListEnvironmentResult(
    config: config,
    results: results,
    projectEnvironment: config.tryGetProjectEnv()?.name,
    globalEnvironment: await getDefaultEnvName(scope: scope),
    showProjects: showProjects,
  );
}
