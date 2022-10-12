import 'package:pub_semver/pub_semver.dart';

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
    var channel = argResults!['channel'] as String?;
    final args = unwrapArguments(atLeast: 1, atMost: 2);
    var version = args.length > 1 ? args[1] : null;
    final envName = args.first;

    if (channel != null && FlutterChannel.fromString(channel) == null) {
      final allChannels = FlutterChannel.values.map((e) => e.name).join(', ');
      throw ArgumentError(
        'Invalid Flutter channel "$channel", valid channels: $allChannels',
      );
    }

    if (version != null && FlutterChannel.fromString(version) != null) {
      channel = version;
      version = null;
    }

    if (version?.startsWith('v') ?? false) {
      version = version!.substring(1);
    }

    return createEnvironment(
      scope: scope,
      envName: envName,
      version: version == null ? null : Version.parse(version),
      channel: channel == null ? null : FlutterChannel.fromString(channel),
    );
  }
}
