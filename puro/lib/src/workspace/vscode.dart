import 'package:file/file.dart';

import '../config.dart';
import '../json_edit/editor.dart';
import '../logger.dart';
import '../process.dart';
import '../provider.dart';
import 'common.dart';

class VSCodeConfig extends IdeConfig {
  VSCodeConfig({
    required super.workspaceDir,
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
      return JsonEditor(
        source: '{}',
        indentLevel: 4,
      );
    }
    return JsonEditor(
      source: settingsFile.readAsStringSync(),
      indentLevel: 4,
    );
  }

  static const flutterSdkDirKey = 'dart.flutterSdkPath';
  static const dartSdkDirKey = 'dart.sdkPath';

  @override
  Future<void> backup({required Scope scope}) async {
    final config = PuroConfig.of(scope);
    final dotfile = config.readDotfileForWriting();
    var changedDotfile = false;
    if (flutterSdkDir != null && !dotfile.hasPreviousFlutterSdk()) {
      dotfile.previousFlutterSdk = flutterSdkDir!.path;
      changedDotfile = true;
    }
    if (dartSdkDir != null && !dotfile.hasPreviousDartSdk()) {
      dotfile.previousDartSdk = dartSdkDir!.path;
      changedDotfile = true;
    }
    if (changedDotfile) {
      config.writeDotfile(dotfile);
    }
  }

  @override
  Future<void> restore({required Scope scope}) async {
    final config = PuroConfig.of(scope);
    final dotfile = config.readDotfileForWriting();
    var changedDotfile = false;
    if (dotfile.hasPreviousFlutterSdk()) {
      flutterSdkDir = config.fileSystem.directory(dotfile.previousFlutterSdk);
      dotfile.clearPreviousFlutterSdk();
      changedDotfile = true;
    } else {
      flutterSdkDir = null;
    }
    if (dotfile.hasPreviousDartSdk()) {
      dartSdkDir = config.fileSystem.directory(dotfile.previousFlutterSdk);
      dotfile.clearPreviousDartSdk();
      changedDotfile = true;
    } else {
      dartSdkDir = null;
    }
    if (changedDotfile) {
      config.writeDotfile(dotfile);
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
  }) async {
    final log = PuroLogger.of(scope);
    final config = PuroConfig.of(scope);
    final workspaceDir = findProjectDir(projectDir, '.vscode');
    log.v('vscode workspaceDir: $workspaceDir');
    if (workspaceDir == null) {
      return VSCodeConfig(
        workspaceDir: findProjectDir(projectDir, '.idea') ??
            config.ensureParentProjectDir(),
        exists: false,
      );
    }
    final vscodeConfig = VSCodeConfig(
      workspaceDir: workspaceDir,
      exists: true,
    );
    if (vscodeConfig.settingsFile.existsSync()) {
      final editor = vscodeConfig.readSettings();
      final flutterSdkPathStr =
          editor.query([flutterSdkDirKey])?.value.toJson();
      if (flutterSdkPathStr is String) {
        vscodeConfig.flutterSdkDir =
            config.fileSystem.directory(flutterSdkPathStr);
      }
      final dartSdkPathStr = editor.query([dartSdkDirKey])?.value.toJson();
      if (dartSdkPathStr is String) {
        vscodeConfig.dartSdkDir = config.fileSystem.directory(dartSdkPathStr);
      }
    }
    return vscodeConfig;
  }
}

Future<bool> isRunningInVscode({
  required Scope scope,
}) async {
  final processes = await getParentProcesses(scope: scope);
  return processes.any((e) => e.name == 'Code.exe' || e.name == 'code');
}
