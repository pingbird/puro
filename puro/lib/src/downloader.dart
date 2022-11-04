import 'package:file/file.dart';
import 'package:http/http.dart';

import 'http.dart';
import 'logger.dart';
import 'progress.dart';
import 'provider.dart';

Future<void> downloadFile({
  required Scope scope,
  required Uri url,
  required File file,
  String? description,
}) async {
  final log = PuroLogger.of(scope);
  final httpClient = scope.read(clientProvider);
  final sink = file.openWrite();

  log.v('Downloading $url to ${file.path}');

  await ProgressNode.of(scope).wrap((scope, node) async {
    node.description = description ?? 'Downloading ${url.pathSegments.last}';
    final response = await httpClient.send(Request('GET', url));
    if (response.statusCode ~/ 100 != 2) {
      throw AssertionError(
        'HTTP ${response.statusCode} on GET $url',
      );
    }
    await node.wrapHttpResponse(response).pipe(sink);
  });
}
