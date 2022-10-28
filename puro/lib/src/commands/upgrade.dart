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
  }

  @override
  final name = 'upgrade';

  @override
  String? get argumentUsage => '<name> <version>';

  @override
  final description = 'Upgrades an environment to a new version of Flutter.\n';

  @override
  Future<EnvUpgradeResult> run() async {
    final config = PuroConfig.of(scope);
    final channel = argResults!['channel'] as String?;
    final args = unwrapArguments(exactly: 2);
    final envName = args[0];
    final version = args[1];

    return upgradeEnvironment(
      scope: scope,
      environment: config.getEnv(envName),
      flutterVersion: await FlutterVersion.query(
        scope: scope,
        version: version,
        channel: channel,
      ),
    );
  }
}
