import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pub_semver/pub_semver.dart';

import 'config.dart';
import 'extensions.dart';
import 'logger.dart';
import 'process.dart';
import 'progress.dart';
import 'provider.dart';
import 'terminal.dart';

enum GitCloneStep {
  // We used to have 'remote: Counting objects' / 'remote: Compressing objects'
  // but git seems to print their progress all at once.
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
  late final _puroConfig = PuroConfig.of(scope);
  late final _gitExecutable = _puroConfig.gitExecutable;
  late final _log = PuroLogger.of(scope);
  late final _terminal = Terminal.of(scope);

  Future<ProcessResult> raw(
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

    final process = await startProcess(
      scope,
      _gitExecutable.path,
      args,
      workingDirectory: directory?.path,
    );

    unawaited(process.stdin.close());

    final Future<dynamic> stdout;
    if (binary) {
      stdout = process.stdout.toBytes();
    } else {
      stdout = const LineSplitter()
          .bind(systemEncoding.decoder.bind(process.stdout))
          .map(
        (e) {
          _log.d('git: $e');
          if (onStdout != null) onStdout(e);
          return e;
        },
      ).join('\n');
    }

    final stderr = const LineSplitter()
        .bind(systemEncoding.decoder.bind(process.stderr))
        .map(
      (e) {
        _log.d('git: $e');
        if (onStderr != null) onStderr(e);
        return e;
      },
    ).join('\n');

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      _log.v('git failed with exit code $exitCode');
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
      if (_log.level == null || _log.level! < LogLevel.debug) {
        _log.e('git: ${result.stderr}');
      }
      throw StateError(
        'git subprocess failed with exit code ${result.exitCode}',
      );
    }
  }

  /// https://git-scm.com/docs/git-init
  Future<void> init({required Directory repository}) async {
    final result = await raw(
      ['init'],
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
    final cloneResult = await raw(
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

  Future<void> cloneWithProgress({
    required String remote,
    required Directory repository,
    bool shared = false,
    String? branch,
    Directory? reference,
    bool checkout = true,
    String? description,
  }) async {
    await ProgressNode.of(scope).wrap((scope, node) async {
      node.description = description ?? 'Cloning $remote';
      await clone(
        remote: remote,
        repository: repository,
        shared: shared,
        branch: branch,
        reference: reference,
        checkout: checkout,
        onProgress: _terminal.enableStatus ? node.onCloneProgress : null,
      );
    });
  }

  /// https://git-scm.com/docs/git-checkout
  Future<void> checkout({
    required Directory repository,
    String? ref,
    bool detach = false,
    bool track = false,
    bool force = false,
    String? newBranch,
  }) async {
    final result = await raw(
      [
        'checkout',
        if (detach) '--detach',
        if (track) '--track',
        if (force) '-f',
        if (newBranch != null) ...['-b', newBranch],
        if (ref != null) ref,
      ],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  /// https://git-scm.com/docs/git-reset
  Future<void> reset({
    required Directory repository,
    String? ref,
    bool soft = false,
    bool mixed = false,
    bool hard = false,
    bool merge = false,
    bool keep = false,
  }) async {
    final result = await raw(
      [
        'reset',
        if (soft) '--soft',
        if (mixed) '--mixed',
        if (hard) '--hard',
        if (merge) '--merge',
        if (keep) '--keep',
        if (ref != null) ref,
      ],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  /// https://git-scm.com/docs/git-reset
  Future<bool> tryReset({
    required Directory repository,
    String? ref,
    bool soft = false,
    bool mixed = false,
    bool hard = false,
    bool merge = false,
    bool keep = false,
  }) async {
    final result = await raw(
      [
        'reset',
        if (soft) '--soft',
        if (mixed) '--mixed',
        if (hard) '--hard',
        if (merge) '--merge',
        if (keep) '--keep',
        if (ref != null) ref,
      ],
      directory: repository,
    );
    return result.exitCode == 0;
  }

  /// https://git-scm.com/docs/git-pull
  Future<void> pull({
    required Directory repository,
    String? remote,
    bool all = false,
  }) async {
    final result = await raw(
      [
        'pull',
        if (remote != null) remote,
        if (all) '--all',
      ],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  /// https://git-scm.com/docs/git-fetch
  Future<void> fetch({
    required Directory repository,
    String remote = 'origin',
    String? ref,
    bool all = false,
    bool updateHeadOk = false,
  }) async {
    final result = await raw(
      [
        'fetch',
        if (all) '--all',
        if (updateHeadOk) '--update-head-ok',
        if (!all) remote,
        if (ref != null) ref,
      ],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  /// https://git-scm.com/docs/git-merge
  Future<void> merge({
    required Directory repository,
    required String fromCommit,
    bool? fastForward,
    bool fastForwardOnly = false,
  }) async {
    final result = await raw(
      [
        'merge',
        if (fastForward != null)
          if (fastForward) '--ff' else '--no-ff',
        if (fastForwardOnly) '--ff-only',
        fromCommit,
      ],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  /// https://git-scm.com/docs/git-rev-parse
  Future<List<String>> revParse({
    required Directory repository,
    required List<String> args,
    bool short = false,
    bool abbreviation = false,
  }) async {
    final result = await raw(
      [
        'rev-parse',
        if (short) '--short',
        if (abbreviation) '--abbrev-ref',
        ...args,
      ],
      directory: repository,
    );
    _ensureSuccess(result);
    return (result.stdout as String).trim().split('\n').toList();
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
    bool verify = false,
  }) async {
    final result = await raw(
      [
        'rev-parse',
        if (short) '--short',
        if (abbreviation) '--abbrev-ref',
        if (verify) '--verify',
        ...args,
      ],
      directory: repository,
    );
    if (result.exitCode != 0) {
      return null;
    }
    return (result.stdout as String).trim().split('\n').toList();
  }

  /// Same as [revParseSingle] but returns null on failure.
  Future<String?> tryRevParseSingle({
    required Directory repository,
    required String arg,
    bool short = false,
    bool abbreviation = false,
    bool verify = false,
  }) async {
    final result = await tryRevParse(
      repository: repository,
      args: [arg],
      short: short,
      abbreviation: abbreviation,
      verify: verify,
    );
    return result?.single;
  }

  /// Returns true if the repository has uncomitted changes.
  Future<bool> hasUncomittedChanges({
    required Directory repository,
  }) async {
    await raw(['git update-index', '--refresh']);
    final result = await raw(['diff-index', '--quiet', 'HEAD', '--']);
    return result.exitCode != 0;
  }

  /// Get the commit hash of the current branch.
  Future<String> getCurrentCommitHash({
    required Directory repository,
    bool short = false,
    String branch = 'HEAD',
  }) async {
    return await revParseSingle(
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

  /// https://git-scm.com/docs/git-branch
  Future<void> branch({
    required Directory repository,
    required String branch,
    String? setUpstream,
    bool force = false,
    bool delete = false,
  }) async {
    final result = await raw(
      [
        'branch',
        if (force) '-f',
        if (delete) '-d',
        if (setUpstream != null) ...['-u', setUpstream],
        branch,
      ],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  Future<bool> checkCommitExists({
    required Directory repository,
    required String commit,
  }) async {
    if (!repository.existsSync()) return false;
    final result = await tryRevParseSingle(
      repository: repository,
      arg: '$commit^{commit}',
      verify: true,
    );
    return result == commit;
  }

  /// Returns true if the provided branch name exists.
  Future<bool> checkBranchExists({
    required Directory repository,
    required String branch,
  }) async {
    final result = await raw(
      [
        'show-ref',
        'refs/heads/$branch',
      ],
      directory: repository,
    );
    return result.exitCode == 0;
  }

  /// Returns true if the provided branch name exists.
  Future<void> deleteBranch({
    required Directory repository,
    required String branch,
  }) async {
    final result = await raw(
      [
        'branch',
        '-D',
        branch,
      ],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  /// Attempts to get the branch of the current commit, returns null if we are
  /// detached from a branch.
  Future<String?> getBranch({
    required Directory repository,
    bool short = false,
    String ref = 'HEAD',
  }) async {
    final result = await tryRevParseSingle(
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

  /// https://git-scm.com/docs/git-symbolic-ref
  Future<void> setSymbolicRef({
    required Directory repository,
    required String name,
    required String? ref,
  }) async {
    final result = await raw(
      [
        'symbolic-ref',
        name,
        if (ref == null) '--delete' else ref,
      ],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  /// https://git-scm.com/docs/git-show
  Future<Uint8List> show({
    required Directory repository,
    required List<String> objects,
  }) async {
    final result = await raw(
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
    final result = await raw(
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

  /// Checks if a file exists in the repository.
  Future<bool> exists({
    required Directory repository,
    String ref = 'HEAD',
    required String path,
  }) async {
    final result = await raw(
      ['cat-file', '-e', '$ref:$path'],
      directory: repository,
      binary: true,
    );
    return result.exitCode == 0;
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

  /// Gets all of the names of tags containing the provided ref.
  ///
  /// https://git-scm.com/docs/git-tag
  Future<List<String>> getTagsContainingRef({
    required Directory repository,
    required String ref,
  }) async {
    final result = await raw(
      ['tag', '--points-at', ref],
      directory: repository,
    );
    return (result.stdout as String).trim().split('\n');
  }

  /// Returns a human-readable description of the provided ref,
  Future<String> describe({
    required Directory repository,
    required String ref,
    bool tags = false,
    String? match,
    bool long = false,
  }) async {
    final result = await raw(
      [
        'describe',
        if (tags) '--tags',
        if (long) '--long',
        if (match != null) ...['--match', match],
        ref,
      ],
      directory: repository,
    );
    return (result.stdout as String).trim();
  }

  static final _remoteRegex = RegExp(r'^(\S+)\s+(\S+)\s+\((.+?)\)$');

  /// Gets all git remotes.
  ///
  /// https://git-scm.com/docs/git-remote
  Future<Map<String, GitRemoteUrls>> getRemotes({
    required Directory repository,
  }) async {
    final result = await raw(
      ['remote', '-v'],
      directory: repository,
    );
    _ensureSuccess(result);
    final stdout = result.stdout as String;
    final fetches = <String, String>{};
    final pushes = <String, Set<String>>{};
    for (final line in stdout.split('\n')) {
      if (line.isEmpty) continue;
      final match = _remoteRegex.matchAsPrefix(line);
      if (match == null) {
        _log.w('Failed to parse remote: ${jsonEncode(line)}');
        continue;
      }
      final name = match.group(1)!;
      final url = match.group(2)!;
      final type = match.group(3)!;
      if (type == 'fetch') {
        fetches[name] = url;
      } else if (type == 'push') {
        pushes.putIfAbsent(name, () => {}).add(url);
      }
    }
    return {
      for (final origin in {...fetches.keys, ...pushes.keys})
        origin: GitRemoteUrls(
          fetch: fetches[origin]!,
          push: pushes[origin] ?? {},
        ),
    };
  }

  /// https://git-scm.com/docs/git-remote
  Future<void> addRemote({
    required Directory repository,
    String name = 'origin',
    required String url,
    bool fetch = false,
  }) async {
    final result = await raw(
      [
        'remote',
        'add',
        if (fetch) '-f',
        name,
        url,
      ],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  /// https://git-scm.com/docs/git-remote
  Future<void> setRemote({
    required Directory repository,
    String name = 'origin',
    required String url,
    bool push = false,
    bool add = false,
    bool delete = false,
  }) async {
    final result = await raw(
      [
        'remote',
        'set-url',
        if (push) '--push',
        if (delete) '--delete',
        if (add) '--add',
        name,
        url,
      ],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  /// https://git-scm.com/docs/git-remote
  Future<void> removeRemote({
    required Directory repository,
    required String name,
  }) async {
    final result = await raw(
      [
        'remote',
        'remove',
        name,
      ],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  /// Sets (or deletes) remotes.
  ///
  /// https://git-scm.com/docs/git-remote
  Future<void> syncRemotes({
    required Directory repository,
    required Map<String, GitRemoteUrls?> remotes,
  }) async {
    final currentRemotes = await getRemotes(repository: repository);
    for (final entry in remotes.entries) {
      final remoteName = entry.key;
      final currentRemote = currentRemotes[remoteName];
      if (currentRemote == entry.value) {
        continue;
      }
      if (currentRemotes.containsKey(remoteName)) {
        // Delete existing remote
        await removeRemote(
          repository: repository,
          name: remoteName,
        );
      }
      final newRemote = entry.value;
      if (newRemote != null) {
        await addRemote(
          repository: repository,
          name: remoteName,
          url: newRemote.fetch,
        );
        final push = newRemote.push.toList();
        if (push.isNotEmpty && push.first != newRemote.fetch) {
          await setRemote(
            repository: repository,
            name: remoteName,
            url: push.first,
            push: true,
          );
        }
        for (var i = 1; i < push.length; i++) {
          await setRemote(
            repository: repository,
            name: remoteName,
            url: push.first,
            push: true,
            add: true,
          );
        }
      }
    }
  }

  /// Gets the name of the default branch for the provided repository.
  Future<String> getDefaultBranch({
    required Directory repository,
    String remote = 'origin',
  }) async {
    final fullName = await revParseSingle(
      repository: repository,
      arg: '$remote/HEAD',
      abbreviation: true,
    );
    return fullName.split('/').last;
  }

  /// https://git-scm.com/docs/git-update-index
  Future<void> assumeUnchanged({
    required Directory repository,
    required Iterable<String> files,
    bool value = true,
  }) async {
    final result = await raw(
      [
        'update-index',
        if (value) '--assume-unchanged' else '--no-assume-unchanged',
        '--',
        ...files,
      ],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  /// https://git-scm.com/docs/git-config
  Future<String?> configGet({
    required Directory repository,
    required String name,
  }) async {
    final result = await raw(
      [
        'config',
        '--get',
        name,
      ],
      directory: repository,
    );
    if (result.exitCode == 1) return null;
    _ensureSuccess(result);
    return (result.stdout as String).trim();
  }

  /// https://git-scm.com/docs/git-config
  Future<void> config({
    required Directory repository,
    required String name,
    required String value,
  }) async {
    final result = await raw(
      [
        'config',
        name,
        value,
      ],
      directory: repository,
    );
    _ensureSuccess(result);
  }

  static final provider = Provider<GitClient>((scope) {
    return GitClient(scope: scope);
  });
  static GitClient of(Scope scope) => scope.read(provider);
}

@immutable
class GitRemoteUrls {
  const GitRemoteUrls({
    required this.fetch,
    required this.push,
  });

  GitRemoteUrls.single(String url)
      : fetch = url,
        push = {url};

  final String fetch;
  final Set<String> push;

  @override
  int get hashCode => Object.hash(fetch, Object.hashAllUnordered(push));

  @override
  bool operator ==(Object other) {
    return other is GitRemoteUrls &&
        fetch == other.fetch &&
        push.length == other.push.length &&
        push.containsAll(other.push);
  }
}

final unknownSemver = Version(0, 0, 0, pre: 'unknown');

/// Version parsed from Git tags.
///
/// Mostly borrowed from https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/version.dart
class GitTagVersion {
  const GitTagVersion({
    this.x,
    this.y,
    this.z,
    this.hotfix,
    this.devVersion,
    this.devPatch,
    this.commits,
    this.hash,
    this.gitTag,
  });

  static const unknown = GitTagVersion();

  /// The X in vX.Y.Z.
  final int? x;

  /// The Y in vX.Y.Z.
  final int? y;

  /// The Z in vX.Y.Z.
  final int? z;

  /// the F in vX.Y.Z+hotfix.F.
  final int? hotfix;

  /// Number of commits since the vX.Y.Z tag.
  final int? commits;

  /// The git hash (or an abbreviation thereof) for this commit.
  final String? hash;

  /// The N in X.Y.Z-dev.N.M.
  final int? devVersion;

  /// The M in X.Y.Z-dev.N.M.
  final int? devPatch;

  /// The git tag that is this version's closest ancestor.
  final String? gitTag;

  bool get isUnknown => x == null || y == null || z == null;

  static Future<GitTagVersion> query({
    required Scope scope,
    required Directory repository,
    String gitRef = 'HEAD',
  }) async {
    final git = GitClient.of(scope);

    final tags = await git.getTagsContainingRef(
      repository: repository,
      ref: gitRef,
    );

    // Check first for a stable tag
    final RegExp stableTagPattern = RegExp(r'^\d+\.\d+\.\d+$');
    for (final String tag in tags) {
      if (stableTagPattern.hasMatch(tag.trim())) {
        return parse(tag);
      }
    }
    // Next check for a dev tag
    final RegExp devTagPattern = RegExp(r'^\d+\.\d+\.\d+-\d+\.\d+\.pre$');
    for (final String tag in tags) {
      if (devTagPattern.hasMatch(tag.trim())) {
        return parse(tag);
      }
    }

    // If we're not currently on a tag, use git describe to find the most
    // recent tag and number of commits past.
    final description = await git.describe(
      repository: repository,
      ref: gitRef,
      match: '*.*.*',
      long: true,
      tags: true,
    );
    return parse(description);
  }

  /// Parse a version string.
  ///
  /// The version string can either be an exact release tag (e.g. '1.2.3' for
  /// stable or 1.2.3-4.5.pre for a dev) or the output of `git describe` (e.g.
  /// for commit abc123 that is 6 commits after tag 1.2.3-4.5.pre, git would
  /// return '1.2.3-4.5.pre-6-gabc123').
  static GitTagVersion parse(String version) {
    final RegExp versionPattern = RegExp(
        r'^(\d+)\.(\d+)\.(\d+)(-\d+\.\d+\.pre)?(?:-(\d+)-g([a-f0-9]+))?$');
    final Match? match = versionPattern.firstMatch(version.trim());
    if (match == null) {
      return unknown;
    }

    final List<String?> matchGroups = match.groups(<int>[1, 2, 3, 4, 5, 6]);
    final int? x =
        matchGroups[0] == null ? null : int.tryParse(matchGroups[0]!);
    final int? y =
        matchGroups[1] == null ? null : int.tryParse(matchGroups[1]!);
    final int? z =
        matchGroups[2] == null ? null : int.tryParse(matchGroups[2]!);
    final String? devString = matchGroups[3];
    int? devVersion, devPatch;
    if (devString != null) {
      final Match? devMatch =
          RegExp(r'^-(\d+)\.(\d+)\.pre$').firstMatch(devString);
      final List<String?>? devGroups = devMatch?.groups(<int>[1, 2]);
      devVersion = devGroups?[0] == null ? null : int.tryParse(devGroups![0]!);
      devPatch = devGroups?[1] == null ? null : int.tryParse(devGroups![1]!);
    }
    // count of commits past last tagged version
    final int? commits =
        matchGroups[4] == null ? 0 : int.tryParse(matchGroups[4]!);
    final String? hash = matchGroups[5];

    return GitTagVersion(
      x: x,
      y: y,
      z: z,
      devVersion: devVersion,
      devPatch: devPatch,
      commits: commits,
      hash: hash,
      gitTag: '$x.$y.$z${devString ?? ''}', // e.g. 1.2.3-4.5.pre
    );
  }

  @override
  String toString() => '${toSemver()}';

  Version toSemver() {
    if (isUnknown) {
      return unknownSemver;
    } else if (commits == 0 && gitTag != null) {
      return Version.parse(gitTag!);
    } else if (hotfix != null) {
      // This is an unexpected state where untagged commits exist past a hotfix
      return Version(x!, y!, z!, build: 'hotfix.${hotfix! + 1}.pre.$commits');
    } else if (devPatch != null && devVersion != null) {
      // The next published release this commit will appear in will be a beta
      // release, thus increment [y].
      return Version(x!, y! + 1, 0, pre: '0.0.pre.$commits');
    } else {
      return Version(x!, y!, z! + 1, pre: '0.0.pre.$commits');
    }
  }
}
