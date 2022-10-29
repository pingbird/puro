import 'dart:io';

import '../command.dart';
import '../terminal.dart';
import '../version.dart';

class VersionCommand extends PuroCommand {
  VersionCommand() {
    argParser.addFlag(
      'plain',
      negatable: false,
    );
    argParser.addFlag(
      'release',
      negatable: false,
    );
  }

  @override
  String get name => 'version';

  @override
  String get description => 'Prints version information.';

  @override
  Future<CommandResult> run() async {
    final plain = argResults!['plain'] as bool;
    final release = argResults!['release'] as bool;
    final version = await getPuroVersion(
      scope: scope,
      withCommit: !release,
    );
    if (plain) {
      return BasicMessageResult(
        success: version != null,
        message: '${version ?? 'unknown'}',
        type: CompletionType.plain,
      );
    }
    return BasicMessageResult(
      success: true,
      message: 'Puro ${version ?? 'unknown'}\n'
          'Dart ${Platform.version}\n'
          '${Platform.operatingSystemVersion}',
      type: CompletionType.info,
    );
  }
}
