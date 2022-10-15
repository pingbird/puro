import 'package:file/file.dart';

import '../config.dart';
import '../json_edit/editor.dart';
import '../provider.dart';
import 'common.dart';

class VSCodeConfig extends IdeConfig {
  VSCodeConfig({
    required super.workspaceDir,
    super.flutterSdkDir,
    super.dartSdkDir,
  });

  late final configDir = workspaceDir.childDirectory('.vscode');
  late final settingsFile = configDir.childFile('settings.json');

  JsonEditor readSettings() {
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
    if (!settingsFile.existsSync()) {
      settingsFile.writeAsStringSync('{}');
    }

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

    settingsFile.writeAsStringSync(editor.source);
  }

  static Future<VSCodeConfig?> load({
    required Scope scope,
    required Directory projectDir,
  }) async {
    final config = PuroConfig.of(scope);
    final workspaceDir = findProjectDir(projectDir, '.vscode');
    if (workspaceDir == null) return null;
    final vscodeConfig = VSCodeConfig(workspaceDir: workspaceDir);
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
