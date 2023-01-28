import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:file/file.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../config.dart';
import '../extensions.dart';
import '../logger.dart';
import '../process.dart';
import '../provider.dart';
import 'bootstrap.dart';
import 'parse.dart';

final _identifierRegex = RegExp(r'[a-zA-Z_$][a-zA-Z_$0-9]*');
final _identifierOrUriRegex = RegExp(r'[a-zA-Z_$:/\\.][a-zA-Z_$0-9:/\\.]*');

class EvalImport {
  EvalImport(
    this.uri, {
    this.as,
    this.show = const {},
    this.hide = const {},
  });

  final Uri uri;
  final String? as;
  final Set<String> show;
  final Set<String> hide;

  factory EvalImport.parse(String import) {
    final uriMatch = _identifierOrUriRegex.matchAsPrefix(import);
    if (uriMatch == null) {
      throw ArgumentError.value(import, 'import', 'name or uri expected');
    }

    var e = uriMatch.group(0)!;
    if (!e.contains(':')) e = 'package:$e';
    var uri = Uri.parse(e);
    if (uri.scheme == 'package') {
      if (uri.pathSegments.length == 1) {
        uri = Uri.parse('$e/${uri.pathSegments.first}.dart');
      } else if (!uri.pathSegments.last.contains('.')) {
        uri = Uri.parse('$e.dart');
      }
    }

    String? as;
    final show = <String>{};
    final hide = <String>{};
    import = import.substring(uriMatch.end);
    String? lastModifier;
    while (import.isNotEmpty) {
      var modifier = import.substring(0, 1);
      if (modifier == ',') {
        if (lastModifier == null) break;
        modifier = lastModifier;
      }
      if (modifier == '=') {
        final identifierMatch = _identifierRegex.matchAsPrefix(import, 1);
        as = identifierMatch?.group(0) ?? uri.pathSegments.first;
        import = import.substring(identifierMatch?.end ?? 1);
      } else if (modifier == '+') {
        final identifierMatch = _identifierRegex.matchAsPrefix(import, 1);
        if (identifierMatch == null) {
          throw ArgumentError.value(
            import,
            'import',
            'name expected after `+`',
          );
        }
        show.add(identifierMatch.group(0)!);
        import = import.substring(identifierMatch.end);
      } else if (modifier == '-') {
        final identifierMatch = _identifierRegex.matchAsPrefix(import, 1);
        if (identifierMatch == null) {
          throw ArgumentError.value(
            import,
            'import',
            'name expected after `-`',
          );
        }
        hide.add(identifierMatch.group(0)!);
        import = import.substring(identifierMatch.end);
      } else {
        break;
      }
      lastModifier = modifier;
    }

    if (import.isNotEmpty) {
      throw ArgumentError.value(
        import,
        'import',
        'unexpected character `${import.substring(0, 1)}`',
      );
    }

    return EvalImport(uri, as: as, show: show, hide: hide);
  }

  @override
  String toString() {
    return "import ${[
      "'$uri'",
      if (as != null) 'as $as',
      if (show.isNotEmpty) 'show ${show.join(', ')}',
      if (hide.isNotEmpty) 'hide ${hide.join(', ')}',
    ].join(' ')};";
  }
}

MapEntry<String, VersionConstraint?> parseEvalPackage(String package) {
  final packageNameMatch = _identifierRegex.matchAsPrefix(package);
  if (packageNameMatch == null) {
    throw ArgumentError.value(package, 'package', 'package name expected');
  }

  final packageName = packageNameMatch.group(0)!;
  package = package.substring(packageNameMatch.end);

  if (package.isEmpty) {
    return MapEntry(packageName, null);
  } else if (package.startsWith('=')) {
    package = package.substring(1);
  }

  if (package.isEmpty || package == 'none') {
    return MapEntry(packageName, VersionConstraint.empty);
  } else {
    return MapEntry(packageName, VersionConstraint.parse(package));
  }
}

class EvalError implements Exception {
  EvalError({required this.message});

  final String message;

  @override
  String toString() => 'Eval error:\n$message';
}

const _hostCode = r'''import 'dart:io';
import 'dart:developer';
import 'dart:convert';
import 'eval.dart' as eval;

void main() {
  // VM service evaluation doesn't support futures so we need an extension to
  // asynchronously send back eval results.
  registerExtension('ext.eval.run', (method, params) async {
    try {
      final result = await (eval.main() as dynamic);
      return ServiceExtensionResponse.result(jsonEncode({
        'value': '$result',
      }));
    } catch (exception, stackTrace) {
      return ServiceExtensionResponse.result(jsonEncode({
        'error': '$exception',
        'stackTrace': '$stackTrace',
      }));
    }
  });
  // exit when stdin closes so it doesn't become a zombie
  stdin.drain().then((_) => exit(0));
}''';

const _coreLibraryNames = {
  'async',
  'collection',
  'convert',
  'math',
  'typed_data',
  'ffi',
  'io',
  'isolate',
  'mirrors',
};

class EvalWorker {
  EvalWorker({
    required this.scope,
    required this.environment,
    required this.process,
    required this.port,
    required this.projectDir,
    required this.mainFileHandle,
    required this.vmService,
    required this.isolateId,
    required this.stderrFuture,
  });

  final Scope scope;
  final EnvConfig environment;
  final Process process;
  final int port;
  final Directory projectDir;
  final RandomAccessFile mainFileHandle;
  final VmService vmService;
  final String isolateId;
  final Future<void> stderrFuture;

  late final log = PuroLogger.of(scope);
  late final evalFile = projectDir.childFile('eval.dart');

  var didUpdatePackages = false;

  static Future<EvalWorker> spawn({
    required Scope scope,
    required EnvConfig environment,
  }) async {
    final log = PuroLogger.of(scope);

    // Clean up old projects.
    environment.evalDir.createSync(recursive: true);
    for (final dir in environment.evalDir.listSync().whereType<Directory>()) {
      if (!dir.basename.startsWith('project')) continue;
      try {
        // Deleting main.dart will throw if the project is still in use.
        final mainFile = dir.childFile('main.dart');
        if (mainFile.existsSync()) {
          mainFile.deleteSync();
        }
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        continue;
      }
    }

    // Create a temp project.
    final projectDir = environment.evalDir.createTempSync('project');
    final mainFile = projectDir.childFile('main.dart');
    final mainFileHandle = mainFile.openSync(mode: FileMode.write);
    mainFileHandle.writeAllStringSync(_hostCode);
    projectDir.childFile('eval.dart').writeAsStringSync('void main() {}');

    // Find an unused port: https://github.com/dart-lang/test/blob/9c6ddedfe44300fe4d63ac5eeb95a1f359bbccc9/pkgs/test_core/lib/src/util/io.dart#L169
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();

    // Create an empty package config, reloadSources doesn't reload packages
    // unless we start with one :/
    final packagesFile = environment.evalBootstrapPackagesFile;
    if (!packagesFile.existsSync()) {
      packagesFile.parent.createSync(recursive: true);
      packagesFile.writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'configVersion': 2,
          'packages': <dynamic>[],
        }),
      );
    }

    final process = await startProcess(
      scope,
      environment.flutter.cache.dartSdk.dartExecutable.path,
      [
        '--enable-vm-service=$port',
        '--packages=${packagesFile.path}',
        'run',
        '--no-serve-devtools',
        '${mainFile.path}',
      ],
      workingDirectory: projectDir.path,
    );

    // Connecting to the observatory requires a token which we can only get from
    // scanning stdout.
    final stdoutLines = const LineSplitter()
        .bind(const Utf8Decoder(allowMalformed: true).bind(process.stdout));
    final serverUriCompleter = Completer<String>();
    stdoutLines.listen((line) {
      if (!serverUriCompleter.isCompleted &&
          line.startsWith('The Dart VM service is listening on')) {
        serverUriCompleter
            .complete(line.split(' ').last.replaceAll('http://', 'ws://'));
      }
    });
    final stderrFuture = process.stderr.listen(stderr.add).asFuture<void>();

    // Wait for the main isolate to become runnable.
    final serverUri = await serverUriCompleter.future;
    log.d('serverUri: $serverUri');
    final vmService = await vmServiceConnectUri(serverUri);

    final streamListenFuture = Future.wait([
      vmService.streamListen(EventStreams.kIsolate),
      vmService.streamListen(EventStreams.kStderr),
      vmService.streamListen(EventStreams.kStdout),
    ]);

    final isolateIdCompleter = Completer<String>();
    vmService.onIsolateEvent.listen((e) {
      if (!isolateIdCompleter.isCompleted && e.kind == 'IsolateRunnable') {
        isolateIdCompleter.complete(e.isolate!.id);
      }
    });

    final isolateId = await isolateIdCompleter.future;
    await streamListenFuture;

    // Forward stdout / stderr.
    vmService.onStdoutEvent.listen((e) => stdout.add(base64.decode(e.bytes!)));
    vmService.onStderrEvent.listen((e) => stderr.add(base64.decode(e.bytes!)));

    // To debug what is being sent/received by the vm service:
    // vmService.onReceive.listen((e) => print('--> $e'));
    // vmService.onSend.listen((e) => print('<-- $e'));

    log.d('EvalWorker.spawn done');

    return EvalWorker(
      scope: scope,
      environment: environment,
      process: process,
      port: port,
      projectDir: projectDir,
      mainFileHandle: mainFileHandle,
      vmService: vmService,
      isolateId: isolateId,
      stderrFuture: stderrFuture,
    );
  }

  Future<void> pullPackages({
    Map<String, VersionConstraint?> packages = const {},
    bool reset = false,
  }) async {
    if (packages.isEmpty) return;
    log.d(() => 'pullPackages: $packages');
    // Initialize packages file, this takes about 1 second on the first run with
    // a good internet connection.
    final vmInfo = await vmService.getVM();
    log.d(() => 'vmInfo: ${prettyJsonEncoder.convert(vmInfo.json)}');
    didUpdatePackages = didUpdatePackages ||
        await updateEvalBootstrapProject(
          scope: scope,
          environment: environment,
          sdkVersion: vmInfo.version!.split(' ').first,
          packages: packages,
          reset: reset,
        );
  }

  SimpleParseResult<AstNode> parse(String code) {
    final unitParseResult = parseDartCompilationUnit(code);
    final unitNode = unitParseResult.node;

    log.d('unitNode: ${unitNode.runtimeType}');
    log.d(() => 'unitNode.directives: ${unitNode?.directives}');
    log.d(() => 'unitNode.declarations: '
        '${unitNode?.declarations.map((e) => e.runtimeType).join(', ')}');

    // Always use unit if it contains top-level declarations or imports.
    if (unitNode != null &&
        (unitNode.directives.isNotEmpty ||
            unitNode.declarations.any((e) =>
                e is ClassDeclaration ||
                e is MixinDeclaration ||
                e is ExtensionDeclaration ||
                e is EnumDeclaration ||
                e is TypeAlias))) {
      return unitParseResult;
    }

    final expressionParseResult = parseDartExpression(code, async: true);

    final expressionNode = expressionParseResult.node;
    log.d('expressionNode: ${expressionNode.runtimeType}');
    log.d('expressionParseResult.parseErrors: '
        '${expressionParseResult.parseErrors}');
    log.d('expressionParseResult.scanErrors: '
        '${expressionParseResult.scanErrors}');
    log.d('expressionParseResult.parseException: '
        '${expressionParseResult.parseException}');
    log.d('expressionParseResult.scanException: '
        '${expressionParseResult.scanException}');
    log.d('expressionParseResult.exhaustive: '
        '${expressionParseResult.exhaustive}');

    if (!expressionParseResult.hasError && expressionParseResult.exhaustive) {
      return expressionParseResult;
    }

    return parseDartBlock('{$code}');
  }

  Future<String?> evaluate(
    String code, {
    List<EvalImport> imports = const [],
    bool importCore = false,
  }) async {
    if (importCore) {
      imports = [
        ..._coreLibraryNames.map((e) => EvalImport(Uri.parse('dart:$e'))),
        ...imports,
      ];
    }
    final importStr = imports.map((e) => '$e\n').join();
    final parseResult = parse(code);
    final node = parseResult.node;
    if (node is Expression) {
      return _evaluate(
        '${importStr}Future<dynamic> main() async =>\n$code\n;',
        hasReturnValue: true,
      );
    } else if (node is CompilationUnit) {
      return _evaluate('$importStr$code');
    } else {
      return _evaluate('${importStr}Future<void> main() async {\n$code\n}');
    }
  }

  Future<String?> _evaluate(String code, {bool hasReturnValue = false}) async {
    log.d(() => '_evaluate: ${jsonEncode(code)}');
    evalFile.writeAsStringSync(code);

    final reloadResult = await vmService.reloadSources(
      isolateId,
      packagesUri: didUpdatePackages
          ? Uri.file(environment.evalBootstrapPackagesFile.path).toString()
          : null,
    );

    didUpdatePackages = false;

    if (reloadResult.success == false) {
      final notices = reloadResult.json!['notices'] as List<dynamic>;
      final dynamic reason =
          notices.firstWhere((dynamic e) => e['type'] == 'ReasonForCancelling');
      throw EvalError(message: reason['message'] as String);
    }

    final response = await vmService.callServiceExtension(
      'ext.eval.run',
      isolateId: isolateId,
    );

    log.d(() => 'response: ${prettyJsonEncoder.convert(response.json)}');

    final jsonData = response.json!;
    if (jsonData['value'] != null) {
      if (hasReturnValue) {
        return jsonData['value'] as String;
      } else {
        return null;
      }
    } else {
      throw EvalError(
        message: '${jsonData['error']}\n${jsonData['stackTrace']}',
      );
    }
  }

  Future<void> dispose() async {
    log.d('disposing EvalWorker(${process.pid})');
    mainFileHandle.closeSync();
    process.kill(ProcessSignal.sigkill);
    await stderrFuture;
  }
}
