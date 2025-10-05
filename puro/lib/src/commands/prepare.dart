import '../command.dart';
import '../command_result.dart';
import '../env/default.dart';
import '../env/prepare.dart';
import '../logger.dart';

class PrepareCommand extends PuroCommand {
  PrepareCommand() {
    argParser
      ..addFlag(
        'force',
        help: 'Force re-downloading artifacts even if they already exist.',
        negatable: false,
      )
      ..addFlag(
        'all-platforms',
        help: 'Precache artifacts for every supported Flutter platform.',
        negatable: false,
      )
      ..addMultiOption(
        'platform',
        help:
            'Precache artifacts for the provided platforms (android, ios, etc).',
        valueHelp: 'name',
        allowed: preparePlatformOptions.toList()..sort(),
      );
  }

  @override
  final name = 'prepare';

  @override
  final description =
      'Pre-downloads Flutter artifacts for an environment so builds can start immediately.';

  @override
  String? get argumentUsage => '[env]';

  @override
  Future<CommandResult> run() async {
    final log = PuroLogger.of(scope);
    final envName = unwrapSingleOptionalArgument();
    final environment = await getProjectEnvOrDefault(
      scope: scope,
      envName: envName,
    );

    final force = argResults!['force'] as bool;
    final allPlatforms = argResults!['all-platforms'] as bool;
    final requestedPlatforms = (argResults!['platform'] as List<String>).map(
      (e) => e.toLowerCase(),
    );
    final sortedRequested = sortPreparePlatforms(requestedPlatforms);
    final defaultPlatforms = defaultPreparePlatforms();

    final platforms = sortedRequested.isNotEmpty
        ? sortedRequested
        : (allPlatforms ? <String>[] : defaultPlatforms);

    log.d(
      'Preparing environment `${environment.name}` for platforms: '
      '${allPlatforms ? 'all platforms' : (platforms.isEmpty ? 'default set' : platforms.join(', '))}'
      '${force ? ' (force)' : ''}',
    );

    await prepareEnvironment(
      scope: scope,
      environment: environment,
      platforms: platforms,
      allPlatforms: allPlatforms,
      force: force,
    );

    final platformSummary = allPlatforms
        ? 'all platforms'
        : (platforms.isEmpty
              ? 'default platforms (${defaultPlatforms.join(', ')})'
              : platforms.join(', '));

    return BasicMessageResult(
      'Prepared environment `${environment.name}` (${platformSummary}${force ? ', forced' : ''})',
    );
  }
}
