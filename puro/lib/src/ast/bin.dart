import 'dart:typed_data';

import 'package:typed_data/typed_buffers.dart';

class Reader {
  Reader(this.fmt, this._bytes);

  final BinFormat fmt;
  final Uint8List _bytes;
  var _byteOffset = 0;
  int get byteOffset => _byteOffset;
  int readByte() => _bytes[_byteOffset++];
  int peekByte() => _bytes[_byteOffset];
  final fields = <String, Uint8Buffer>{};

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

  int readUint32() {
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
    bytes.setRange(0, bytes.length, _bytes, _byteOffset);
    _byteOffset += bytes.length;
    return bytes;
  }

  Uint8List readByteList() {
    return readBytes(readUInt30());
  }

  Uint8List readOrViewByteList() {
    final length = readUInt30();
    final source = _bytes;
    final Uint8List view =
        source.buffer.asUint8List(source.offsetInBytes + _byteOffset, length);
    _byteOffset += length;
    return view;
  }

  void addByte(String name, int value) {
    final buf = fields[name] ??= Uint8Buffer();
    buf.add(value);
  }

  void addInt32(String name, int value) {
    final buf = fields[name] ??= Uint8Buffer();
    buf.length += 4;
    buf.buffer.asByteData().setInt32(buf.length - 4, value);
  }

  void addInt64(String name, int value) {
    final buf = fields[name] ??= Uint8Buffer();
    buf.length += 8;
    buf.buffer.asByteData().setInt64(buf.length - 8, value);
  }

  void addDouble(String name, double value) {
    final buf = fields[name] ??= Uint8Buffer();
    buf.length += 8;
    buf.buffer.asByteData().setFloat64(buf.length - 8, value);
  }

  void addBytes(String name, Uint8List value) {
    final buf = fields[name] ??= Uint8Buffer();
    buf.addAll(value);
  }

  void readType(String prefix, BinType c) {
    if (c is NamedBinType) {
      final cl = fmt.classes[c.name]!;
      for (final field in cl.fields.entries) {
        readType('$prefix.${field.key}', field.value);
      }
    } else {
      throw UnimplementedError('Unknown type: $c');
    }
  }
}

class BinFormat {
  BinFormat(this.classes);
  final Map<String, BinClass> classes;
}

class BinClass {
  BinClass(this.fields);
  final Map<String, BinType> fields;
}

abstract class BinType {}

class NamedBinType extends BinType {
  NamedBinType(this.name);
  final String name;
}

class ListBinType extends BinType {
  ListBinType(this.elementType);
  final BinType elementType;
}

class RListBinType extends BinType {
  RListBinType(this.elementType);
  final BinType elementType;
}

class OptionalBinType extends BinType {
  OptionalBinType(this.elementType);
  final BinType elementType;
}

class PairBinType extends BinType {
  PairBinType(this.firstType, this.secondType);
  final BinType firstType;
  final BinType secondType;
}