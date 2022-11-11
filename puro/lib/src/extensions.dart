import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

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
    await truncate(0);
    setPositionSync(0);
    await writeFrom(bytes);
  }

  Future<void> writeAllString(String string) {
    return writeAll(utf8.encode(string));
  }

  void writeAllSync(List<int> bytes) {
    truncateSync(0);
    setPositionSync(0);
    writeFromSync(bytes);
  }

  void writeAllStringSync(String string) {
    writeAllSync(utf8.encode(string));
  }
}

extension FileSystemEntityExtensions on FileSystemEntity {
  bool pathEquals(FileSystemEntity other) {
    return path.equals(this.path, other.path);
  }
}
