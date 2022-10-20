import 'package:file/file.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../models.dart';
import '../command.dart';
import '../config.dart';
import '../git.dart';
import '../logger.dart';
import '../progress.dart';
import '../provider.dart';
import 'engine.dart';
import 'releases.dart';

class EnvCreateResult extends CommandResult {
  EnvCreateResult({
    required this.success,
    required this.existing,
    required this.directory,
  });

  final bool success;
  final bool existing;
  final Directory directory;

  @override
  CommandResultModel toModel() {
    return CommandResultModel(success: success);
  }

  @override
  String? get description => existing
      ? 'Updated existing environment `${directory.basename}`'
      : 'Created new environment `${directory.basename}` in `${directory.path}`';
}

/// Creates a new Puro environment named [envName] and installs flutter.
Future<EnvCreateResult> createEnvironment({
  required Scope scope,
  required String envName,
  Version? version,
  FlutterChannel? channel,
}) async {
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);
  final environment = config.getEnv(envName);

  log.v('Creating a new environment in ${environment.envDir.path}');

  final existing = environment.envDir.existsSync();
  environment.envDir.createSync(recursive: true);

  // Clone flutter
  await cloneFlutterWithSharedRefs(
    scope: scope,
    repository: environment.flutterDir,
    version: version,
    channel: channel,
  );

  // Set up engine
  await setUpFlutterTool(
    scope: scope,
    environment: environment,
  );

  return EnvCreateResult(
    success: true,
    existing: existing,
    directory: environment.envDir,
  );
}

/// Clones or fetches from a remote, putting it in a shared repository.
Future<void> fetchOrCloneShared({
  required Scope scope,
  required Directory repository,
  required Uri remote,
}) async {
  await ProgressNode.of(scope).wrap((scope, node) async {
    final git = GitClient.of(scope);
    if (repository.existsSync()) {
      node.description = 'Fetching $remote';
      await git.fetch(repository: repository);
    } else {
      node.description = 'Cloning $remote';
      await git.clone(
        remote: remote,
        repository: repository,
        shared: true,
        checkout: false,
        onProgress: node.onCloneProgress,
      );
    }
  });
}

/// Clone Flutter using git objects from a shared repository.
Future<void> cloneFlutterWithSharedRefs({
  required Scope scope,
  required Directory repository,
  Version? version,
  FlutterChannel? channel,
}) async {
  final git = GitClient.of(scope);
  final config = PuroConfig.of(scope);

  final ref = await findFrameworkRef(
    scope: scope,
    version: version,
    channel: channel,
  );

  final sharedRepository = config.sharedFlutterDir;
  await fetchOrCloneShared(
    scope: scope,
    repository: sharedRepository,
    remote: config.flutterGitUrl,
  );

  if (!repository.existsSync()) {
    await ProgressNode.of(scope).wrap((scope, node) async {
      node.description = 'Cloning framework from cache';
      await git.clone(
        remote: config.flutterGitUrl,
        repository: repository,
        reference: sharedRepository,
        checkout: false,
      );
    });
  }

  await ProgressNode.of(scope).wrap((scope, node) async {
    node.description = 'Checking out $ref';
    await git.checkout(
      repository: repository,
      refname: ref,
    );
  });
}
