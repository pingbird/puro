import 'dart:convert';
import 'dart:io';

import '../command_result.dart';
import '../config.dart';
import '../env/create.dart';
import '../git.dart';
import '../logger.dart';
import '../process.dart';
import '../progress.dart';
import '../provider.dart';
import 'depot_tools.dart';
import 'worker.dart';

Future<void> prepareEngineSystemDeps({required Scope scope}) async {
  await installDepotTools(scope: scope);

  if (Platform.isLinux) {
    await installLinuxWorkerPackages(scope: scope);
  } else if (Platform.isWindows) {
    await ensureWindowsPythonInstalled(scope: scope);
  } else {
    throw UnsupportedOSError();
  }
}

/// Checks out and prepares the engine for building.
Future<void> prepareEngine({
  required Scope scope,
  required EnvConfig environment,
  required String? ref,
  String? forkRemoteUrl,
  bool force = false,
}) async {
  final git = GitClient.of(scope);
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);

  await prepareEngineSystemDeps(scope: scope);

  ref ??= environment.flutter.engineVersion;
  ref ??= await getEngineVersionOfCommit(
    scope: scope,
    commit: await git.getCurrentCommitHash(repository: environment.flutterDir),
  );

  if (ref == null) {
    throw AssertionError(
      'Failed to detect engine version of environment `${environment.name}`\n'
      'Does `${environment.flutter.engineVersionFile.path}` exist?',
    );
  }

  final sharedRepository = config.sharedEngineDir;
  if (forkRemoteUrl != null ||
      !await git.checkCommitExists(repository: sharedRepository, commit: ref)) {
    await fetchOrCloneShared(
      scope: scope,
      repository: sharedRepository,
      remoteUrl: config.engineGitUrl,
    );
  }

  final origin = forkRemoteUrl ?? config.engineGitUrl;
  final upstream = forkRemoteUrl == null ? null : config.engineGitUrl;

  final remotes = {
    if (upstream != null) 'upstream': GitRemoteUrls.single(upstream),
    'origin': GitRemoteUrls.single(origin),
  };

  final repository = environment.engine.engineSrcDir;

  await ProgressNode.of(scope).wrap((scope, node) async {
    node.description = 'Initializing repository';
    if (!repository.childDirectory('.git').existsSync()) {
      repository.createSync(recursive: true);
      await git.init(repository: repository);
    }
    final alternatesFile = repository
        .childDirectory('.git')
        .childDirectory('objects')
        .childDirectory('info')
        .childFile('alternates');
    final sharedObjects = sharedRepository
        .childDirectory('.git')
        .childDirectory('objects');
    alternatesFile.writeAsStringSync('${sharedObjects.path}\n');
    await git.syncRemotes(repository: repository, remotes: remotes);
    await git.checkout(repository: repository, ref: ref);
  });

  // This is Python, not JSON.
  environment.engine.gclientFile.writeAsStringSync('''solutions = [
  {
    "managed": False,
    "name": "src/flutter",
    "url": ${jsonEncode(origin)},
    "custom_deps": {},
    "deps_file": "DEPS",
    "safesync_url": "",
  }
]
cache_dir = ${jsonEncode(config.sharedGClientDir.path)}
''');

  await ProgressNode.of(scope).wrap((scope, node) async {
    node.description = 'Running gclient sync (this may take awhile)';

    final envVars = await getEngineBuildEnvVars(scope: scope);

    final proc = await startProcess(
      scope,
      'gclient',
      ['sync', '--verbose', '--verbose'],
      workingDirectory: environment.engineRootDir.path,
      runInShell: true,
      environment: envVars,
    );

    final logFile = environment.engineRootDir.childFile('gclient.log');
    final logSink = logFile.openWrite(mode: FileMode.append);
    final stdoutFuture = proc.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          log.d('gclient: $line');
          logSink.writeln(line);
        })
        .asFuture();
    final stderrFuture = proc.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          log.d('(E) gclient: $line');
          logSink.writeln(line);
        })
        .asFuture();

    final exitCode = await proc.exitCode;
    await stdoutFuture;
    await stderrFuture;
    await logSink.close();

    if (exitCode != 0) {
      throw CommandError(
        'gclient sync failed with exit code ${await proc.exitCode}\n'
        'See ${logFile.path} for more details',
      );
    }
  });
}
