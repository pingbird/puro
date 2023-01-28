import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:file/file.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../config.dart';
import '../env/default.dart';
import '../extensions.dart';
import '../logger.dart';
import '../process.dart';
import '../provider.dart';
import 'bootstrap.dart';
import 'parse.dart';

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

class EvalWorker {
  EvalWorker({
    required this.scope,
    required this.process,
    required this.port,
    required this.projectDir,
    required this.bootstrapDir,
    required this.mainFileHandle,
    required this.vmService,
    required this.isolateId,
    required this.stderrFuture,
  });

  final Scope scope;
  final Process process;
  final int port;
  final Directory projectDir;
  final Directory bootstrapDir;
  final RandomAccessFile mainFileHandle;
  final VmService vmService;
  final String isolateId;
  final Future<void> stderrFuture;

  late final log = PuroLogger.of(scope);
  late final evalFile = projectDir.childFile('eval.dart');

  static Future<EvalWorker> spawn({
    required Scope scope,
  }) async {
    final environment = await getProjectEnvOrDefault(scope: scope);
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

    final process = await startProcess(
      scope,
      environment.flutter.cache.dartSdk.dartExecutable.path,
      [
        '--enable-vm-service=$port',
        //'--packages=${environment.flutter.flutterToolsPackageConfigJsonFile.path}',
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
    await vmService.streamListen(EventStreams.kIsolate);
    final isolateIdCompleter = Completer<String>();
    vmService.onIsolateEvent.listen((e) {
      if (!isolateIdCompleter.isCompleted && e.kind == 'IsolateRunnable') {
        isolateIdCompleter.complete(e.isolate!.id);
      }
    });

    // Initialize packages file, this takes about 1 second on the first run with
    // a good internet connection
    final vmInfo = await vmService.getVM();
    log.d('vmInfo: ${prettyJsonEncoder.convert(vmInfo.json)}');
    await initEvalBootstrapProject(
      scope: scope,
      environment: environment,
      sdkVersion: vmInfo.version!.split(' ').first,
    );

    // Forward stdout / stderr.
    await vmService.streamListen(EventStreams.kStdout);
    vmService.onStdoutEvent.listen((e) => stdout.add(base64.decode(e.bytes!)));
    await vmService.streamListen(EventStreams.kStderr);
    vmService.onStderrEvent.listen((e) => stderr.add(base64.decode(e.bytes!)));

    // To debug what is being sent/received by the vm service:
    // vmService.onReceive.listen((e) => print('--> $e'));
    // vmService.onSend.listen((e) => print('<-- $e'));

    return EvalWorker(
      scope: scope,
      process: process,
      port: port,
      projectDir: projectDir,
      bootstrapDir: environment.evalBootstrapDir,
      mainFileHandle: mainFileHandle,
      vmService: vmService,
      isolateId: await isolateIdCompleter.future,
      stderrFuture: stderrFuture,
    );
  }

  SimpleParseResult<AstNode> parse(String code) {
    final unitParseResult = parseDartCompilationUnit(code);
    final unitNode = unitParseResult.node;

    // Always use unit if it contains top-level declarations or imports
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

    final expressionParseResult = parseDartExpression(code);

    if (!expressionParseResult.hasError && expressionParseResult.exhaustive) {
      return expressionParseResult;
    }

    return parseDartBlock('{$code}');
  }

  Future<String?> evaluate(String code) async {
    final parseResult = parse(code);
    final node = parseResult.node;
    if (node is Expression) {
      return _evaluate(
        'Future<dynamic> main() async =>\n$code;',
        hasReturnValue: true,
      );
    } else if (node is CompilationUnit) {
      return _evaluate(code);
    } else {
      return _evaluate('Future<void> main() {\n$code\n}');
    }
  }

  Future<String?> _evaluate(String code, {bool hasReturnValue = false}) async {
    log.d('_evaluate: ${jsonEncode(code)}');
    evalFile.writeAsStringSync(code);

    final reloadResult = await vmService.reloadSources(
      isolateId,
      packagesUri: Uri.file(
        bootstrapDir
            .childDirectory('.dart_tool')
            .childFile('package_config.json')
            .path,
      ).toString(),
    );

    if (reloadResult.success == false) {
      final notices = reloadResult.json!['notices'] as List<dynamic>;
      final dynamic reason =
          notices.firstWhere((dynamic e) => e['type'] == 'ReasonForCancelling');
      throw EvalError(message: reason['message'] as String);
    }

    final isolateInfo = await vmService.getIsolate(isolateId);
    log.d('isolateInfo: ${prettyJsonEncoder.convert(isolateInfo.json)}');

    final response = await vmService.callServiceExtension(
      'ext.eval.run',
      isolateId: isolateId,
    );

    log.d('response: ${prettyJsonEncoder.convert(response.json)}');

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
