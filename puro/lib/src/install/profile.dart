import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:neoansi/neoansi.dart';

import '../command_result.dart';
import '../config.dart';
import '../extensions.dart';
import '../file_lock.dart';
import '../logger.dart';
import '../process.dart';
import '../provider.dart';
import '../string_utils.dart';
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

  final defaultEnvBinDir =
      config.getEnv('default', resolve: false).flutter.binDir.path;
  offending.removeWhere((e) => path.equals(path.dirname(e), defaultEnvBinDir));

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

Future<File?> findProfileFile({
  required Scope scope,
  String? profileOverride,
}) async {
  final config = PuroConfig.of(scope);
  return profileOverride == null
      ? await detectProfile(scope: scope)
      : config.fileSystem.file(profileOverride).absolute;
}

Future<bool> updateProfile({
  required Scope scope,
  required File file,
  required Iterable<String> lines,
}) {
  final export = lines.map((e) => '$e $_kProfileComment').join('\n');
  return lockFile(
    scope,
    file,
    (handle) async {
      final contents = await handle.readAllAsString();
      if (export.isNotEmpty && contents.contains(export)) {
        // Already exported
        return false;
      }
      final lines = contents.split('\n');
      final originalLines = lines.length;
      lines.removeWhere((e) => e.endsWith(_kProfileComment));
      if (export.isEmpty && lines.length == originalLines) {
        // Not exporting anything
        return false;
      }
      while (lines.isNotEmpty && lines.last.isEmpty) {
        lines.removeLast();
      }
      lines.add('');
      lines.add(export);
      await handle.writeAllString('${lines.join('\n')}\n');
      return true;
    },
    mode: FileMode.append,
  );
}

Future<File?> installProfileEnv({
  required Scope scope,
  String? profileOverride,
}) async {
  final log = PuroLogger.of(scope);
  final config = PuroConfig.of(scope);
  final file = await findProfileFile(scope: scope);
  log.d('detected profile: ${file?.path}');
  if (file == null) {
    return null;
  }
  final home = config.homeDir.path;
  final result = await updateProfile(
    scope: scope,
    file: file,
    lines: [
      for (final path in config.desiredEnvPaths)
        'export PATH="\$PATH:${path.replaceAll(home, '\$HOME')}"',
      'export PURO_ROOT="${config.puroRoot.path}"',
      'export PUB_CACHE="${config.pubCacheDir.path}"'
    ],
  );
  return result ? file : null;
}

Future<File?> uninstallProfileEnv({
  required Scope scope,
  String? profileOverride,
}) async {
  final log = PuroLogger.of(scope);
  final file = await findProfileFile(scope: scope);
  log.d('detected profile: ${file?.path}');
  if (file == null) {
    return null;
  }
  final result = await updateProfile(
    scope: scope,
    file: file,
    lines: [],
  );
  return result ? file : null;
}

Future<File?> detectProfile({required Scope scope}) async {
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);
  final homeDir = config.homeDir;
  final home = homeDir.path;
  final bashEnv = Platform.environment['BASH_ENV'];
  final path = config.fileSystem.path;
  final bashProfiles = {
    if (bashEnv != null && bashEnv.isNotEmpty) bashEnv,
    path.join(home, '.profile'),
    path.join(home, '.bash_profile'),
    path.join(home, '.bashrc'),
  };
  final zshProfiles = {
    path.join(home, '.zprofile'),
    path.join(home, '.zshrc'),
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
    log.d('Using process tree to detect shell');
    final processes = await getParentProcesses(scope: scope);
    final shell = processes.firstWhereOrNull(
      (e) => e.name == 'bash' || e.name == 'zsh',
    );
    if (shell?.name == 'bash') {
      profiles.addAll(bashProfiles);
      profiles.addAll(zshProfiles);
    } else if (shell?.name == 'zsh') {
      profiles.addAll(zshProfiles);
      profiles.addAll(bashProfiles);
    }
  }
  for (final name in profiles) {
    final file = config.fileSystem.file(name);
    if (file.existsSync()) {
      return file;
    }
  }
  return profiles.isEmpty ? null : homeDir.childFile(profiles.first);
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

Future<bool> deleteWindowsRegistryValue({
  required Scope scope,
  required String key,
  required String valueName,
  bool elevated = false,
}) async {
  final args = [
    'delete',
    key,
    '/v',
    valueName,
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
    log.w(
        'reg delete failed with exit code ${result.exitCode}\n${result.stderr}');
  }
  return result.exitCode == 0;
}

Future<bool> tryUpdateWindowsEnv({
  required Scope scope,
  required Map<String, String> env,
}) async {
  var result = false;
  for (final entry in env.entries) {
    final currentValue = await readWindowsRegistryValue(
      scope: scope,
      key: 'HKEY_CURRENT_USER\\Environment',
      valueName: entry.key,
    );
    if (currentValue == entry.value) {
      continue;
    }
    await writeWindowsRegistryValue(
      scope: scope,
      key: 'HKEY_CURRENT_USER\\Environment',
      valueName: entry.key,
      value: entry.value,
    );
    result = true;
  }
  return result;
}

Future<bool> tryDeleteWindowsEnv({
  required Scope scope,
  required String name,
  required String? value,
}) async {
  if (value != null) {
    final currentValue = await readWindowsRegistryValue(
      scope: scope,
      key: 'HKEY_CURRENT_USER\\Environment',
      valueName: name,
    );
    if (currentValue != value) {
      return false;
    }
  }
  return await deleteWindowsRegistryValue(
    scope: scope,
    key: 'HKEY_CURRENT_USER\\Environment',
    valueName: name,
  );
}

Future<bool> tryUpdateWindowsPath({
  required Scope scope,
}) async {
  final config = PuroConfig.of(scope);

  final env = <String, String>{
    'PURO_ROOT': config.puroRoot.path,
    'PUB_CACHE': config.pubCacheDir.path,
  };

  final currentPath = await readWindowsRegistryValue(
    scope: scope,
    key: 'HKEY_CURRENT_USER\\Environment',
    valueName: 'Path',
  );
  final paths = (currentPath ?? '').split(';');
  if (config.desiredEnvPaths.any((e) => !paths.contains(e))) {
    while (paths.isNotEmpty && paths.last.isEmpty) paths.removeLast();
    paths.removeWhere(config.desiredEnvPaths.contains);
    paths.addAll(config.desiredEnvPaths);
    env['Path'] = paths.join(';');
  }

  return await tryUpdateWindowsEnv(
    scope: scope,
    env: env,
  );
}

Future<bool> tryCleanWindowsPath({
  required Scope scope,
}) async {
  final config = PuroConfig.of(scope);
  final currentPath = await readWindowsRegistryValue(
    scope: scope,
    key: 'HKEY_CURRENT_USER\\Environment',
    valueName: 'Path',
  );
  final paths = (currentPath ?? '').split(';');
  paths.removeWhere(config.desiredEnvPaths.contains);

  var result = await tryUpdateWindowsEnv(
    scope: scope,
    env: {'Path': paths.join(';')},
  );

  if (await tryDeleteWindowsEnv(
    scope: scope,
    name: 'PURO_ROOT',
    value: config.puroRoot.path,
  )) {
    result = true;
  }

  if (await tryDeleteWindowsEnv(
    scope: scope,
    name: 'PUB_CACHE',
    value: config.pubCacheDir.path,
  )) {
    result = true;
  }

  return result;
}
