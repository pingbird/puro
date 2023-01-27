import 'dart:io';

import 'package:file/file.dart';
import 'package:neoansi/neoansi.dart';

import '../command_result.dart';
import '../config.dart';
import '../extensions.dart';
import '../file_lock.dart';
import '../logger.dart';
import '../process.dart';
import '../provider.dart';
import '../terminal.dart';
import '../version.dart';

Future<CommandMessage?> detectExternalFlutterInstallations({
  required Scope scope,
}) async {
  final config = PuroConfig.of(scope);
  final path = config.fileSystem.path;
  final log = PuroLogger.of(scope);

  final puroVersion = await PuroVersion.of(scope);

  // Ignore conflicts if this is a standalone / development / pub install.
  if (puroVersion.type != PuroInstallationType.distribution) {
    return null;
  }

  final dartFiles = await findProgramInPath(
    scope: scope,
    name: config.buildTarget.dartName,
  );

  final flutterFiles = await findProgramInPath(
    scope: scope,
    name: config.buildTarget.flutterName,
  );

  final puroFiles = await findProgramInPath(
    scope: scope,
    name: config.puroExecutableFile.basename,
  );

  final offending = {
    ...dartFiles.map((e) => e.path),
    ...flutterFiles.map((e) => e.path),
    ...puroFiles.map((e) => e.path),
  };

  offending.remove(config.puroDartShimFile.path);
  offending.remove(config.puroFlutterShimFile.path);
  offending.remove(config.puroExecutableFile.path);

  final defaultEnvBinDir = config.getEnv('default').flutter.binDir.path;
  offending.removeWhere((e) => path.basename(e) == defaultEnvBinDir);

  log.d('defaultEnvBinDir: $defaultEnvBinDir');
  log.d('PATH: ${Platform.environment['PATH']}');
  log.d('puroDartShimFile: ${config.puroDartShimFile.path}');
  log.d('puroFlutterShimFile: ${config.puroFlutterShimFile.path}');

  if (offending.isNotEmpty) {
    return CommandMessage.format(
      (format) => 'Other Flutter or Dart installations detected\n'
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
  String? profileOverride,
}) async {
  final config = PuroConfig.of(scope);
  final file = profileOverride == null
      ? detectProfile(scope: scope)
      : config.fileSystem.file(profileOverride).absolute;
  if (file == null) {
    return null;
  }
  final home = config.homeDir.path;
  final export = [
    for (final path in config.desiredEnvPaths)
      'export PATH="\$PATH:${path.replaceAll(home, '\$HOME')}"',
    'export PURO_ROOT="${config.puroRoot.path}"',
    'export PUB_CACHE="${config.pubCacheDir.path}"'
  ].map((e) => '$e $_kProfileComment').join('\n');
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
  final stdout = (result.stdout as String).replaceAll('\r\n', '\n');
  return [
    for (final line in stdout.split('\n'))
      if (line.trim().isNotEmpty) config.fileSystem.file(line),
  ];
}

Future<String?> readWindowsRegistryValue({
  required Scope scope,
  required String key,
  required String valueName,
}) async {
  // This is horrible.
  final result = await runProcess(
    scope,
    'reg',
    ['query', key, '/v', valueName],
  );
  if (result.exitCode != 0) {
    return null;
  }
  final lines =
      (result.stdout as String).replaceAll('\r\n', '\n').trim().split('\n');
  if (lines.length != 2) {
    return null;
  }
  final line = lines[1];
  final match = RegExp('REG_(\\S+)    ').firstMatch(line);
  if (match == null) {
    return null;
  }
  return line.substring(match.end);
}

String escapePowershellString(String str) => str
    .replaceAll('`', '``')
    .replaceAll('"', '`"')
    .replaceAll('\$', '`\$')
    .replaceAll('\x00', '`0')
    .replaceAll('\x07', '`a')
    .replaceAll('\b', '`b')
    .replaceAll('\x1b', '`e')
    .replaceAll('\f', '`f')
    .replaceAll('\n', '`n')
    .replaceAll('\r', '`r')
    .replaceAll('\t', '`t')
    .replaceAll('\v', '`v');

Future<bool> writeWindowsRegistryValue({
  required Scope scope,
  required String key,
  required String valueName,
  required String value,
  bool elevated = false,
}) async {
  final args = [
    'add',
    key,
    '/v',
    valueName,
    '/t',
    'REG_EXPAND_SZ',
    '/d',
    value,
    '/f',
  ];

  final log = PuroLogger.of(scope);
  final ProcessResult result;
  if (elevated) {
    result = await runProcess(
      scope,
      'powershell',
      [
        '-command',
        ('Start-Process reg -Wait -Verb runAs -ArgumentList '
            '${args.map(escapePowershellString).map((e) => '"$e"').join(',')}'),
      ],
    );
  } else {
    result = await runProcess(scope, 'reg', args);
  }
  if (result.exitCode != 0) {
    log.w('reg add failed with exit code ${result.exitCode}\n${result.stderr}');
  }
  return result.exitCode == 0;
}

Future<bool> tryUpdateWindowsPath({
  required Scope scope,
}) async {
  final currentPath = await readWindowsRegistryValue(
    scope: scope,
    key: 'HKEY_CURRENT_USER\\Environment',
    valueName: 'Path',
  );
  final config = PuroConfig.of(scope);
  final paths = (currentPath ?? '').split(';');
  if (!config.desiredEnvPaths.any((e) => !paths.contains(e))) {
    // Already has all of our paths
    return false;
  }
  while (paths.isNotEmpty && paths.last.isEmpty) paths.removeLast();
  paths.removeWhere(config.desiredEnvPaths.contains);
  paths.addAll(config.desiredEnvPaths);
  await writeWindowsRegistryValue(
    scope: scope,
    key: 'HKEY_CURRENT_USER\\Environment',
    valueName: 'Path',
    value: paths.join(';'),
  );
  await writeWindowsRegistryValue(
    scope: scope,
    key: 'HKEY_CURRENT_USER\\Environment',
    valueName: 'PURO_ROOT',
    value: config.puroRoot.path,
  );
  await writeWindowsRegistryValue(
    scope: scope,
    key: 'HKEY_CURRENT_USER\\Environment',
    valueName: 'PUB_CACHE',
    value: config.pubCacheDir.path,
  );
  return true;
}
