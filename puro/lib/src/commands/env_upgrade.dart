import '../command.dart';
import '../config.dart';
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
      help: 'Forcefully upgrade the instance, erasing any unstaged changes',
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
    final envName = args[0];
    var version = args.length > 1 ? args[1] : null;

    final environment = config.getEnv(envName);
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
      throw ArgumentError('No version provided and no branch to upgrade from');
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
