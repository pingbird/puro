import 'dart:convert';

import 'package:petitparser/core.dart';

abstract class JsonElement {
  Object? toJson();
  MapEntry<String, dynamic> toMapEntry() =>
      throw ArgumentError('$runtimeType is not a map entry');
  Iterable<Token<JsonElement>> get children;
  String toJsonString();
}

String _indentString(
  String input, [
  bool skipFirstLine = false,
  int indent = 1,
]) {
  final lines = input.split('\n');
  if (skipFirstLine) {
    if (lines.length == 1) return lines.first;
    return '${lines.first}\n${lines.skip(1).map((e) => '${'  ' * indent}$e').join('\n')}';
  } else {
    return lines.map((e) => '  $e').join('\n');
  }
}

class JsonWhitespace extends JsonElement {
  JsonWhitespace({
    required this.leading,
    required this.body,
    required this.trailing,
  });

  String leading;
  Token<JsonElement> body;
  String trailing;

  @override
  Iterable<Token<JsonElement>> get children => [body];

  @override
  Object? toJson() => body.value.toJson();

  @override
  MapEntry<String, dynamic> toMapEntry() => body.value.toMapEntry();

  @override
  String toString() {
    return 'Whitespace(\n'
        '  leading: ${jsonEncode(leading)}\n'
        '  body: ${_indentString('${body.value}', true)}\n'
        '  trailing: ${jsonEncode(trailing)}\n'
        ')';
  }

  @override
  String toJsonString() => '$leading${body.value.toJsonString()}$trailing';
}

class JsonMap extends JsonElement {
  JsonMap({
    required this.children,
    required this.space,
  });

  @override
  final List<Token<JsonMapEntry>> children;
  final String space;

  Token<JsonMapEntry>? operator [](String key) {
    return children.cast<Token<JsonMapEntry>?>().firstWhere(
          (child) => child!.value.key.value == key,
          orElse: () => null,
        );
  }

  @override
  Object? toJson() {
    return Map<String, dynamic>.fromEntries([
      for (final child in children) child.value.toMapEntry(),
    ]);
  }

  @override
  String toString() {
    if (space.isNotEmpty) {
      if (children.isEmpty) {
        return 'JsonMap(children: [], space: ${jsonEncode(space)})';
      }
      return 'JsonMap(\n'
          '  children: [\n'
          '    ${children.map((e) => '${_indentString('${e.value}', false, 2)}\n').join()}'
          '  ],\n'
          '  space: ${jsonEncode(space)}\n'
          ')';
    } else {
      if (children.isEmpty) return 'JsonMap(children: [])';
      return 'JsonMap(children: [\n'
          '${children.map((e) => '${_indentString('${e.value}')}\n').join()}'
          '])';
    }
  }

  @override
  String toJsonString() {
    throw UnimplementedError();
  }
}

class JsonArray extends JsonElement {
  JsonArray({
    required this.children,
    required this.space,
  });

  @override
  List<Token<JsonElement>> children;
  String space;

  Token<JsonElement> operator [](int index) {
    return children[index];
  }

  @override
  Object? toJson() {
    return [
      for (final child in children) child.value.toJson(),
    ];
  }

  @override
  String toString() {
    if (space.isNotEmpty) {
      if (children.isEmpty) {
        return 'JsonArray(children: [], space: ${jsonEncode(space)})';
      }
      return 'JsonArray(\n'
          '  children: [\n'
          '    ${children.map((e) => '${_indentString('${e.value}', false, 2)}\n').join()}'
          '  ],\n'
          '  space: ${jsonEncode(space)}\n'
          ')';
    } else {
      if (children.isEmpty) return 'JsonArray(children: [])';
      return 'JsonArray(children: [\n'
          '${children.map((e) => '${_indentString('${e.value}')}\n').join()}'
          '])';
    }
  }

  @override
  String toJsonString() {
    return '{${children.map((e) => e.value.toJsonString()).join()}$space}';
  }
}

class JsonMapEntry extends JsonElement {
  JsonMapEntry({
    required this.beforeKey,
    required this.key,
    required this.afterKey,
    required this.value,
  });

  String beforeKey;
  Token<String> key;
  String afterKey;
  Token<JsonElement> value;

  @override
  Iterable<Token<JsonElement>> get children => [value];

  @override
  MapEntry<String, dynamic> toMapEntry() {
    return MapEntry<String, dynamic>(key.value, value.value.toJson());
  }

  @override
  Object? toJson() => value.value.toJson();

  @override
  String toString() {
    return 'JsonMapEntry(\n'
        '  beforeKey: ${jsonEncode(beforeKey)}\n'
        '  key: ${jsonEncode(key.value)}\n'
        '  afterKey: ${jsonEncode(afterKey)}\n'
        '  value: ${_indentString('${value.value}', true)}\n'
        ')';
  }

  @override
  String toJsonString() {
    return '$beforeKey${key.input}$afterKey:${value.value.toJsonString()}';
  }
}

class JsonLiteral extends JsonElement {
  JsonLiteral({required this.value});

  Token<Object?> value;

  @override
  Object? toJson() => value.value;

  @override
  String toString() {
    return 'JsonLiteral(value: ${jsonEncode(value.value)})';
  }

  @override
  Iterable<Token<JsonElement>> get children => const [];

  @override
  String toJsonString() => value.input;
}
