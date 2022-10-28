import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart';

import 'config.dart';
import 'extensions.dart';
import 'logger.dart';
import 'process.dart';
import 'provider.dart';

enum GitCloneStep {
  countingObjects('remote: Counting objects'),
  compressingObjects('remote: Compressing objects'),
  receivingObjects('Receiving objects'),
  resolvingDeltas('Resolving deltas');

  const GitCloneStep(this.prefix);

  final String prefix;
}

class GitClient {
  GitClient({
    required this.scope,
  });

  final Scope scope;
  late final config = PuroConfig.of(scope);
  late final gitExecutable = config.gitExecutable;
  late final log = PuroLogger.of(scope);

  Future<ProcessResult> _git(
    List<String> args, {
    Directory? directory,
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
    bool binary = false,
  }) async {
    if (directory != null && !directory.existsSync()) {
      return ProcessResult(
        -1,
        -1,
        binary ? Uint8List(0) : '',
        'working directory ${directory.path} does not exist',
      );
    }

    log.v('${directory?.path ?? ''}> ${gitExecutable.path} ${args.join(' ')}');

    final process = await startProcess(
      scope,
      gitExecutable.path,
      args,
      workingDirectory: directory?.path,
    );

    process.stdin.close();

    final Future<dynamic> stdout;
    if (binary) {
      stdout = process.stdout.toBytes();
    } else {
      stdout = const LineSplitter().bind(utf8.decoder.bind(process.stdout)).map(
        (e) {
          log.d('git: $e');
          if (onStdout != null) onStdout(e);
          return e;
        },
      ).join('\n');
    }

    final stderr =
        const LineSplitter().bind(utf8.decoder.bind(process.stderr)).map(
      (e) {
        log.d('git: $e');
        if (onStderr != null) onStderr(e);
        return e;
      },
    ).join('\n');

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      log.v('git failed with exit code $exitCode');
    }

    return ProcessResult(
      process.pid,
      exitCode,
      await stdout,
      await stderr,
    );
  }

  void _ensureSuccess(ProcessResult result) {
    if (result.exitCode != 0) {
      if (log.level == null || log.level! < LogLevel.debug) {
        log.e('git: ${result.stderr}');
      }
      throw StateError(
        'git subprocess failed with exit code ${result.exitCode}',
      );
    }
  }

  /// https://git-scm.com/docs/git-init
  Future<void> init({required Directory repository}) async {
    final result = await _git(
      ['init'],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  /// https://git-scm.com/docs/git-remote
  Future<void> addRemote({
    required Directory repository,
    String name = 'origin',
    required String remote,
    bool fetch = false,
  }) async {
    final result = await _git(
      [
        'remote',
        'add',
        if (fetch) '-f',
        name,
        remote,
      ],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  /// https://git-scm.com/docs/git -clone
  Future<void> clone({
    required String remote,
    required Directory repository,
    bool shared = false,
    String? branch,
    Directory? reference,
    bool checkout = true,
    void Function(GitCloneStep step, double progress)? onProgress,
  }) async {
    if (onProgress != null) onProgress(GitCloneStep.values.first, 0);
    final cloneResult = await _git(
      [
        'clone',
        remote,
        if (branch != null) ...['--branch', branch],
        if (reference != null) ...['--reference', reference.path],
        if (!checkout) '--no-checkout',
        if (onProgress != null) '--progress',
        if (shared) '--shared',
        repository.path,
      ],
      onStderr: (line) {
        if (onProgress == null) return;
        if (line.endsWith(', done.')) return;
        for (final step in GitCloneStep.values) {
          final prefix = '${step.prefix}:';
          if (!line.startsWith(prefix)) continue;
          final percentIndex = line.indexOf('%', prefix.length);
          if (percentIndex < 0) {
            continue;
          }
          final percent = int.tryParse(line
              .substring(
                prefix.length,
                percentIndex,
              )
              .trimLeft());
          if (percent == null) continue;
          onProgress(step, percent / 100);
        }
      },
    );
    _ensureSuccess(cloneResult);
  }

  /// https://git-scm.com/docs/git-checkout
  Future<void> checkout({
    required Directory repository,
    required String ref,
    bool detach = false,
  }) async {
    final checkoutResult = await _git(
      [
        'checkout',
        if (detach) '--detach',
        ref,
      ],
      directory: repository,
    );
    _ensureSuccess(checkoutResult);
  }

  /// https://git-scm.com/docs/git-fetch
  Future<void> fetch({
    required Directory repository,
    String? ref,
  }) async {
    final cloneResult = await _git(
      [
        'fetch',
        if (ref != null) ref,
      ],
      directory: repository,
    );
    _ensureSuccess(cloneResult);
  }

  /// https://git-scm.com/docs/git-rev-parse
  Future<List<String>> revParse({
    required Directory repository,
    required List<String> args,
    bool short = false,
    bool abbreviation = false,
  }) async {
    final revParseResult = await _git(
      [
        'rev-parse',
        if (short) '--short',
        if (abbreviation) '--abbrev-ref',
        ...args,
      ],
      directory: repository,
    );
    _ensureSuccess(revParseResult);
    return (revParseResult.stdout as String).trim().split('\n').toList();
  }

  /// Same as [revParse] but parses a single argument.
  Future<String> revParseSingle({
    required Directory repository,
    required String arg,
    bool short = false,
    bool abbreviation = false,
  }) async {
    final result = await revParse(
      repository: repository,
      args: [arg],
      short: short,
      abbreviation: abbreviation,
    );
    return result.single;
  }

  /// Same as [tryRevParse] but returns null on failure.
  Future<List<String>?> tryRevParse({
    required Directory repository,
    required List<String> args,
    bool short = false,
    bool abbreviation = false,
  }) async {
    final revParseResult = await _git(
      [
        'rev-parse',
        if (short) '--short',
        if (abbreviation) '--abbrev-ref',
        ...args,
      ],
      directory: repository,
    );
    if (revParseResult.exitCode != 0) {
      return null;
    }
    return (revParseResult.stdout as String).trim().split('\n').toList();
  }

  /// Same as [revParseSingle] but returns null on failure.
  Future<String?> tryRevParseSingle({
    required Directory repository,
    required String arg,
    bool short = false,
    bool abbreviation = false,
  }) async {
    final result = await tryRevParse(
      repository: repository,
      args: [arg],
      short: short,
      abbreviation: abbreviation,
    );
    return result?.single;
  }

  final _branchRegex = RegExp(
    r'^(?!.*/\.)(?!.*\.\.)(?!/)(?!.*//)(?!.*@\{)(?!.*\\)[^\000-\037\177 ~^:?*[]+/[^\000-\037\177 ~^:?*[]+(?<!\.lock)(?<!/)(?<!\.)$',
  );

  Future<bool> checkBranchExists({
    required String branch,
  }) async {
    if (!_branchRegex.hasMatch(branch)) return false;
    final result = await _git([
      'branch',
      '-a',
      '--list',
      branch,
    ]);
    return result.exitCode == 0;
  }

  /// Get the commit hash of the current branch.
  Future<String> getCurrentCommitHash({
    required Directory repository,
    bool short = false,
    String branch = 'HEAD',
  }) {
    return revParseSingle(
      repository: repository,
      short: short,
      arg: branch,
    );
  }

  /// Same as [getCurrentCommitHash] but returns null on failure.
  Future<String?> tryGetCurrentCommitHash({
    required Directory repository,
    bool short = false,
    String branch = 'HEAD',
  }) {
    return tryRevParseSingle(
      repository: repository,
      short: short,
      arg: branch,
    );
  }

  /// Attempts to get the branch of the current commit, returns null if we are
  /// detached from a branch.
  Future<String?> getBranch({
    required Directory repository,
    bool short = false,
    String ref = 'HEAD',
  }) async {
    final result = await revParseSingle(
      repository: repository,
      short: short,
      arg: ref,
      abbreviation: true,
    );
    if (result == ref) {
      return null;
    }
    return result;
  }

  /// https://git-scm.com/docs/git-show
  Future<Uint8List> show({
    required Directory repository,
    required List<String> objects,
  }) async {
    final result = await _git(
      [
        'show',
        ...objects,
      ],
      directory: repository,
      binary: true,
    );
    _ensureSuccess(result);
    return result.stdout as Uint8List;
  }

  /// Same as [show] but returns null on failure.
  Future<Uint8List?> tryShow({
    required Directory repository,
    required List<String> objects,
  }) async {
    final result = await _git(
      [
        'show',
        ...objects,
      ],
      directory: repository,
      binary: true,
    );
    if (result.exitCode != 0) return null;
    return result.stdout as Uint8List;
  }

  /// Reads a file from a reference the git repository.
  Future<Uint8List> cat({
    required Directory repository,
    String ref = 'HEAD',
    required String path,
  }) {
    return show(
      repository: repository,
      objects: ['$ref:$path'],
    );
  }

  /// Same as [cat] but returns null on failure.
  Future<Uint8List?> tryCat({
    required Directory repository,
    String ref = 'HEAD',
    required String path,
  }) {
    return tryShow(
      repository: repository,
      objects: ['$ref:$path'],
    );
  }

  static final provider = Provider<GitClient>((scope) {
    return GitClient(scope: scope);
  });
  static GitClient of(Scope scope) => scope.read(provider);
}
