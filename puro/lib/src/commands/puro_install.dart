import 'dart:io';

import '../command.dart';
import '../config.dart';
import '../install/profile.dart';
import '../install/shims.dart';
import '../version.dart';

class PuroInstallCommand extends PuroCommand {
  PuroInstallCommand() {
    argParser.addFlag(
      'force',
      hide: true,
      negatable: false,
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
    final version = await getPuroVersion(scope: scope);
    final config = PuroConfig.of(scope);

    final force = argResults!['force'] as bool;

    final currentExecutable =
        config.fileSystem.file(Platform.resolvedExecutable);
    if (!force && currentExecutable.path != config.puroExecutableFile.path) {
      return BasicMessageResult(
        success: false,
        message: 'Installing standalone executables is not supported',
      );
    }

    final homeDir = config.homeDir.path;
    final scriptPath = Platform.script.toFilePath().replaceAll(homeDir, '~');
    String? profilePath;
    var updatedWindowsRegistry = false;
    if (Platform.isLinux || Platform.isMacOS) {
      final profile = await tryUpdateProfile(scope: scope);
      profilePath = profile?.path.replaceAll(homeDir, '~');
    } else if (Platform.isWindows) {
      updatedWindowsRegistry = await tryUpdateWindowsPath(
        scope: scope,
      );
    }

    await installShims(scope: scope);

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
          (format) => 'Successfully installed Puro $version to $scriptPath',
        ),
      ],
    );
  }
}
