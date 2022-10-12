import 'package:pub_semver/pub_semver.dart';

import '../command.dart';
import '../env/create.dart';
import '../env/delete.dart';
import '../env/install.dart';
import '../env/list.dart';

class EnvCommand extends PuroCommand {
  EnvCommand() {
    addSubcommand(EnvLsCommand());
    addSubcommand(EnvCreateCommand());
    addSubcommand(EnvRmCommand());
    addSubcommand(EnvUseCommand());
  }

  @override
  final name = 'env';

  @override
  final description = 'Manage puro environments.';
}

class EnvLsCommand extends PuroCommand {
  @override
  final name = 'ls';

  @override
  final description = 'List available environments.';

  @override
  Future<ListEnvironmentResult> run() async {
    return listEnvironments(scope: scope);
  }
}

class EnvCreateCommand extends PuroCommand {
  EnvCreateCommand() {
    argParser.addOption(
      'version',
      help: 'The version of Flutter to base the environment on.',
    );
    argParser.addOption(
      'channel',
      help:
          'The Flutter channel, in case multiple channels have builds with the same version number.',
    );
  }

  @override
  final name = 'create';

  @override
  String? get argumentUsage => '<name>';

  @override
  final description = 'Sets up a new Flutter environment.';

  @override
  Future<EnvCreateResult> run() async {
    var channel = argResults!['channel'] as String?;
    var version = argResults!['version'] as String?;

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
      envName: unwrapSingleArgument(),
      version: version == null ? null : Version.parse(version),
      channel: channel == null ? null : FlutterChannel.fromString(channel),
    );
  }
}

class EnvRmCommand extends PuroCommand {
  @override
  final name = 'rm';

  @override
  final description = 'Delete an environment.';

  @override
  String? get argumentUsage => '<name>';

  @override
  Future<CommandResult> run() async {
    final name = unwrapSingleArgument();
    await deleteEnvironment(
      scope: scope,
      name: name,
    );
    return BasicMessageResult(
      success: true,
      message: 'Deleted environment `$name`',
    );
  }
}

class EnvUseCommand extends PuroCommand {
  @override
  final name = 'use';

  @override
  final description = 'Select an environment to use in the current project.';

  @override
  String? get argumentUsage => '<name>';

  @override
  Future<CommandResult> run() async {
    final name = unwrapSingleArgument();
    await useEnvironment(
      scope: scope,
      name: name,
    );
    return BasicMessageResult(
      success: true,
      message: 'Now using environment `$name` for the current project',
    );
  }
}
