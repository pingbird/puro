import 'dart:math';

import 'package:clock/clock.dart';
import 'package:neoansi/neoansi.dart';
import 'package:pub_semver/pub_semver.dart';

import '../command.dart';
import '../command_result.dart';
import '../config.dart';
import '../env/releases.dart';
import '../extensions.dart';
import '../proto/flutter_releases.pb.dart';
import '../terminal.dart';

class LsVersionsCommand extends PuroCommand {
  @override
  final name = 'ls-versions';

  @override
  List<String> get aliases => ['releases', 'ls-releases'];

  @override
  final description = 'Lists available Flutter versions';

  @override
  Future<CommandResult> run() async {
    final flutterVersions =
        await getCachedFlutterReleases(scope: scope, unlessStale: true) ??
            await fetchFlutterReleases(scope: scope);

    final parsedVersions = <String, Version>{};
    final sortedReleases = flutterVersions.releases.toList()
      ..sort((a, b) {
        return parsedVersions
            .putIfAbsent(b.version, () => tryParseVersion(b.version)!)
            .compareTo(parsedVersions.putIfAbsent(
                a.version, () => tryParseVersion(a.version)!));
      });
    final now = clock.now();

    List<FlutterReleaseModel> latestReleasesFor(String channel) {
      final releases = <FlutterReleaseModel>[];
      final candidates = sortedReleases.where((e) => e.channel == channel);
      Version? lastVersion;
      for (final release in candidates) {
        final version = parsedVersions[release.version]!;
        final isPreviousPatch = lastVersion != null &&
            version.major == lastVersion.major &&
            version.minor == lastVersion.minor;
        lastVersion = version;
        if (releases.length >= 5 && isPreviousPatch) {
          continue;
        }
        releases.add(release);
        if (releases.length >= 10) break;
      }
      return releases;
    }

    final channelReleases = <String, List<FlutterReleaseModel>>{
      'stable': latestReleasesFor('stable'),
      'beta': latestReleasesFor('beta'),
    };

    return BasicMessageResult.format(
      success: true,
      message: (format) {
        List<List<String>> formatReleases(List<FlutterReleaseModel> releases) {
          return [
            for (final release in releases)
              [
                'Flutter ${release.version}',
                format.color(' | ', foregroundColor: Ansi8BitColor.grey),
                DateTime.parse(release.releaseDate).difference(now).pretty(
                      before: '',
                      abbr: true,
                    ),
                format.color(' | ', foregroundColor: Ansi8BitColor.grey),
                release.hash.substring(0, 10),
                format.color(' | ', foregroundColor: Ansi8BitColor.grey),
                'Dart ${release.dartSdkVersion.split(' ').first}',
              ],
          ];
        }

        final formattedReleases = <String, List<List<String>>>{
          for (final entry in channelReleases.entries)
            entry.key: formatReleases(entry.value),
        };

        final colWidths = List.generate(
          formattedReleases.values.first.first.length,
          (index) {
            return formattedReleases.values.fold<int>(0, (n, rows) {
              return max(
                  n,
                  rows.fold(0,
                      (n, row) => max(n, stripAnsiEscapes(row[index]).length)));
            });
          },
        );

        return [
          for (final entry in formattedReleases.entries) ...[
            'Latest ${entry.key} releases:',
            for (final row in entry.value)
              '${row.mapWithIndex((s, i) => padRightColored(s, colWidths[i])).join()}',
            '',
          ],
        ].join('\n').trim();
      },
      type: CompletionType.info,
    );
  }
}
