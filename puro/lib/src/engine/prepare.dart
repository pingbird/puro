import 'dart:io';

import '../command_result.dart';
import '../config.dart';
import '../env/create.dart';
import '../git.dart';
import '../provider.dart';
import 'linux_worker.dart';

/// Clone the Flutter Engine using git objects from a shared repository.
Future<void> cloneEngineWithSharedRefs({
  required Scope scope,
  required EnvConfig environment,
  String? engineCommit,
  String? forkRemoteUrl,
  bool force = false,
}) async {
  final git = GitClient.of(scope);
  final config = PuroConfig.of(scope);

  engineCommit ??= environment.flutter.engineVersion;
  engineCommit ??= await getEngineVersionOfCommit(
    scope: scope,
    commit: await git.getCurrentCommitHash(repository: environment.flutterDir),
  );

  if (engineCommit == null) {
    throw AssertionError(
      'Failed to detect engine version of environment `${environment.name}`\n'
      'Does `${environment.flutter.engineVersionFile.path}` exist?',
    );
  }

  final sharedRepository = config.sharedEngineDir;
  if (forkRemoteUrl != null ||
      !await git.checkCommitExists(
        repository: config.sharedFlutterDir,
        commit: engineCommit,
      )) {
    await fetchOrCloneShared(
      scope: scope,
      repository: sharedRepository,
      remoteUrl: config.engineGitUrl,
    );
  }
}

Future<void> prepareEngine({
  required Scope scope,
  required EnvConfig environment,
}) async {
  if (!Platform.isLinux) {
    throw UnsupportedOSError();
  }
  await installLinuxWorkerPackages(scope: scope);
  await cloneEngineWithSharedRefs(
    scope: scope,
    environment: environment,
  );
}
