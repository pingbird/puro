import 'dart:io';

import '../command.dart';
import '../command_result.dart';
import '../config.dart';
import '../install/profile.dart';
import '../version.dart';

class PuroUninstallCommand extends PuroCommand {
  PuroUninstallCommand() {
    argParser.addFlag(
      'force',
      help:
          'Ignore the current installation method and attempt to uninstall anyway',
      negatable: false,
    );
    argParser.addOption(
      'profile',
      help:
          'Overrides the profile script puro appends to when updating the PATH',
    );
  }

  @override
  final name = 'uninstall-puro';

  @override
  final description = 'Uninstalls puro from the system';

  @override
  bool get allowUpdateCheck => false;

  @override
  Future<CommandResult> run() async {
    final puroVersion = await PuroVersion.of(scope);
    final config = PuroConfig.of(scope);
    final force = argResults!['force'] as bool;

    if (puroVersion.type != PuroInstallationType.distribution && !force) {
      throw CommandError(
        'Can only uninstall puro when installed normally, use --force to ignore\n'
        '${puroVersion.type.description}',
      );
    }

    final prefs = await readGlobalPrefs(scope: scope);

    String? profilePath;
    var updatedWindowsRegistry = false;
    final homeDir = config.homeDir.path;
    if (Platform.isLinux || Platform.isMacOS) {
      final profile = await uninstallProfileEnv(
        scope: scope,
        profileOverride:
            prefs.hasProfileOverride() ? prefs.profileOverride : null,
      );
      profilePath = profile?.path.replaceAll(homeDir, '~');
    } else if (Platform.isWindows) {
      updatedWindowsRegistry = await tryCleanWindowsPath(
        scope: scope,
      );
    }

    if (profilePath == null && !updatedWindowsRegistry) {
      throw CommandError('Could not find Puro in PATH, is it still installed?');
    }

    return BasicMessageResult.list([
      if (profilePath != null)
        CommandMessage(
            'Removed Puro from PATH in $profilePath, reopen your terminal for it to take effect'),
      if (updatedWindowsRegistry)
        CommandMessage(
          'Removed Puro from PATH in the Windows registry, reopen your terminal for it to take effect',
        ),
      CommandMessage.format(
        (format) => Platform.isWindows
            ? 'To remove environments and settings completely, delete \'${config.puroRoot.path}\'`'
            : 'To remove environments and settings completely, run rm -r \'${config.puroRoot.path}\'',
      ),
    ]);
  }
}
