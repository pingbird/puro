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
  Future<String> readAllAsString() async {
    setPositionSync(0);
    return utf8.decode(await read(lengthSync()));
  }

  String readAllAsStringSync() {
    setPositionSync(0);
    return utf8.decode(readSync(lengthSync()));
  }

  Future<void> writeAll(List<int> bytes) async {
    setPositionSync(0);
    await truncate(bytes.length);
    await writeFrom(bytes);
  }

  Future<void> writeAllString(String string) {
    return writeAll(utf8.encode(string));
  }

  void writeAllSync(List<int> bytes) {
    setPositionSync(0);
    truncateSync(bytes.length);
    writeFromSync(bytes);
  }

  void writeAllStringSync(String string) {
    writeAllSync(utf8.encode(string));
  }
}
