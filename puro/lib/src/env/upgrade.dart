import '../command_result.dart';
import '../config.dart';
import '../git.dart';
import '../logger.dart';
import '../proto/puro.pb.dart';
import '../provider.dart';
import 'create.dart';
import 'env_shims.dart';
import 'flutter_tool.dart';
import 'version.dart';

class EnvUpgradeResult extends CommandResult {
  EnvUpgradeResult({
    required this.environment,
    required this.from,
    required this.to,
    required this.forkRemoteUrl,
    this.switchedBranch = false,
    required this.toolInfo,
  });

  final EnvConfig environment;
  final FlutterVersion from;
  final FlutterVersion to;
  final String? forkRemoteUrl;
  final bool switchedBranch;
  final FlutterToolInfo toolInfo;

  @override
  bool get success => true;

  bool get downgrade => from > to;

  @override
  CommandMessage get message => CommandMessage.format(
        (format) => from.commit == to.commit
            ? toolInfo.didUpdateTool || toolInfo.didUpdateEngine
                ? 'Finished installation of $to in environment `${environment.name}`'
                : 'Environment `${environment.name}` is already up to date'
            : '${downgrade ? 'Downgraded' : 'Upgraded'} environment `${environment.name}`\n'
                '${from.toString(format)} => ${to.toString(format)}',
      );

  @override
  late final model = CommandResultModel(
    success: true,
    environmentUpgrade: EnvironmentUpgradeModel(
      name: environment.name,
      from: from.toModel(),
      to: to.toModel(),
    ),
  );
}

/// Upgrades an environment to a different version of flutter.
Future<EnvUpgradeResult> upgradeEnvironment({
  required Scope scope,
  required EnvConfig environment,
  required FlutterVersion toVersion,
  bool force = false,
}) async {
  final log = PuroLogger.of(scope);
  final git = GitClient.of(scope);
  environment.ensureExists();

  log.v('Upgrading environment in ${environment.envDir.path}');

  final repository = environment.flutterDir;
  final currentCommit = await git.getCurrentCommitHash(repository: repository);

  final branch = await git.getBranch(repository: repository);
  var prefs = await environment.readPrefs(scope: scope);
  final fromVersion = prefs.hasDesiredVersion()
      ? FlutterVersion.fromModel(prefs.desiredVersion)
      : await getEnvironmentFlutterVersion(
          scope: scope,
          environment: environment,
        );

  if (fromVersion == null) {
    throw CommandError("Couldn't find Flutter version, corrupt environment?");
  }

  if (currentCommit != toVersion.commit ||
      (toVersion.branch != null && branch != toVersion.branch)) {
    prefs = await environment.updatePrefs(
      scope: scope,
      fn: (prefs) {
        prefs.desiredVersion = toVersion.toModel();
      },
    );

    if (prefs.hasForkRemoteUrl()) {
      if (branch == null) {
        throw CommandError(
          'HEAD is not attached to a branch, could not upgrade fork',
        );
      }
      if (await git.hasUncomittedChanges(repository: repository)) {
        throw CommandError(
          "Can't upgrade fork with uncomitted changes",
        );
      }
      await git.pull(
        repository: repository,
        all: true,
      );
      final switchBranch =
          toVersion.branch != null && branch != toVersion.branch;
      if (switchBranch) {
        await git.checkout(repository: repository, ref: toVersion.branch!);
      }
      await git.merge(
        repository: repository,
        fromCommit: toVersion.commit,
        fastForwardOnly: true,
      );

      final toolInfo = await setUpFlutterTool(
        scope: scope,
        environment: environment,
      );

      return EnvUpgradeResult(
        environment: environment,
        from: fromVersion,
        to: toVersion,
        forkRemoteUrl: prefs.forkRemoteUrl,
        switchedBranch: switchBranch,
        toolInfo: toolInfo,
      );
    }

    await cloneFlutterWithSharedRefs(
      scope: scope,
      repository: environment.flutterDir,
      flutterVersion: toVersion,
      environment: environment,
      forkRemoteUrl: prefs.hasForkRemoteUrl() ? prefs.forkRemoteUrl : null,
      force: force,
    );
  }

  // Replace flutter/dart with shims
  await installEnvShims(
    scope: scope,
    environment: environment,
  );

  final toolInfo = await setUpFlutterTool(
    scope: scope,
    environment: environment,
  );

  if (environment.flutter.legacyVersionFile.existsSync()) {
    environment.flutter.legacyVersionFile.deleteSync();
  }

  return EnvUpgradeResult(
    environment: environment,
    from: fromVersion,
    to: toVersion,
    forkRemoteUrl: null,
    toolInfo: toolInfo,
  );
}
