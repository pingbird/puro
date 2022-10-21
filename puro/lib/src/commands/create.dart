import '../command.dart';
import '../env/create.dart';

class EnvCreateCommand extends PuroCommand {
  EnvCreateCommand() {
    argParser.addOption(
      'channel',
      help:
          'The Flutter channel, in case multiple channels have builds with the same version number.',
    );
  }

  @override
  final name = 'create';

  @override
  String? get argumentUsage => '<name> [version]';

  @override
  final description = 'Sets up a new Flutter environment.';

  @override
  Future<EnvCreateResult> run() async {
    final channel = argResults!['channel'] as String?;
    final args = unwrapArguments(atLeast: 1, atMost: 2);
    final version = args.length > 1 ? args[1] : null;
    final envName = args.first;

    return createEnvironment(
      scope: scope,
      envName: envName,
      flutterVersion: await FlutterVersion.query(
        scope: scope,
        version: version,
        channel: channel,
      ),
    );
  }
}
