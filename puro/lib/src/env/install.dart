import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

import '../config.dart';
import '../json_edit/editor.dart';
import '../logger.dart';
import '../provider.dart';

const ignoredFiles = {PuroConfig.dotfileName};
const ignoreComment = '# Managed by puro';

/// Adds the dotfile to .git/info/exclude which is a handy way to ignore it
/// without touching the working tree or global git configuration.
Future<void> installGitignore({required Scope scope}) async {
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);
  final projectDir = config.projectDir;
  if (projectDir == null) return;
  final gitTree = findProjectDir(projectDir, '.git');
  if (gitTree == null) return;
  final excludeFile = gitTree
      .childDirectory('.git')
      .childDirectory('info')
      .childFile('exclude');
  excludeFile.createSync(recursive: true);
  final lines = const LineSplitter().convert(excludeFile.readAsStringSync());
  final existingIgnores = <String>{};
  for (var i = 0; i < lines.length;) {
    if (lines[i] == ignoreComment && i + 1 < lines.length) {
      existingIgnores.add(lines[i + 1]);
      lines.removeAt(i);
      lines.removeAt(i);
    } else {
      i++;
    }
  }
  while (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
  if (!existingIgnores.containsAll(ignoredFiles)) {
    log.v('Updating gitignore of ${gitTree.path}');
    excludeFile.writeAsStringSync([
      ...lines,
      '',
      for (final name in ignoredFiles) ...[ignoreComment, name],
    ].join('\n'));
    log.v('Added ${PuroConfig.dotfileName} to .git/info/exclude');
  }
}

/// Modifies IntelliJ and VSCode configs of the current project to use the
/// selected environment's Flutter SDK.
Future<void> installIdeConfigs({
  required Scope scope,
}) async {
  final config = PuroConfig.of(scope);
  final log = PuroLogger.of(scope);
  final homeDir = config.homeDir;
  final dotfile = config.readDotfileForWriting();
  final environment = config.getCurrentEnv();
  final intelliJConfigDir = findProjectDir(
    config.parentProjectDir!,
    '.idea',
  )?.childDirectory('.idea');
  final vscodeConfigDir = findProjectDir(
    config.parentProjectDir!,
    '.vscode',
  )?.childDirectory('.vscode');

  Directory? originalDartSdk;
  Directory? originalFlutterSdk;

  if (intelliJConfigDir != null) {
    final librariesDir = intelliJConfigDir.childDirectory('libraries');
    librariesDir.createSync(recursive: true);
    final dartSdkFile = librariesDir.childFile('Dart_SDK.xml');
    final dartSdkBakFile = librariesDir.childFile('Dart_SDK.xml.bak');
    final dartPackagesFile = librariesDir.childFile('Dart_Packages.xml');
    final dartPackagesBakFile = librariesDir.childFile('Dart_Packages.xml.bak');

    if (dartSdkFile.existsSync()) {
      // Back up Dart_SDK.xml
      if (!dartSdkBakFile.existsSync()) {
        dartSdkFile.copySync(dartSdkBakFile.path);
      }
      final xml = XmlDocument.parse(dartSdkFile.readAsStringSync());
      final classElement = xml.findAllElements('root').first;
      final urlPath = Uri.parse(classElement.getAttribute('url')!)
          .toFilePath()
          .replaceAll(
            RegExp(r'\$USER_HOME\$', caseSensitive: false),
            homeDir.path,
          )
          .replaceAll(RegExp(r'^\\\\'), '');
      final dartSdkDir =
          config.fileSystem.directory(urlPath).absolute.parent.parent;
      if (dartSdkDir.childDirectory('bin').existsSync()) {
        originalDartSdk = dartSdkDir.absolute;
        if (dartSdkDir.parent.basename == 'cache' &&
            dartSdkDir.parent.parent.basename == 'bin') {
          originalFlutterSdk = dartSdkDir.parent.parent.parent.absolute;
        }
      }
    }

    if (originalFlutterSdk?.path != environment.flutterDir.path) {
      log.v('Updating IntelliJ configs to use `${environment.name}`');

      final dartSdk = environment.flutter.cache.dartSdk;
      final librariesJson =
          jsonDecode(await dartSdk.librariesJsonFile.readAsString())
              as Map<String, dynamic>;
      final libraries = <String>{
        ...(librariesJson['vm']['libraries'] as Map<String, dynamic>).keys,
        ...(librariesJson['dart2js']['libraries'] as Map<String, dynamic>).keys,
      };
      final homeDirStr = path.canonicalize(homeDir.path).replaceAll('\\', '/');
      final urls = <String>[
        for (final libName in libraries)
          if (!libName.startsWith('_'))
            '${Uri.file(path.canonicalize(dartSdk.libDir.path))}/$libName'
                .replaceAll('/$homeDirStr', r'$USER_HOME$'),
      ];

      urls.sort();

      final document = XmlDocument(
        [
          XmlElement(
            XmlName('component'),
            [XmlAttribute(XmlName('name'), 'libraryTable')],
            [
              XmlElement(
                XmlName('library'),
                [XmlAttribute(XmlName('name'), 'Dart SDK')],
                [
                  XmlElement(
                    XmlName('CLASSES'),
                    [],
                    [
                      for (final url in urls)
                        XmlElement(
                          XmlName('root'),
                          [XmlAttribute(XmlName('url'), url)],
                        ),
                    ],
                  ),
                  XmlElement(XmlName('JAVADOC')),
                  XmlElement(XmlName('SOURCES')),
                ],
              ),
            ],
          ),
        ],
      );

      dartSdkFile.writeAsStringSync(document.toXmlString(pretty: true));

      // Back up Dart_Packages.xml
      if (dartPackagesFile.existsSync()) {
        if (!dartPackagesBakFile.existsSync()) {
          dartPackagesFile.copySync(dartPackagesBakFile.path);
        }
        dartPackagesFile.deleteSync(recursive: true);
      }
    }
  }

  if (vscodeConfigDir != null) {
    final settingsFile = vscodeConfigDir.childFile('settings.json');
    if (!settingsFile.existsSync()) {
      settingsFile.writeAsStringSync('{}');
    }
    final editor = JsonEditor(
      source: settingsFile.readAsStringSync(),
      indentLevel: 4,
    );
    final flutterSdkPathStr =
        editor.query(['dart.flutterSdkPath'])?.value.toJson();
    if (flutterSdkPathStr is String) {
      originalFlutterSdk = config.fileSystem.directory(flutterSdkPathStr);
    }
    final dartSdkPathStr = editor.query(['dart.sdkPath'])?.value.toJson();
    if (dartSdkPathStr is String) {
      originalDartSdk = config.fileSystem.directory(dartSdkPathStr);
    }

    final envFlutterSdkPath = environment.flutter.sdkDir.path;
    if (flutterSdkPathStr != envFlutterSdkPath) {
      editor.remove(['dart.sdkPath']);
      editor.update(['dart.flutterSdkPath'], envFlutterSdkPath);
      if (editor.query(['dart.flutterSdkPath'])?.value.toJson() !=
          envFlutterSdkPath) {
        throw AssertionError('Corrupt settings.json');
      }
      settingsFile.writeAsStringSync(editor.source);
    }
  }

  if (originalFlutterSdk != null || originalDartSdk != null) {
    if (!dotfile.hasPreviousFlutterSdk() && originalFlutterSdk != null)
      dotfile.previousFlutterSdk = originalFlutterSdk.path;
    if (!dotfile.hasPreviousDartSdk() && originalDartSdk != null)
      dotfile.previousDartSdk = originalDartSdk.path;
    config.writeDotfile(dotfile);
  }
}

/// Switches the environment of the current project.
Future<void> useEnvironment({
  required Scope scope,
  required String name,
}) async {
  final config = PuroConfig.of(scope);
  final model = config.readDotfile();
  config.getEnv(name).ensureExists();
  model.env = name;
  config.writeDotfile(model);
  await runOptional(
    scope,
    'adding ${PuroConfig.dotfileName} to gitignore',
    () => installGitignore(scope: scope),
  );
  await runOptional(
    scope,
    'installing IDE configs',
    () => installIdeConfigs(scope: scope),
  );
}
