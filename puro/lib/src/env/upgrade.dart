import '../command.dart';
import '../config.dart';
import '../git.dart';
import '../logger.dart';
import '../proto/puro.pb.dart';
import '../provider.dart';
import 'create.dart';
import 'engine.dart';
import 'env_shims.dart';
import 'version.dart';

class EnvUpgradeResult extends CommandResult {
  EnvUpgradeResult({
    required this.environment,
    required this.from,
    required this.to,
    required this.forkRemoteUrl,
    this.switchedBranch = false,
  });

  final EnvConfig environment;
  final FlutterVersion from;
  final FlutterVersion to;
  final String? forkRemoteUrl;
  final bool switchedBranch;

  @override
  bool get success => true;

  @override
  CommandMessage get message => CommandMessage(
        (format) => from.commit == to.commit
            ? 'Environment `${environment.name}` is already up to date'
            : 'Upgraded `${environment.name}` from $from to $to',
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
  final fromVersion = await getEnvironmentFlutterVersion(
    scope: scope,
    environment: environment,
  );

  if (fromVersion == null) {
    throw ArgumentError("Couldn't find Flutter version, corrupt environment?");
  }

  if (currentCommit != toVersion.commit ||
      (toVersion.branch != null && branch != toVersion.branch)) {
    final prefs = await environment.updatePrefs(
      scope: scope,
      fn: (prefs) {
        prefs.desiredVersion = toVersion.toModel();
      },
    );

    if (prefs.hasForkRemoteUrl()) {
      if (branch == null) {
        throw ArgumentError(
          'HEAD is not attached to a branch, could not upgrade fork',
        );
      }
      if (await git.hasUncomittedChanges(repository: repository)) {
        throw ArgumentError(
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

      await setUpFlutterTool(
        scope: scope,
        environment: environment,
      );

      return EnvUpgradeResult(
        environment: environment,
        from: fromVersion,
        to: toVersion,
        forkRemoteUrl: prefs.forkRemoteUrl,
        switchedBranch: switchBranch,
      );
    }

    await cloneFlutterWithSharedRefs(
      scope: scope,
      repository: environment.flutterDir,
      flutterVersion: toVersion,
      forkRemoteUrl: prefs.hasForkRemoteUrl() ? prefs.forkRemoteUrl : null,
      force: force,
    );

    // Replace flutter/dart with shims
    await installEnvShims(
      scope: scope,
      environment: environment,
    );

    await setUpFlutterTool(
      scope: scope,
      environment: environment,
    );
  }

  return EnvUpgradeResult(
    environment: environment,
    from: fromVersion,
    to: toVersion,
    forkRemoteUrl: null,
  );
}
