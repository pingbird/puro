// This is a work in progress

import 'dart:typed_data';

import 'package:typed_data/typed_buffers.dart';

import 'reader.dart';

class BinReader extends Reader {
  BinReader(this.fmt, super.bytes);

  final BinFormat fmt;

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

  void readType(String name, BinType c) {
    final delim = name.isEmpty ? '' : '$name.';
    if (c is NamedBinType) {
      switch (c.name) {
        case 'Bool':
          addByte(name, readByte());
          break;
        case 'UInt':
          addInt32(name, readUInt30());
          break;
        case 'UInt32':
          addInt32(name, readUInt32());
          break;
        case 'Double':
          addDouble(name, readDouble());
          break;
        default:
          final cl = fmt.classes[c.name]!;
          for (final field in cl.fields.entries) {
            readType('$delim${c.name}.${field.key}', field.value);
          }
      }
    } else if (c is TaggedBinType) {
      final tag = readByte();
      addByte(name, tag);
      final type = c.tags[tag]!;
      readType(name, type);
    } else if (c is ListBinType) {
      final length = readUInt30();
      addInt32(name, length);
      for (var i = 0; i < length; i++) {
        readType('${delim}element', c.elementType);
      }
    } else if (c is OptionalBinType) {
      final hasValue = readByte();
      addByte(name, hasValue);
      if (hasValue != 0) {
        assert(hasValue == 1);
        readType('${delim}value', c.elementType);
      }
    } else if (c is PairBinType) {
      readType('${delim}first', c.firstType);
      readType('${delim}second', c.secondType);
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

class TaggedBinType extends BinType {
  TaggedBinType(this.tags);
  final Map<int, BinType> tags;
}

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
