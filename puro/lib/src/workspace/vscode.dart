import 'package:file/file.dart';

import '../config.dart';
import '../extensions.dart';
import '../json_edit/editor.dart';
import '../logger.dart';
import '../process.dart';
import '../provider.dart';
import 'common.dart';

class VSCodeConfig extends IdeConfig {
  VSCodeConfig({
    required super.workspaceDir,
    required super.projectConfig,
    super.flutterSdkDir,
    super.dartSdkDir,
    required super.exists,
  });

  late final configDir = workspaceDir.childDirectory('.vscode');
  late final settingsFile = configDir.childFile('settings.json');

  @override
  String get name => 'VSCode';

  JsonEditor readSettings() {
    if (!settingsFile.existsSync()) {
      return JsonEditor(source: '{}', indentLevel: 4);
    }
    final source = settingsFile.readAsStringSync();
    return JsonEditor(source: source.isEmpty ? '{}' : source, indentLevel: 4);
  }

  static const flutterSdkDirKey = 'dart.flutterSdkPath';
  static const dartSdkDirKey = 'dart.sdkPath';

  @override
  Future<void> backup({required Scope scope}) async {
    final config = PuroConfig.of(scope);
    final dotfile = projectConfig.readDotfileForWriting();
    var changedDotfile = false;
    if (flutterSdkDir != null &&
        !flutterSdkDir!.parent.parent.pathEquals(config.envsDir) &&
        !dotfile.hasPreviousFlutterSdk()) {
      dotfile.previousFlutterSdk = flutterSdkDir!.path;
      changedDotfile = true;
    }
    if (dartSdkDir != null &&
        dartSdkDir!.existsSync() &&
        !dartSdkDir!.resolve().parent.parent.resolvedPathEquals(
          config.sharedCachesDir,
        ) &&
        !dotfile.hasPreviousDartSdk()) {
      dotfile.previousDartSdk = dartSdkDir!.path;
      changedDotfile = true;
    }
    if (changedDotfile) {
      await projectConfig.writeDotfile(scope, dotfile);
    }
  }

  @override
  Future<void> restore({required Scope scope}) async {
    final config = PuroConfig.of(scope);
    final dotfile = projectConfig.readDotfileForWriting();
    var changedDotfile = false;
    if (dotfile.hasPreviousFlutterSdk()) {
      flutterSdkDir = config.fileSystem.directory(dotfile.previousFlutterSdk);
      dotfile.clearPreviousFlutterSdk();
      changedDotfile = true;
    } else {
      flutterSdkDir = null;
    }
    if (dotfile.hasPreviousDartSdk()) {
      dartSdkDir = config.fileSystem.directory(dotfile.previousDartSdk);
      dotfile.clearPreviousDartSdk();
      changedDotfile = true;
    } else {
      dartSdkDir = null;
    }
    if (changedDotfile) {
      await projectConfig.writeDotfile(scope, dotfile);
    }
    return save(scope: scope);
  }

  @override
  Future<void> save({required Scope scope}) async {
    final log = PuroLogger.of(scope);
    final editor = readSettings();

    if (flutterSdkDir == null) {
      editor.remove([flutterSdkDirKey]);
    } else {
      editor.update([flutterSdkDirKey], flutterSdkDir?.path);
    }

    if (dartSdkDir == null) {
      editor.remove([dartSdkDirKey]);
    } else {
      editor.update([dartSdkDirKey], dartSdkDir?.path);
    }

    if (editor.query([flutterSdkDirKey])?.value.toJson() !=
            flutterSdkDir?.path ||
        editor.query([dartSdkDirKey])?.value.toJson() != dartSdkDir?.path) {
      throw AssertionError('Corrupt settings.json');
    }

    // Delete settings.json and .vscode if they are empty
    if (editor.source.trim() == '{}' && settingsFile.existsSync()) {
      settingsFile.deleteSync();
      if (configDir.listSync().isEmpty) {
        configDir.deleteSync();
      }
    }

    log.v('Writing to `${settingsFile.path}`');
    settingsFile.parent.createSync(recursive: true);
    settingsFile.writeAsStringSync(editor.source);
  }

  static Future<VSCodeConfig> load({
    required Scope scope,
    required Directory projectDir,
    required ProjectConfig projectConfig,
  }) async {
    final log = PuroLogger.of(scope);
    final config = PuroConfig.of(scope);
    final workspaceDir = config.findVSCodeWorkspaceDir(projectDir);
    log.v('vscode workspaceDir: $workspaceDir');
    if (workspaceDir == null) {
      return VSCodeConfig(
        workspaceDir:
            findProjectDir(projectDir, '.idea') ??
            projectConfig.ensureParentProjectDir(),
        projectConfig: projectConfig,
        exists: false,
      );
    }
    final vscodeConfig = VSCodeConfig(
      workspaceDir: workspaceDir,
      projectConfig: projectConfig,
      exists: true,
    );
    if (vscodeConfig.settingsFile.existsSync() &&
        vscodeConfig.settingsFile.lengthSync() > 0) {
      final editor = vscodeConfig.readSettings();
      final flutterSdkPathStr = editor
          .query([flutterSdkDirKey])
          ?.value
          .toJson();
      if (flutterSdkPathStr is String) {
        vscodeConfig.flutterSdkDir = config.fileSystem.directory(
          flutterSdkPathStr,
        );
      }
      final dartSdkPathStr = editor.query([dartSdkDirKey])?.value.toJson();
      if (dartSdkPathStr is String) {
        vscodeConfig.dartSdkDir = config.fileSystem.directory(dartSdkPathStr);
      }
    }
    return vscodeConfig;
  }
}

Future<bool> isRunningInVscode({required Scope scope}) async {
  final processes = await getParentProcesses(scope: scope);
  return processes.any(
    (e) =>
        e.name == 'Code.exe' ||
        e.name == 'VSCode.exe' ||
        e.name == 'VSCodium.exe' ||
        e.name == 'code' ||
        e.name == 'codium',
  );
}
