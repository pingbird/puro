import 'dart:io';

import '../command_result.dart';
import '../config.dart';
import '../provider.dart';
import 'command.dart';

const Set<String> preparePlatformOptions = {
  'android',
  'ios',
  'linux',
  'macos',
  'windows',
  'web',
  'fuchsia',
};

const List<String> _platformOrder = [
  'android',
  'ios',
  'macos',
  'linux',
  'windows',
  'web',
  'fuchsia',
];

List<String> sortPreparePlatforms(Iterable<String> platforms) {
  final platformSet = platforms.toSet();
  return _platformOrder.where(platformSet.contains).toList();
}

List<String> defaultPreparePlatforms() {
  final platforms = <String>{'android', 'web'};
  if (Platform.isMacOS) {
    platforms
      ..add('ios')
      ..add('macos');
  }
  if (Platform.isLinux) {
    platforms.add('linux');
  }
  if (Platform.isWindows) {
    platforms.add('windows');
  }
  return sortPreparePlatforms(platforms);
}

Future<void> prepareEnvironment({
  required Scope scope,
  required EnvConfig environment,
  List<String>? platforms,
  bool allPlatforms = false,
  bool force = false,
}) async {
  final effectivePlatforms = platforms == null
      ? const <String>[]
      : sortPreparePlatforms(platforms);
  final args = <String>['precache'];
  if (force) {
    args.add('--force');
  }
  if (allPlatforms) {
    args.add('--all-platforms');
  }
  for (final platform in effectivePlatforms) {
    args.add('--$platform');
  }
  final exitCode = await runFlutterCommand(
    scope: scope,
    environment: environment,
    args: args,
    mode: ProcessStartMode.inheritStdio,
  );
  if (exitCode != 0) {
    throw CommandError(
      '`flutter ${args.join(' ')}` failed with exit code $exitCode',
    );
  }
}
