import 'dart:io';

import '../command.dart';
import '../config.dart';
import '../install/bin.dart';
import '../install/profile.dart';
import '../version.dart';

class PuroInstallCommand extends PuroCommand {
  PuroInstallCommand() {
    argParser.addFlag(
      'force',
      help: 'Overwrite an existing puro installation, if any',
      negatable: false,
    );
    argParser.addFlag(
      'path',
      help: 'Whether or not to update the PATH automatically',
    );
  }

  @override
  final name = 'install-puro';

  @override
  bool get hidden => true;

  @override
  final description = 'Finishes installation of the puro tool';

  @override
  bool get allowUpdateCheck => false;

  @override
  Future<CommandResult> run() async {
    final puroVersion = await PuroVersion.of(scope);
    final config = PuroConfig.of(scope);

    final force = argResults!['force'] as bool;
    final updatePath =
        argResults!.wasParsed('path') ? argResults!['path'] as bool : null;

    await ensurePuroInstalled(scope: scope, force: force);

    // Update the path by default if this is a distribution install.
    String? profilePath;
    var updatedWindowsRegistry = false;
    final homeDir = config.homeDir.path;
    if (updatePath ?? puroVersion.type == PuroInstallationType.distribution) {
      if (Platform.isLinux || Platform.isMacOS) {
        final profile = await tryUpdateProfile(scope: scope);
        profilePath = profile?.path.replaceAll(homeDir, '~');
      } else if (Platform.isWindows) {
        updatedWindowsRegistry = await tryUpdateWindowsPath(
          scope: scope,
        );
      }
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
        if (profilePath != null)
          CommandMessage(
            (format) => 'Updated PATH in $profilePath',
          ),
        if (updatedWindowsRegistry)
          CommandMessage(
            (format) => 'Updated PATH in windows registry',
          ),
        CommandMessage(
          (format) =>
              'Successfully installed Puro ${puroVersion.semver} to `${config.puroRoot.path}`',
        ),
      ],
    );
  }
}
