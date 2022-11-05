import 'dart:io';

import 'package:file/file.dart';
import 'package:neoansi/neoansi.dart';

import '../command.dart';
import '../config.dart';
import '../extensions.dart';
import '../file_lock.dart';
import '../logger.dart';
import '../process.dart';
import '../provider.dart';
import '../terminal.dart';

Future<CommandMessage?> detectExternalFlutterInstallations({
  required Scope scope,
}) async {
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);

  final dartFiles = await findProgramInPath(
    scope: scope,
    name: config.buildTarget.dartName,
  );

  final flutterFiles = await findProgramInPath(
    scope: scope,
    name: config.buildTarget.flutterName,
  );

  final offending = {
    ...dartFiles.map((e) => e.path),
    ...flutterFiles.map((e) => e.path),
  };

  offending.remove(config.puroDartShimFile.path);
  offending.remove(config.puroFlutterShimFile.path);

  log.d('PATH: ${Platform.environment['PATH']}');
  log.d('puroDartShimFile: ${config.puroDartShimFile.path}');
  log.d('puroFlutterShimFile: ${config.puroFlutterShimFile.path}');

  if (offending.isNotEmpty) {
    return CommandMessage(
      (format) => 'Other flutter/dart installations detected\n'
          'Puro recommends removing the following from your PATH:\n'
          '${offending.map((e) => '${format.color(
                '*',
                bold: true,
                foregroundColor: Ansi8BitColor.red,
              )} $e').join('\n')}',
      type: CompletionType.alert,
    );
  } else {
    return null;
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
      while (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
      lines.add('');
      lines.add(export);
      await handle.writeAllString('${lines.join('\n')}\n');
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

Future<List<File>> findProgramInPath({
  required Scope scope,
  required String name,
}) async {
  final config = PuroConfig.of(scope);
  final ProcessResult result;
  if (Platform.isWindows) {
    result = await runProcess(scope, 'where', [name]);
  } else {
    result = await runProcess(scope, 'which', ['-a', name]);
  }
  return [
    for (final line in (result.stdout as String).trim().split('\n'))
      config.fileSystem.file(line),
  ];
}
