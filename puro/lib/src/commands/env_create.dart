import '../command.dart';
import '../command_result.dart';
import '../config.dart';
import '../env/create.dart';
import '../env/default.dart';
import '../env/releases.dart';
import '../env/version.dart';
import '../install/bin.dart';

class EnvCreateCommand extends PuroCommand {
  EnvCreateCommand() {
    argParser.addOption(
      'channel',
      help:
          'The Flutter channel, in case multiple channels have builds with the same version number.',
      valueHelp: 'name',
    );
    argParser.addOption(
      'fork',
      help:
          'The origin to use when cloning the framework, puro will set the upstream automatically.',
      valueHelp: 'url',
    );
  }

  @override
  final name = 'create';

  @override
  String? get argumentUsage => '<name> [version]';

  @override
  final description = 'Sets up a new Flutter environment';

  @override
  Future<EnvCreateResult> run() async {
    final channel = argResults!['channel'] as String?;
    final fork = argResults!['fork'] as String?;
    final args = unwrapArguments(atLeast: 1, atMost: 2);
    final version = args.length > 1 ? args[1] : null;
    final envName = args.first.toLowerCase();
    ensureValidEnvName(envName);

    await ensurePuroInstalled(scope: scope);

    if (fork != null) {
      if (pseudoEnvironmentNames.contains(envName) || isValidVersion(envName)) {
        throw CommandError(
          'Cannot create fixed version `$envName` with a fork',
        );
      }
      return createEnvironment(
        scope: scope,
        envName: envName,
        forkRemoteUrl: fork,
        forkRef: version,
      );
    } else {
      return createEnvironment(
        scope: scope,
        envName: envName,
        flutterVersion: await FlutterVersion.query(
          scope: scope,
          version: version,
          channel: channel,
          defaultVersion: isPseudoEnvName(envName) ? envName : 'stable',
        ),
      );
    }
  }
}
