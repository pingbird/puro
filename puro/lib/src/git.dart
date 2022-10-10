import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:puro/src/config.dart';
import 'package:puro/src/logger.dart';
import 'package:puro/src/provider.dart';

class GitClient {
  GitClient({
    required this.gitExecutable,
    required this.log,
  });

  final File gitExecutable;
  final PuroLogger log;

  Future<ProcessResult> _git(
    List<String> args, {
    Directory? directory,
  }) async {
    log.v('${directory?.path ?? ''}> ${gitExecutable.path} ${args.join(' ')}');

    final process = await Process.start(
      gitExecutable.path,
      args,
      runInShell: true,
      workingDirectory: directory?.path,
    );

    process.stdin.close();

    final stdout = utf8.decoder.bind(process.stdout).join();

    final stderr = LineSplitter().bind(utf8.decoder.bind(process.stderr)).map(
      (e) {
        log.v('git: $e');
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
        for (final line in (result.stderr as String).split('\n')) {
          log.e('git: $line');
        }
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
  }) async {
    final cloneResult = await _git([
      'clone',
      '$remote',
      if (branch != null) ...['--branch', branch],
      if (reference != null) ...['--reference', reference.path],
      if (!checkout) '--no-checkout',
      repository.path,
    ]);
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

  static final provider = Provider<GitClient>((scope) {
    return GitClient(
      gitExecutable: PuroConfig.of(scope).gitExecutable,
      log: PuroLogger.of(scope),
    );
  });
  static GitClient of(Scope scope) => scope.read(provider);
}
