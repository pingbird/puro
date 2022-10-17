import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';

import 'config.dart';
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
  }) async {
    log.v('${directory?.path ?? ''}> ${gitExecutable.path} ${args.join(' ')}');

    final process = await startProcess(
      scope,
      gitExecutable.path,
      args,
      runInShell: true,
      workingDirectory: directory?.path,
    );

    process.stdin.close();

    final stdout =
        const LineSplitter().bind(utf8.decoder.bind(process.stdout)).map(
      (e) {
        log.d('git: $e');
        if (onStdout != null) onStdout(e);
        return e;
      },
    ).join('\n');

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
      if (log.level == null || log.level! < LogLevel.verbose) {
        log.e('git: ${result.stderr}');
      }
      throw StateError(
        'git subprocess failed with exit code ${result.exitCode}',
      );
    }
  }

  Future<void> clone({
    required Uri remote,
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
        '$remote',
        if (branch != null) ...['--branch', branch],
        if (reference != null) ...['--reference', reference.path],
        if (!checkout) '--no-checkout',
        if (onProgress != null) '--progress',
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

  Future<void> checkout({
    required Directory repository,
    required String refname,
    bool detach = false,
  }) async {
    final checkoutResult = await _git(
      [
        'checkout',
        if (detach) '--detach',
        refname,
      ],
      directory: repository,
    );
    _ensureSuccess(checkoutResult);
  }

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

  Future<String> revParseSingle({
    required Directory repository,
    required String arg,
    bool short = false,
  }) async {
    final revParseResult = await _git(
      [
        'rev-parse',
        if (short) '--short',
        arg,
      ],
      directory: repository,
    );
    _ensureSuccess(revParseResult);
    return (revParseResult.stdout as String).trim().split('\n').single;
  }

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

  static final provider = Provider<GitClient>((scope) {
    return GitClient(scope: scope);
  });
  static GitClient of(Scope scope) => scope.read(provider);
}
