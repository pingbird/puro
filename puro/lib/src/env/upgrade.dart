import 'package:pub_semver/pub_semver.dart';

import '../command.dart';
import '../config.dart';
import '../proto/puro.pb.dart';
import '../provider.dart';
import 'releases.dart';

class EnvUpgradeResult extends CommandResult {
  EnvUpgradeResult({
    required this.environment,
    required this.fromChannel,
    required this.fromVersion,
    required this.fromCommit,
    required this.toChannel,
    required this.toVersion,
    required this.toCommit,
  });

  final EnvConfig environment;
  final FlutterChannel? fromChannel;
  final Version? fromVersion;
  final String fromCommit;
  final FlutterChannel? toChannel;
  final Version? toVersion;
  final String toCommit;

  @override
  String get description => [
        'Upgraded `${environment.name}` from',
        if (fromChannel != null) fromChannel?.name,
        if (fromVersion != null) '$fromVersion',
        if (fromChannel != null || fromVersion != null)
          '(commit $fromCommit)'
        else
          fromCommit,
        'to',
        if (toChannel != null) toChannel?.name,
        if (toVersion != null) '$toVersion',
        if (toChannel != null || toVersion != null)
          '(commit $toCommit)'
        else
          toCommit,
      ].join(' ');

  @override
  CommandResultModel toModel() {
    return CommandResultModel(
      success: true,
      environmentUpgrade: EnvironmentUpgradeModel(
        environment: environment.name,
        fromChannel: fromChannel?.name,
        fromVersion: fromVersion?.toString(),
        fromCommit: fromCommit,
        toChannel: toChannel?.name,
        toVersion: toVersion?.toString(),
        toCommit: toCommit,
      ),
    );
  }
}

/// Upgrades an environment to a different version of flutter.
Future<EnvUpgradeResult> upgradeEnvironment({
  required Scope scope,
  required String name,
  Version? version,
  FlutterChannel? channel,
}) async {
  final config = PuroConfig.of(scope);
  // ignore: unused_local_variable
  final env = config.getEnv(name);
  throw UnimplementedError();
}
