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
    this.dartVersion,
    this.projects,
    this.showDartVersion,
  );

  final EnvConfig environment;
  final FlutterVersion? version;
  final String? dartVersion;
  final List<Directory> projects;
  final bool showDartVersion;

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
    return CommandMessage.format((format) {
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
            resultLines.add('  | ${config.shortenHome(project.path)}');
          }
        }
        lines.add(resultLines);
      }

      final linePadding = lines.fold<int>(
        0,
        (v, e) => max(v, stripAnsiEscapes(e[0]).length),
      );

      return [
        'Environments:',
        for (var i = 0; i < lines.length; i++) ...[
          padRightColored(lines[i][0], linePadding) +
              format.color(
                ' (${[if (results[i].environment.exists) results[i].version ?? 'unknown' else 'not installed', if (results[i].dartVersion != null && results[i].showDartVersion) 'Dart ${results[i].dartVersion}'].join(' / ')})',
                foregroundColor: Ansi8BitColor.grey,
              ),
          ...lines[i].skip(1),
        ],
        '',
        'Use `puro create <name>` to create an environment, or `puro use <name>` to switch',
      ].join('\n');
    }, type: CompletionType.info);
  }

  @override
  late final model = CommandResultModel(
    environmentList: EnvironmentListModel(
      environments: [for (final info in results) info.toModel()],
      projectEnvironment: projectEnvironment,
      globalEnvironment: globalEnvironment,
    ),
  );
}

/// Lists all available environments
Future<ListEnvironmentResult> listEnvironments({
  required Scope scope,
  bool showProjects = false,
  bool showDartVersion = false,
}) async {
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);
  final results = <EnvironmentInfoResult>[];
  final allDotfiles = await getAllDotfiles(scope: scope);

  log.d('listEnvironments');

  for (final name in pseudoEnvironmentNames) {
    final environment = config.getEnv(name);
    FlutterVersion? version;
    String? dartVersion;
    if (environment.exists) {
      version = await getEnvironmentFlutterVersion(
        scope: scope,
        environment: environment,
      );
      final dartVersionFile = environment.flutter.cache.dartSdk.versionFile;
      dartVersion = dartVersionFile.existsSync()
          ? dartVersionFile.readAsStringSync().trim()
          : null;
    }
    final projects = (allDotfiles[environment.name] ?? [])
        .map((e) => e.parent)
        .toList();
    results.add(
      EnvironmentInfoResult(
        environment,
        version,
        dartVersion,
        projects,
        showDartVersion,
      ),
    );
  }

  if (config.envsDir.existsSync()) {
    for (final childEntity in config.envsDir.listSync()) {
      if (childEntity is! Directory ||
          !isValidEnvName(childEntity.basename) ||
          childEntity.basename == 'default') {
        continue;
      }
      final environment = config.getEnv(childEntity.basename);
      if (pseudoEnvironmentNames.contains(environment.name)) continue;
      final version = await getEnvironmentFlutterVersion(
        scope: scope,
        environment: environment,
      );
      final dartVersionFile = environment.flutter.cache.dartSdk.versionFile;
      final dartVersion = dartVersionFile.existsSync()
          ? dartVersionFile.readAsStringSync().trim()
          : null;
      final projects = (allDotfiles[environment.name] ?? [])
          .map((e) => e.parent)
          .toList();
      results.add(
        EnvironmentInfoResult(
          environment,
          version,
          dartVersion,
          projects,
          showDartVersion,
        ),
      );
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
