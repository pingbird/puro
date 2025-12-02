import 'dart:io';

import '../command_result.dart';
import '../config.dart';
import '../file_lock.dart';
import '../provider.dart';
import 'create.dart';
import 'releases.dart';
import 'version.dart';

bool isPseudoEnvName(String name) {
  return pseudoEnvironmentNames.contains(name) || isValidVersion(name);
}

Future<EnvConfig> _getPseudoEnvironment({
  required Scope scope,
  required String envName,
}) async {
  final config = PuroConfig.of(scope);
  final environment = config.getEnv(envName);
  if (!environment.exists) {
    await createEnvironment(
      scope: scope,
      envName: environment.name,
      flutterVersion: await FlutterVersion.query(
        scope: scope,
        version: environment.name,
      ),
    );
  }
  return environment;
}

Future<EnvConfig> getProjectEnvOrDefault({
  required Scope scope,
  String? envName,
}) async {
  final config = PuroConfig.of(scope);
  if (envName != null) {
    final environment = config.getEnv(envName);
    if (!environment.exists) {
      if (isPseudoEnvName(environment.name)) {
        return _getPseudoEnvironment(scope: scope, envName: envName);
      }
      environment.ensureExists();
    }
    return environment;
  }
  var env = config.tryGetProjectEnv();
  if (env == null) {
    final override = config.environmentOverride;
    if (override != null) {
      if (isPseudoEnvName(override)) {
        return _getPseudoEnvironment(scope: scope, envName: override);
      }
      throw CommandError(
        'Selected environment `${config.environmentOverride}` does not exist',
      );
    }
    final envName = await getDefaultEnvName(scope: scope);
    if (isPseudoEnvName(envName)) {
      return _getPseudoEnvironment(scope: scope, envName: envName);
    }
    env = config.getEnv(envName);
    if (!env.exists) {
      throw CommandError(
        'No environment selected and default environment `$envName` does not exist',
      );
    }
  }
  return env;
}

Future<String> getDefaultEnvName({required Scope scope}) async {
  final prefs = await readGlobalPrefs(scope: scope);
  return prefs.hasDefaultEnvironment() ? prefs.defaultEnvironment : 'stable';
}

Future<void> setDefaultEnvName({
  required Scope scope,
  required String envName,
}) async {
  ensureValidEnvName(envName);
  await updateGlobalPrefs(
    scope: scope,
    fn: (prefs) {
      prefs.defaultEnvironment = envName;
    },
  );
  await updateDefaultEnvSymlink(scope: scope, name: envName);
}

Future<void> updateDefaultEnvSymlink({
  required Scope scope,
  String? name,
}) async {
  final config = PuroConfig.of(scope);
  name ??= await getDefaultEnvName(scope: scope);
  final environment = config.getEnv(name);
  final link = config.defaultEnvLink;

  if (environment.exists) {
    final path = environment.envDir.path;
    if (!FileSystemEntity.isLinkSync(link.path)) {
      if (link.existsSync()) {
        link.deleteSync();
      }
      link.parent.createSync(recursive: true);
      await createLink(scope: scope, link: link, path: path);
    } else if (link.targetSync() != path) {
      link.updateSync(path);
    }
  } else if (FileSystemEntity.isLinkSync(link.path)) {
    link.deleteSync();
  }
}
