import 'dart:convert';

import 'package:petitparser/petitparser.dart';

import 'element.dart';
import 'grammar.dart';

class JsonEditor {
  JsonEditor({
    required this.source,
    required this.indentLevel,
  });

  String source;
  final int indentLevel;

  late final _indentedEncoder = JsonEncoder.withIndent(' ' * indentLevel);

  String _encodeWithoutIndent(Object? value) {
    // Hack to keep space between elements
    return const JsonEncoder.withIndent('')
        .convert(value)
        .split('\n')
        .join()
        .trim();
  }

  Object? _wrapWithSelector(Iterable<Object> selectors, Object? value) {
    if (selectors.isEmpty) return value;
    final selector = selectors.last;
    if (selector is String) {
      value = <String, dynamic>{selector: value};
    } else if (selector is int) {
      RangeError.checkValueInInterval(
        selector,
        0,
        0,
        'selector',
        'in data${selectors.map((e) => '[${jsonEncode(e)}]').join()}',
      );
      value = <dynamic>[value];
    } else {
      throw ArgumentError('Unrecognized selector: ${selector.runtimeType}');
    }
    return _wrapWithSelector(selectors.take(selectors.length - 1), value);
  }

  bool _validOffset(int offset) => offset >= 0 && offset < source.length;

  bool _spaceAt(int offset) => _validOffset(offset) && source[offset] == ' ';

  bool _whitespaceAt(int offset) =>
      _validOffset(offset) &&
      const WhitespaceCharPredicate().test(source.codeUnitAt(offset));

  bool _newlineAt(int offset) => _validOffset(offset) && source[offset] == '\n';

  int _indentAt(int offset) {
    // Find start of line
    while (_validOffset(offset - 1) && !_newlineAt(offset - 1)) offset--;
    // Count number of spaces to the right
    var indent = 0;
    while (_spaceAt(offset)) {
      offset++;
      indent++;
    }
    return indent;
  }

  String _indentString(
    String input,
    String indent, {
    bool indentFirstLine = true,
  }) {
    final lines = input.split('\n');
    if (indentFirstLine) {
      return lines.map((e) => '$indent$e').join('\n');
    } else {
      if (lines.length == 1) return lines.first;
      return '${lines.first}\n${lines.skip(1).map((e) => '$indent$e').join('\n')}';
    }
  }

  void update(
    List<Object> selectors,
    Object? value, {
    bool create = false,
  }) {
    if (selectors.isEmpty) {
      source = _indentedEncoder.convert(value);
      return;
    }

    Token<JsonElement>? token = JsonGrammar.parse(source);
    late Token<JsonElement> collectionToken;
    late Object collectionSelector;
    var selectorDesc = 'data';
    for (var i = 0; i < selectors.length; i++) {
      final selector = selectors[i];
      if (token == null) {
        if (create) {
          return update(
            selectors.take(i).toList(),
            _wrapWithSelector(selectors.skip(i), value),
          );
        } else {
          throw ArgumentError('$selectorDesc not found');
        }
      }
      var element = token.value;
      if (element is JsonMapEntry) {
        token = element.value;
        element = token.value;
      } else if (element is JsonWhitespace) {
        token = element.body;
        element = token.value;
      }
      collectionToken = token;
      collectionSelector = selector;
      if (selector is String) {
        if (element is! JsonMap) {
          throw ArgumentError(
            'Attempt to index $selectorDesc (a ${element.runtimeType}) with String',
          );
        }
        token = element[selector];
      } else if (selector is int) {
        if (element is! JsonArray) {
          throw ArgumentError(
            'Attempt to index $selectorDesc (a ${element.runtimeType}) with int',
          );
        }
        RangeError.checkValidIndex(
          selector,
          element.children,
          'selector',
          element.children.length + 1,
          'in $selectorDesc',
        );
        token = selector == element.children.length ? null : element[selector];
      } else {
        throw ArgumentError('Unrecognized selector: ${selector.runtimeType}');
      }
      selectorDesc += '[${jsonEncode(selector)}]';
    }

    int replaceStart;
    int replaceEnd;
    var leading = '';
    var trailing = '';
    int? indent;
    var indentFirstLine = true;

    final collectionElement = collectionToken.value;
    final collectionIndent = _indentAt(collectionToken.start);
    final collectionStartLine = collectionToken.line;
    final collectionEndLine =
        Token.lineAndColumnOf(collectionToken.buffer, collectionToken.stop)[0];
    final collectionSpace = collectionElement is JsonMap
        ? collectionElement.space
        : (collectionElement as JsonArray).space;
    final trimmedCollectionSpace = collectionSpace.trim();

    if (token == null) {
      if (collectionStartLine == collectionEndLine) {
        if (collectionElement.children.isEmpty) {
          // Collection begins and ends on the same line, expand it
          replaceStart = collectionToken.start + 1;
          replaceEnd = collectionToken.stop - 1;
          leading = '\n';
          indent = collectionIndent + indentLevel;
          if (trimmedCollectionSpace.isNotEmpty) {
            // Shift comments to a new line too
            leading +=
                _indentString(trimmedCollectionSpace, ' ' * indent) + '\n';
          }
          trailing += '\n${' ' * collectionIndent}';
        } else {
          // Collection has other children on the same line, keep it that way
          if (trimmedCollectionSpace.isNotEmpty) {
            replaceStart = collectionToken.stop - (collectionSpace.length + 1);
            leading = ',$collectionSpace ';
          } else {
            leading = ', ';
            replaceStart = collectionToken.stop - 1;
            while (_spaceAt(replaceStart - 1)) replaceStart--;
          }
          replaceEnd = collectionToken.stop - 1;
        }
      } else {
        replaceEnd = collectionToken.stop - 1;
        indent = collectionIndent + indentLevel;
        if (collectionElement.children.isNotEmpty) {
          var lastChild = collectionElement.children.last.value;
          var lastChildTrailingSpace = '';
          if (lastChild is JsonMapEntry) {
            lastChild = lastChild.value.value;
          }
          if (lastChild is JsonWhitespace) {
            lastChildTrailingSpace = lastChild.trailing;
          }
          replaceStart = collectionElement.children.last.stop -
              lastChildTrailingSpace.length;
          leading = ',${lastChildTrailingSpace.trimRight()}';
        } else {
          replaceStart = collectionToken.stop - 1;
          while (_whitespaceAt(replaceStart - 1)) replaceStart--;
        }
        leading += '\n';
        trailing = '\n${' ' * collectionIndent}';
      }

      // Add the map key
      if (collectionElement is JsonMap) {
        if (indentFirstLine && indent != null) {
          leading += ' ' * indent;
          indentFirstLine = false;
        }
        leading += '${_encodeWithoutIndent(collectionSelector)}: ';
      }
    } else {
      var element = token.value;
      var overwriteToken = token;
      if (element is JsonMapEntry) {
        overwriteToken = element.value;
        element = overwriteToken.value;
      }
      if (element is JsonWhitespace) {
        overwriteToken = element.body;
        element = overwriteToken.value;
      }
      if (collectionStartLine == collectionEndLine) {
        replaceStart = overwriteToken.start;
        replaceEnd = overwriteToken.stop;
      } else {
        indentFirstLine = false;
        indent = _indentAt(overwriteToken.start);
        replaceStart = overwriteToken.start;
        replaceEnd = overwriteToken.stop;
      }
    }

    assert(replaceStart <= replaceEnd);

    final String encodedValue;
    if (indent != null) {
      encodedValue = _indentString(
        _indentedEncoder.convert(value),
        ' ' * indent,
        indentFirstLine: indentFirstLine,
      );
    } else {
      encodedValue = _encodeWithoutIndent(value);
    }

    source = source.substring(0, replaceStart) +
        leading +
        encodedValue +
        trailing +
        source.substring(replaceEnd);
  }

  void remove(
    List<Object> selectors, {
    bool permissive = true,
  }) {
    if (selectors.isEmpty) {
      throw ArgumentError('Cannot delete root');
    }
    Token<JsonElement>? token = JsonGrammar.parse(source);
    late Token<JsonElement> collectionToken;
    var selectorDesc = 'data';
    for (var i = 0; i < selectors.length; i++) {
      final selector = selectors[i];
      var element = token!.value;
      if (element is JsonMapEntry) {
        token = element.value;
        element = token.value;
      } else if (element is JsonWhitespace) {
        token = element.body;
        element = token.value;
      }
      collectionToken = token;
      if (selector is String) {
        if (element is! JsonMap) {
          if (permissive) return;
          throw ArgumentError(
            'Attempt to index $selectorDesc (a ${element.runtimeType}) with String',
          );
        }
        token = element[selector];
      } else if (selector is int) {
        if (element is! JsonArray) {
          if (permissive) return;
          throw ArgumentError(
            'Attempt to index $selectorDesc (a ${element.runtimeType}) with int',
          );
        }
        if (permissive &&
            (selector < 0 || selector > element.children.length)) {
          return;
        }
        RangeError.checkValidIndex(
          selector,
          element.children,
          'selector',
          element.children.length + 1,
          'in $selectorDesc',
        );
        token = selector == element.children.length ? null : element[selector];
      } else {
        throw ArgumentError('Unrecognized selector: ${selector.runtimeType}');
      }
      selectorDesc += '[${jsonEncode(selector)}]';
      if (token == null) {
        if (permissive) return;
        throw ArgumentError('$selectorDesc not found');
      }
    }

    if (token == null) {
      if (permissive) return;
      throw ArgumentError('$selectorDesc not found');
    }

    int replaceStart;
    int replaceEnd;
    var content = '';

    final collectionElement = collectionToken.value;

    String trailingSpaceOf(JsonElement element) {
      if (element is JsonMapEntry) {
        element = element.value.value;
      }
      if (element is JsonWhitespace) {
        return element.trailing;
      }
      return '';
    }

    String leadingSpaceOf(JsonElement element) {
      if (element is JsonMapEntry) {
        return element.beforeKey;
      } else if (element is JsonWhitespace) {
        return element.leading;
      } else {
        return '';
      }
    }

    final trailingSpace = trailingSpaceOf(token.value);
    final trailingSpaceNewline = trailingSpace.indexOf('\n');
    final trailingSpaceAfterEOL = trailingSpaceNewline == -1
        ? ''
        : trailingSpace.substring(trailingSpaceNewline);

    final collectionChildren = collectionElement.children.toList();
    final elementIndex = collectionChildren.indexOf(token);
    final hasChildBefore = elementIndex > 0;
    final hasChildAfter = elementIndex + 1 < collectionChildren.length;
    final collectionStartLine = collectionToken.line;
    final collectionEndLine =
        Token.lineAndColumnOf(collectionToken.buffer, collectionToken.stop)[0];
    final singleLine = collectionStartLine == collectionEndLine;
    final leadingLines = leadingSpaceOf(token.value).split('\n');
    final leadingLineAfterComma =
        !singleLine && hasChildBefore && leadingLines.isNotEmpty
            ? leadingLines.first
            : '';

    if (collectionElement.children.length == 1 &&
        trailingSpaceAfterEOL.trim().isEmpty) {
      // Only child and no comment, collapse collection
      replaceStart = collectionToken.start + 1;
      replaceEnd = collectionToken.stop - 1;
    } else {
      final removeLeadingComma = hasChildBefore && !hasChildAfter;
      replaceStart = token.start - (removeLeadingComma ? 1 : 0);
      while (removeLeadingComma && _spaceAt(replaceStart - 1)) replaceStart--;

      final removeTrailingComma = hasChildAfter;
      replaceEnd = token.stop + (removeTrailingComma ? 1 : 0);
      while (_spaceAt(replaceEnd)) replaceEnd++;

      content = leadingLineAfterComma + trailingSpaceAfterEOL;
      if (singleLine && hasChildBefore && hasChildAfter) {
        content += ' ';
      }

      // Remove trailing comments on the same line
      if (collectionStartLine != collectionEndLine && hasChildAfter) {
        final nextChild = collectionChildren[elementIndex + 1];
        final space = leadingSpaceOf(nextChild.value);
        final spaceNewline = space.indexOf('\n');
        if (spaceNewline > 0) {
          replaceEnd = nextChild.start + spaceNewline;
        }
      }
    }

    source = source.substring(0, replaceStart) +
        content +
        source.substring(replaceEnd);
  }

  Token<JsonElement>? query(
    List<Object> selectors, {
    bool permissive = true,
  }) {
    Token<JsonElement>? token = JsonGrammar.parse(source);
    var selectorDesc = 'data';
    for (var i = 0; i < selectors.length; i++) {
      final selector = selectors[i];
      var element = token!.value;
      if (element is JsonMapEntry) {
        token = element.value;
        element = token.value;
      } else if (element is JsonWhitespace) {
        token = element.body;
        element = token.value;
      }
      if (selector is String) {
        if (element is! JsonMap) {
          if (permissive) return null;
          throw ArgumentError(
            'Attempt to index $selectorDesc (a ${element.runtimeType}) with String',
          );
        }
        token = element[selector];
      } else if (selector is int) {
        if (element is! JsonArray) {
          if (permissive) return null;
          throw ArgumentError(
            'Attempt to index $selectorDesc (a ${element.runtimeType}) with int',
          );
        }
        if (permissive &&
            (selector < 0 || selector > element.children.length)) {
          return null;
        }
        RangeError.checkValidIndex(
          selector,
          element.children,
          'selector',
          element.children.length + 1,
          'in $selectorDesc',
        );
        token = selector == element.children.length ? null : element[selector];
      } else {
        throw ArgumentError('Unrecognized selector: ${selector.runtimeType}');
      }
      selectorDesc += '[${jsonEncode(selector)}]';
      if (token == null) {
        if (permissive) return null;
        throw ArgumentError('$selectorDesc not found');
      }
    }
    return token;
  }
}
