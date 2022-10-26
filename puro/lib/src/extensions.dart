import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

extension ListIntStreamExtensions on Stream<List<int>> {
  Future<Uint8List> toBytes() {
    final completer = Completer<Uint8List>();
    final sink = ByteConversionSink.withCallback(
      (bytes) => completer.complete(Uint8List.fromList(bytes)),
    );
    listen(
      sink.add,
      onError: completer.completeError,
      onDone: sink.close,
      cancelOnError: true,
    );
    return completer.future;
  }
}

extension RandomAccessFileExtensions on RandomAccessFile {
  Future<String> readAsString() async {
    return utf8.decode(await read(lengthSync() - positionSync()));
  }

  String readAsStringSync() {
    return utf8.decode(readSync(lengthSync() - positionSync()));
  }
}
