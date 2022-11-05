import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:pub_semver/pub_semver.dart';

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

  /// Returns true if the provided branch name exists.
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

  /// Gets all of the names of tags containing the provided ref.
  ///
  /// https://git-scm.com/docs/git-tag
  Future<List<String>> getTagsContainingRef({
    required Directory repository,
    required String ref,
  }) async {
    final result = await _git(
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
    final result = await _git(
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

  static final provider = Provider<GitClient>((scope) {
    return GitClient(scope: scope);
  });
  static GitClient of(Scope scope) => scope.read(provider);
}

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
      return Version(0, 0, 0, pre: 'unknown');
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
