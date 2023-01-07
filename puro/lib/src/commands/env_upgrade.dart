import '../command.dart';
import '../command_result.dart';
import '../config.dart';
import '../env/releases.dart';
import '../env/upgrade.dart';
import '../env/version.dart';

class EnvUpgradeCommand extends PuroCommand {
  EnvUpgradeCommand() {
    argParser.addOption(
      'channel',
      help:
          'The Flutter channel, in case multiple channels have builds with the same version number.',
      valueHelp: 'name',
    );
    argParser.addFlag(
      'force',
      help: 'Forcefully upgrade the framework, erasing any unstaged changes',
      negatable: false,
    );
  }

  @override
  final name = 'upgrade';

  @override
  String? get argumentUsage => '<name> [version]';

  @override
  final description = 'Upgrades an environment to a new version of Flutter';

  @override
  Future<EnvUpgradeResult> run() async {
    final config = PuroConfig.of(scope);
    final channel = argResults!['channel'] as String?;
    final force = argResults!['force'] as bool;
    final args = unwrapArguments(atLeast: 1, atMost: 2);
    var version = args.length > 1 ? args[1] : null;

    final environment = config.getEnv(args[0]);
    environment.ensureExists();

    if (version == null && channel == null) {
      final prefs = await environment.readPrefs(scope: scope);
      if (prefs.hasDesiredVersion()) {
        final versionModel = prefs.desiredVersion;
        if (versionModel.hasBranch()) {
          version = prefs.desiredVersion.branch;
        }
      }
    }

    if (version == null && channel == null) {
      if (pseudoEnvironmentNames.contains(environment.name)) {
        version = environment.name;
      } else {
        throw CommandError(
          'No version provided and environment `${environment.name}` is not on a branch',
        );
      }
    }

    return upgradeEnvironment(
      scope: scope,
      environment: environment,
      toVersion: await FlutterVersion.query(
        scope: scope,
        version: version,
        channel: channel,
      ),
      force: force,
    );
  }
}
