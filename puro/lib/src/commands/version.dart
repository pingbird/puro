import 'dart:io';

import '../command.dart';
import '../install/profile.dart';
import '../terminal.dart';
import '../version.dart';

class VersionCommand extends PuroCommand {
  VersionCommand() {
    argParser.addFlag(
      'plain',
      negatable: false,
      help: 'Print just the version to stdout and exit',
    );
    argParser.addFlag(
      'release',
      negatable: false,
    );
  }

  @override
  String get name => 'version';

  @override
  String get description => 'Prints version information';

  @override
  Future<CommandResult> run() async {
    final plain = argResults!['plain'] as bool;
    final version = await getPuroVersion(scope: scope);
    if (plain) {
      Terminal.of(scope).flushStatus();
      await stderr.flush();
      stdout.write('$version');
      await runner.exitPuro(0);
    }
    final externalMessage =
        await detectExternalFlutterInstallations(scope: scope);
    final updateMessage = await checkIfUpdateAvailable(
      scope: scope,
      runner: runner,
      alwaysNotify: true,
    );
    return BasicMessageResult.list(
      success: true,
      messages: [
        if (externalMessage != null) externalMessage,
        if (updateMessage != null) updateMessage,
        CommandMessage(
          (format) => 'Puro $version\n'
              'Dart ${Platform.version}\n'
              '${Platform.operatingSystemVersion}',
          type: CompletionType.info,
        ),
      ],
    );
  }
}
