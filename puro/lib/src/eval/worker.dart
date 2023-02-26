import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../config.dart';
import '../extensions.dart';
import '../logger.dart';
import '../process.dart';
import '../provider.dart';
import 'context.dart';
import 'parse.dart';

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
  postEvent('EvalReady', {});
  // exit when stdin closes so it doesn't become a zombie
  stdin.drain().then((_) => exit(0));
}''';

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
    required this.onExit,
    required this.context,
    required this.currentCode,
  });

  final Scope scope;
  final EnvConfig environment;
  final Process process;
  final int port;
  final Directory projectDir;
  final RandomAccessFile mainFileHandle;
  final VmService vmService;
  final String isolateId;
  final Future<int> onExit;
  final EvalContext context;
  ParseResult currentCode;
  var reloadSuccessful = true;

  late final log = PuroLogger.of(scope);
  late final evalFile = projectDir.childFile('eval.dart');

  static Future<EvalWorker> spawn({
    required Scope scope,
    required EvalContext context,
    List<String> extra = const [],
    String? code,
  }) async {
    final log = PuroLogger.of(scope);
    final environment = context.environment;

    var initialCode = context.parse('void main() {}');
    if (code != null) {
      initialCode = context.transform(code);
    }

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
    projectDir.childFile('eval.dart').writeAsStringSync(initialCode.code);

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
        ...extra,
        '${mainFile.path}',
      ],
      workingDirectory: projectDir.path,
    );
    context.needsPackageReload = false;

    // Connecting to the observatory requires a token which we can only get from
    // scanning stdout.
    final stdoutLines = const LineSplitter()
        .bind(const Utf8Decoder(allowMalformed: true).bind(process.stdout));
    final serverUriCompleter = Completer<String>();
    final stdoutFuture = stdoutLines.listen((line) {
      if (!serverUriCompleter.isCompleted &&
          line.startsWith('The Dart VM service is listening on')) {
        serverUriCompleter
            .complete(line.split(' ').last.replaceAll('http://', 'ws://'));
      }
    }).asFuture<void>();
    final stderrFuture = process.stderr.listen(stderr.add).asFuture<void>();

    // Wait for the main isolate to become runnable.
    final serverUri = await serverUriCompleter.future;
    log.d('serverUri: $serverUri');
    final vmService = await vmServiceConnectUri(serverUri);

    final streamListenFuture = Future.wait([
      vmService.streamListen(EventStreams.kStderr),
      vmService.streamListen(EventStreams.kStdout),
      vmService.streamListen(EventStreams.kExtension),
    ]);

    final isolateIdCompleter = Completer<String>();
    vmService.onExtensionEvent.listen((e) {
      if (e.extensionKind == 'EvalReady') {
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
      onExit:
          stdoutFuture.then((_) => stderrFuture.then((_) => process.exitCode)),
      context: context,
      currentCode: initialCode,
    );
  }

  Future<void> reload(ParseResult parseResult) async {
    log.d(() => '_evaluate: ${jsonEncode(parseResult.code)}');
    if (parseResult.code == currentCode.code &&
        !context.needsPackageReload &&
        reloadSuccessful) return;
    reloadSuccessful = false;
    evalFile.writeAsStringSync(parseResult.code);
    currentCode = parseResult;

    final reloadResult = await vmService.reloadSources(
      isolateId,
      packagesUri: context.needsPackageReload
          ? Uri.file(environment.evalBootstrapPackagesFile.path).toString()
          : null,
    );

    if (reloadResult.success == false) {
      final notices = reloadResult.json!['notices'] as List<dynamic>;
      final dynamic reason =
          notices.firstWhere((dynamic e) => e['type'] == 'ReasonForCancelling');
      throw EvalError(message: reason['message'] as String);
    }

    context.needsPackageReload = false;
    reloadSuccessful = true;
  }

  Future<String?> run() async {
    final response = await vmService.callServiceExtension(
      'ext.eval.run',
      isolateId: isolateId,
    );

    log.d(() => 'response: ${prettyJsonEncoder.convert(response.json)}');

    final jsonData = response.json!;
    if (jsonData['value'] != null) {
      if (currentCode.hasReturn) {
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
    await onExit;
  }
}
