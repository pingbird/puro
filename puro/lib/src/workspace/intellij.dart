import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

import '../config.dart';
import '../logger.dart';
import '../provider.dart';
import 'common.dart';

class IntelliJConfig extends IdeConfig {
  IntelliJConfig({
    required super.workspaceDir,
    required super.projectConfig,
    super.dartSdkDir,
    super.flutterSdkDir,
    required super.exists,
  });

  late final configDir = workspaceDir.childDirectory('.idea');
  late final librariesDir = configDir.childDirectory('libraries');
  late final dartSdkFile = librariesDir.childFile('Dart_SDK.xml');
  late final dartSdkBakFile = librariesDir.childFile('Dart_SDK.xml.bak');
  late final dartPackagesFile = librariesDir.childFile('Dart_Packages.xml');
  late final modulesXmlFile = configDir.childFile('modules.xml');
  late final dartPackagesBakFile =
      librariesDir.childFile('Dart_Packages.xml.bak');

  @override
  String get name => 'IntelliJ';

  @override
  Future<void> backup({required Scope scope}) async {
    if (dartSdkFile.existsSync() && !dartSdkBakFile.existsSync()) {
      dartSdkFile.copySync(dartSdkBakFile.path);
    }
    if (dartPackagesFile.existsSync() && !dartPackagesBakFile.existsSync()) {
      dartPackagesFile.copySync(dartPackagesBakFile.path);
    }
  }

  @override
  Future<void> restore({required Scope scope}) async {
    final log = PuroLogger.of(scope);

    if (dartSdkBakFile.existsSync()) {
      if (dartSdkFile.existsSync()) {
        log.v('Deleting `${dartSdkFile.path}`');
        dartSdkFile.deleteSync();
      }
      log.v('Renaming `${dartSdkBakFile.path}` to `${dartSdkFile.path}`');
      dartSdkBakFile.renameSync(dartSdkFile.path);
    }
    if (dartPackagesBakFile.existsSync()) {
      if (dartPackagesFile.existsSync()) {
        log.v('Deleting `${dartPackagesFile.path}`');
        dartPackagesFile.deleteSync();
      }
      log.v(
        'Renaming `${dartPackagesBakFile.path}` to `${dartPackagesFile.path}`',
      );
      dartPackagesBakFile.renameSync(dartPackagesFile.path);
    }
  }

  Directory? get effectiveDartSdkDir {
    if (dartSdkDir != null) return dartSdkDir;
    if (flutterSdkDir == null) return null;
    return FlutterConfig(flutterSdkDir!).cache.dartSdkDir;
  }

  @override
  Future<void> save({required Scope scope}) async {
    final dartSdk = DartSdkConfig(effectiveDartSdkDir!);
    final config = PuroConfig.of(scope);
    final log = PuroLogger.of(scope);

    // The IntelliJ Dart plugin parses this file and walks its AST to extract
    // the keys of this library map. This is dumb. 💀
    // https://github.com/JetBrains/intellij-plugins/blob/0f07ca63355d5530b441ca566c98f17c560e77f8/Dart/src/com/jetbrains/lang/dart/ide/index/DartLibraryIndex.java#L132
    final librariesFileLines =
        await dartSdk.internalLibrariesDartFile.readAsLines();
    final startLine = librariesFileLines.indexOf(
      'const Map<String, LibraryInfo> libraries = const {',
    );
    if (startLine < 0) {
      throw AssertionError(
        'Failed to extract libraries from ${dartSdk.internalLibrariesDartFile.path}',
      );
    }
    final endLine = librariesFileLines.indexOf('};', startLine);
    final libraries = <String>{};
    String? currentLib;
    for (var i = startLine; i < endLine; i++) {
      final line = librariesFileLines[i];
      if (line.trimLeft().startsWith('documented: false') &&
          currentLib != null) {
        libraries.remove(currentLib);
        continue;
      }
      if (!line.startsWith(RegExp('\\s\\s["\']'))) continue;
      final libName = line.substring(3, line.indexOf(RegExp('[\'"]'), 3));
      currentLib = libName;
      if (libName.startsWith('_')) continue;

      libraries.add(libName);
    }
    if (libraries.isEmpty) {
      throw AssertionError(
        'Failed to extract libraries from ${dartSdk.internalLibrariesDartFile.path}',
      );
    }
    final homeDirStr =
        path.canonicalize(config.homeDir.path).replaceAll('\\', '/');
    final urls = <String>[
      for (final libName in libraries)
        '${Uri.file(path.canonicalize(dartSdk.libDir.path))}/$libName'
            .replaceAll('$homeDirStr', r'$USER_HOME$'),
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
    log.v('Writing to `${dartSdkFile.path}`');
    dartSdkFile.parent.createSync(recursive: true);
    dartSdkFile.writeAsStringSync(document.toXmlString(pretty: true));
    // IntellIJ will re-populate this file immediately after we delete it
    if (dartPackagesFile.existsSync()) {
      dartPackagesFile.deleteSync();
    }

    await enableDartSupport(scope: scope);
  }

  Future<void> enableDartSupport({required Scope scope}) async {
    final log = PuroLogger.of(scope);
    if (!modulesXmlFile.existsSync()) {
      log.d('enableDartSupport - no modules.xml');
      return;
    }

    var document = XmlDocument.parse(modulesXmlFile.readAsStringSync());
    final project = document.getElement('project');
    if (project == null) {
      log.d('enableDartSupport - no project');
      return;
    }

    var component = project.childElements.firstWhereOrNull((e) =>
        e.name.toString() == 'component' &&
        e.getAttribute('name') == 'ProjectModuleManager');
    if (component == null) {
      log.d('enableDartSupport - no component');
      return;
    }

    final modules = component.getElement('modules');
    if (modules == null) {
      log.d('enableDartSupport - no modules');
      return;
    }

    const projectDirStr = r'$PROJECT_DIR$/';
    const dotIdeaStr = r'.idea/';
    final rootModule = modules.childElements.firstWhereOrNull((e) {
      var filepath = e.getAttribute('filepath');
      if (filepath == null ||
          !filepath.startsWith(projectDirStr) ||
          !filepath.endsWith('.iml')) return false;
      filepath = filepath.substring(projectDirStr.length);
      if (filepath.startsWith(dotIdeaStr)) {
        filepath = filepath.substring(dotIdeaStr.length);
      }
      return !filepath.contains('/');
    });
    if (rootModule == null) {
      log.d('enableDartSupport - no root module');
      return;
    }

    var rootModulePath =
        rootModule.getAttribute('filepath')!.substring(projectDirStr.length);
    if (Platform.isWindows) {
      rootModulePath = rootModulePath.replaceAll('/', '\\');
    }

    final imlFile = workspaceDir.childFile(rootModulePath);
    log.d('imlFile: $imlFile');
    if (!imlFile.existsSync()) {
      log.d('enableDartSupport - no iml file');
      return;
    }

    document = XmlDocument.parse(imlFile.readAsStringSync());
    final module = document.getElement('module');
    if (module == null) {
      log.d('enableDartSupport - no module in iml');
      return;
    }

    component = module.childElements.firstWhereOrNull((e) =>
        e.name.toString() == 'component' &&
        e.getAttribute('name') == 'NewModuleRootManager');
    if (component == null) {
      log.d('enableDartSupport - no component in iml');
      return;
    }

    final needsLibraries = {'Dart SDK', 'Dart Packages', 'Flutter Plugins'};

    for (final child in component.childElements) {
      if (child.name.toString() == 'orderEntry' &&
          child.getAttribute('type') == 'library' &&
          child.getAttribute('level') == 'project') {
        needsLibraries.remove(child.getAttribute('name')!);
      }
    }

    if (needsLibraries.isEmpty) {
      log.d('enableDartSupport - libraries satisfied');
      return;
    }

    for (final library in needsLibraries) {
      component.children.add(
        XmlElement(XmlName('orderEntry'), [
          XmlAttribute(XmlName('type'), 'library'),
          XmlAttribute(XmlName('name'), library),
          XmlAttribute(XmlName('level'), 'project'),
        ]),
      );
    }

    imlFile.writeAsStringSync(document.toXmlString(pretty: true));

    log.v('Enabled dart support in IntelliJ project');
  }

  static Future<IntelliJConfig> load({
    required Scope scope,
    required Directory projectDir,
    required ProjectConfig projectConfig,
  }) async {
    final log = PuroLogger.of(scope);
    final config = PuroConfig.of(scope);
    final workspaceDir = findProjectDir(projectDir, '.idea');
    log.v('intellij workspaceDir: $workspaceDir');
    if (workspaceDir == null) {
      return IntelliJConfig(
        workspaceDir: config.findVSCodeWorkspaceDir(projectDir) ??
            projectConfig.ensureParentProjectDir(),
        projectConfig: projectConfig,
        exists: false,
      );
    }
    final intellijConfig = IntelliJConfig(
      workspaceDir: workspaceDir,
      projectConfig: projectConfig,
      exists: true,
    );
    if (intellijConfig.dartSdkFile.existsSync()) {
      final xml = XmlDocument.parse(
        intellijConfig.dartSdkFile.readAsStringSync(),
      );
      final classElements = xml.findAllElements('root');
      if (classElements.isNotEmpty) {
        final classElement = classElements.first;
        final urlPath = Uri.parse(classElement
                .getAttribute('url')!
                .replaceAll(
                  RegExp(r'\$USER_HOME\$', caseSensitive: false),
                  config.homeDir.path,
                )
                .replaceAll(RegExp(r'\$PROJECT_DIR\$', caseSensitive: false),
                    workspaceDir.path))
            .toFilePath()
            .replaceAll(RegExp(r'^\\\\'), '');
        final dartSdkDir =
            config.fileSystem.directory(urlPath).absolute.parent.parent;
        if (dartSdkDir.childDirectory('bin').existsSync()) {
          intellijConfig.dartSdkDir = dartSdkDir.absolute;
          if (dartSdkDir.parent.basename == 'cache' &&
              dartSdkDir.parent.parent.basename == 'bin') {
            intellijConfig.flutterSdkDir =
                dartSdkDir.parent.parent.parent.absolute;
          }
        }
      }
    }
    return intellijConfig;
  }
}
