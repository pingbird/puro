import 'package:meta/meta.dart';
import 'package:neoansi/neoansi.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../models.dart';
import '../command_result.dart';
import '../config.dart';
import '../git.dart';
import '../logger.dart';
import '../provider.dart';
import '../terminal.dart';
import 'command.dart';
import 'create.dart';
import 'releases.dart';

enum FlutterChannel {
  master,
  dev,
  beta,
  stable;

  static FlutterChannel? parse(String name) {
    name = name.toLowerCase();
    for (final channel in values) {
      if (channel.name == name) {
        return channel;
      }
    }
    return null;
  }
}

@immutable
class FlutterVersion {
  const FlutterVersion({
    required this.commit,
    this.version,
    this.branch,
    this.tag,
  });

  final String commit;
  final Version? version;
  final String? branch;
  final String? tag;

  @override
  String toString([OutputFormatter? format]) {
    format ??= const OutputFormatter();
    final commitStr = commit.substring(0, 10);
    String colorize(List<String> result) {
      return result
          .map(
            (e) => format!.color(
              e,
              bold: true,
              foregroundColor: Ansi8BitColor.green,
            ),
          )
          .join(' / ');
    }

    if (tag != null && tag != '$version' && tag != 'v$version') {
      return colorize(['tags/$tag', '$commitStr']);
    } else if (version != null) {
      if (branch != null) {
        return colorize(['$branch', '$version', '$commitStr']);
      } else {
        return colorize(['$version', '$commitStr']);
      }
    } else {
      return colorize([commitStr]);
    }
  }

  FlutterChannel? get channel =>
      branch == null ? null : FlutterChannel.parse(branch!);

  static Future<FlutterVersion> query({
    required Scope scope,
    String? version,
    String? channel,
    String defaultChannel = 'stable',
  }) async {
    if (version == null) {
      if (channel != null) {
        version = channel;
        channel = null;
      } else {
        version = defaultChannel;
      }
    }

    final config = PuroConfig.of(scope);
    final git = GitClient.of(scope);

    FlutterChannel? parsedChannel;

    if (channel != null) {
      parsedChannel = FlutterChannel.parse(channel);
      if (parsedChannel == null) {
        final allChannels = FlutterChannel.values.map((e) => e.name).join(', ');
        throw CommandError(
          'Invalid Flutter channel `$channel`, valid channels: $allChannels',
        );
      }
    } else {
      parsedChannel = FlutterChannel.parse(version);
    }

    final parsedVersion = tryParseVersion(version);

    // Check the official releases if a version or channel was given.
    if (parsedVersion != null || parsedChannel != null) {
      if (parsedChannel == FlutterChannel.master) {
        if (parsedVersion != null) {
          throw CommandError(
            'Unexpected version $version, the master channel does not have versions',
          );
        }
      } else {
        final release = await findFrameworkRelease(
          scope: scope,
          version: parsedVersion,
          channel: parsedChannel,
        );
        final releaseVersion = tryParseVersion(release.version);
        if (releaseVersion == null) {
          throw AssertionError(
            'Invalid version "${release.version}" in release $parsedVersion/$parsedChannel',
          );
        }
        return FlutterVersion(
          commit: release.hash,
          version: releaseVersion,
          branch: release.channel,
        );
      }
    }

    final repository = config.sharedFlutterDir;

    Future<FlutterVersion?> checkCache() async {
      // Check if it's a tag
      var result = await git.tryRevParseSingle(
        repository: repository,
        arg: 'tags/$version',
      );
      if (result != null) {
        return FlutterVersion(
          commit: result,
          tag: version,
        );
      }

      // Check if it's a commit
      result = await git.tryRevParseSingle(
        repository: repository,
        arg: '$version^{commit}',
      );
      if (result == version) {
        return FlutterVersion(commit: version!);
      }

      return null;
    }

    // Check existing cache
    var cacheResult = await checkCache();
    if (cacheResult != null) return cacheResult;

    // Fetch the framework to scan it
    final sharedRepository = config.sharedFlutterDir;
    await fetchOrCloneShared(
      scope: scope,
      repository: sharedRepository,
      remoteUrl: config.flutterGitUrl,
    );

    // Check if it's in origin
    final result = await git.tryRevParseSingle(
      repository: sharedRepository,
      arg: 'origin/$version', // look at origin since it may be untracked
    );
    if (result != null) {
      final isBranch = await git.checkBranchExists(
        repository: sharedRepository,
        branch: 'origin/$version',
      );
      return FlutterVersion(
        commit: result,
        branch: isBranch ? version : null,
      );
    }

    // Check again after fetching
    cacheResult = await checkCache();
    if (cacheResult != null) return cacheResult;

    throw CommandError(
      'Could not find flutter version from `$version`, expected a valid '
      'commit, branch, tag, or version.',
    );
  }

  FlutterVersionModel toModel() {
    return FlutterVersionModel(
      commit: commit,
      version: version?.toString(),
      branch: branch,
      tag: tag,
    );
  }

  static FlutterVersion fromModel(FlutterVersionModel model) {
    return FlutterVersion(
      commit: model.commit,
      version: model.hasVersion() ? Version.parse(model.version) : null,
      branch: model.hasBranch() ? model.branch : null,
      tag: model.hasTag() ? model.tag : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlutterVersion &&
        other.commit == commit &&
        other.version == version &&
        other.branch == branch &&
        other.tag == tag;
  }

  @override
  int get hashCode => Object.hash(commit, version, branch, tag);
}

Future<FlutterVersion?> getEnvironmentFlutterVersion({
  required Scope scope,
  required EnvConfig environment,
}) async {
  final git = GitClient.of(scope);
  final flutterConfig = environment.flutter;
  final versionFile = flutterConfig.versionFile;
  final commit = await git.tryGetCurrentCommitHash(
    repository: flutterConfig.sdkDir,
  );
  if (commit == null) {
    return null;
  }
  if (!versionFile.existsSync()) {
    await runOptional(
      scope,
      'querying Flutter version for `${environment.name}`',
      () {
        return runFlutterCommand(
          scope: scope,
          environment: environment,
          args: ['--version', '--machine'],
          onStdout: (_) {},
          onStderr: (_) {},
        );
      },
    );
  }
  Version? version;
  if (versionFile.existsSync()) {
    version = tryParseVersion(versionFile.readAsStringSync().trim());
  }
  final branch = await git.getBranch(repository: flutterConfig.sdkDir);
  return FlutterVersion(
    commit: commit,
    version: version,
    branch: branch,
  );
}
