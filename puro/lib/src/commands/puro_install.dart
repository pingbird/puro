import 'dart:io';

import 'package:file/file.dart';

import '../command.dart';
import '../config.dart';
import '../extensions.dart';
import '../file_lock.dart';
import '../provider.dart';
import '../version.dart';

class PuroInstallCommand extends PuroCommand {
  @override
  final name = 'install-puro';

  @override
  bool get hidden => true;

  @override
  final description = 'Finishes installation of the puro tool.';

  @override
  Future<CommandResult> run() async {
    final version = await getPuroVersion(scope: scope);
    final config = PuroConfig.of(scope);
    final profile = await tryUpdateProfile(scope: scope);
    final homeDir = config.homeDir.path;
    final profilePath = profile?.path.replaceAll(homeDir, '~');
    final scriptPath = Platform.script.toFilePath().replaceAll(homeDir, '~');
    return BasicMessageResult.list(
      success: true,
      messages: [
        if (profile != null)
          CommandMessage(
            (format) => 'Updated PATH in $profilePath',
          ),
        CommandMessage(
          (format) => 'Successfully installed Puro $version at $scriptPath',
        ),
      ],
    );
  }
}

const _kProfileComment = '# Added by Puro';

Future<File?> tryUpdateProfile({
  required Scope scope,
}) async {
  final config = PuroConfig.of(scope);
  final file = detectProfile(scope: scope);
  if (file == null) {
    return null;
  }
  final home = config.homeDir.path;
  final bin = config.binDir.path.replaceAll(home, '\$HOME');
  final export = 'export PATH="\$PATH:$bin" $_kProfileComment';
  return await lockFile(
    scope,
    file,
    (handle) async {
      final contents = await handle.readAllAsString();
      if (contents.contains(export)) {
        // Already exported
        return null;
      }
      final lines = contents.split('\n');
      lines.removeWhere((e) => e.endsWith(_kProfileComment));
      lines.add(export);
      await handle.writeAllString(lines.join('\n'));
      return file;
    },
    mode: FileMode.append,
  );
}

File? detectProfile({required Scope scope}) {
  final config = PuroConfig.of(scope);
  final homeDir = config.homeDir;
  const bashProfiles = {
    '.profile',
    '.bash_profile',
    '.bashrc',
  };
  const zshProfiles = {
    '.zprofile',
    '.zshrc',
  };
  final profiles = <String>{};
  final shell = Platform.environment['SHELL'] ?? '';
  if (shell.endsWith('/bash')) {
    profiles.addAll(bashProfiles);
    profiles.addAll(zshProfiles);
  } else if (shell.endsWith('/zsh')) {
    profiles.addAll(zshProfiles);
    profiles.addAll(bashProfiles);
  } else {
    return null;
  }
  for (final name in profiles) {
    final file = homeDir.childFile(name);
    if (file.existsSync()) {
      return file;
    }
  }
  return null;
}
