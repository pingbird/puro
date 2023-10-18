// This is a work in progress

import 'dart:typed_data';

class Reader {
  Reader(this._bytes);

  final Uint8List _bytes;
  late final byteData =
      _bytes.buffer.asByteData(_bytes.offsetInBytes, _bytes.lengthInBytes);
  var byteOffset = 0;
  int readByte() => _bytes[byteOffset++];
  int peekByte() => _bytes[byteOffset];

  late final componentFileSize = byteData.getUint32(_bytes.length - 4);
  late final libraryCount = byteData.getUint32(_bytes.length - 8) + 1;
  late final libraryOffsetsStartOffset = _bytes.length - 8 - libraryCount * 4;
  late final List<int> libraryOffsets = List.generate(
    libraryCount,
    (i) => byteData.getUint32(libraryOffsetsStartOffset + i * 4),
  );
  late final magic = byteData.getUint32(0);
  late final formatVersion = byteData.getUint32(4);

  int readUInt30() {
    final int byte = readByte();
    if (byte & 0x80 == 0) {
      // 0xxxxxxx
      return byte;
    } else if (byte & 0x40 == 0) {
      // 10xxxxxx
      return ((byte & 0x3F) << 8) | readByte();
    } else {
      // 11xxxxxx
      return ((byte & 0x3F) << 24) |
          (readByte() << 16) |
          (readByte() << 8) |
          readByte();
    }
  }

  int readUInt32() {
    return (readByte() << 24) |
        (readByte() << 16) |
        (readByte() << 8) |
        readByte();
  }

  final _doubleBuffer = Float64List(1);
  Uint8List? _doubleBufferUint8;

  double readDouble() {
    final doubleBufferUint8 =
        _doubleBufferUint8 ??= _doubleBuffer.buffer.asUint8List();
    doubleBufferUint8[0] = readByte();
    doubleBufferUint8[1] = readByte();
    doubleBufferUint8[2] = readByte();
    doubleBufferUint8[3] = readByte();
    doubleBufferUint8[4] = readByte();
    doubleBufferUint8[5] = readByte();
    doubleBufferUint8[6] = readByte();
    doubleBufferUint8[7] = readByte();
    return _doubleBuffer[0];
  }

  Uint8List readBytes(int length) {
    final bytes = Uint8List(length);
    bytes.setRange(0, bytes.length, _bytes, byteOffset);
    byteOffset += bytes.length;
    return bytes;
  }

  Uint8List readByteList() {
    return readBytes(readUInt30());
  }

  Uint8List readOrViewByteList() {
    final length = readUInt30();
    final source = _bytes;
    final Uint8List view = source.buffer.asUint8List(
      source.offsetInBytes + byteOffset,
      length,
    );
    byteOffset += length;
    return view;
  }
}
