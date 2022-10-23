import 'package:petitparser/petitparser.dart';

import 'element.dart';

class JsonGrammar extends GrammarDefinition<Token<JsonElement>> {
  static Token<JsonElement> parse(String input) =>
      JsonGrammar().build<Token<JsonElement>>().parse(input).value;

  @override
  Parser<Token<JsonElement>> start() => ref0(element).end();

  Parser<Token<JsonElement>> element() => [
        literalElement(),
        mapElement(),
        arrayElement(),
      ].toChoiceParser(failureJoiner: selectFarthestJoined).cast();

  Parser<String> lineComment() {
    return (string('//') & Token.newlineParser().neg().star()).flatten();
  }

  Parser<String> inlineComment() {
    return (string('/*') & any().starLazy(string('*/')) & string('*/'))
        .flatten();
  }

  Parser<String> space() {
    return (whitespace() | lineComment() | inlineComment()).star().flatten();
  }

  Parser<Token<JsonElement>> token(Parser<JsonElement> parser) {
    return (ref0(space) & parser.token() & ref0<String>(space))
        .token()
        .map((token) {
      final res = token.value;
      final leading = res[0] as String;
      final body = res[1] as Token<JsonElement>;
      final trailing = res[2] as String;
      if (leading.isEmpty && trailing.isEmpty) {
        return body;
      } else {
        return token.map(
          (res) => JsonWhitespace(
            leading: leading,
            body: body,
            trailing: trailing,
          ),
        );
      }
    });
  }

  Parser<String> escapedChar() =>
      (char(r'\') & pattern(escapeChars.keys.join()))
          .pick(1)
          .map((Object? str) => escapeChars[str]!);

  Parser<String> unicodeChar() =>
      (string(r'\u') & pattern('0-9A-Fa-f').times(4)).map((digits) {
        final charCode = int.parse((digits[1] as List).join(), radix: 16);
        return String.fromCharCode(charCode);
      });

  Parser<String> stringLiteral() {
    return (char('"') &
            (pattern(r'^"\') |
                    ref0<String>(escapedChar) |
                    ref0<String>(unicodeChar))
                .star()
                .map<String>((list) => list.join()) &
            char('"'))
        .pick(1)
        .cast();
  }

  Parser<bool> trueLiteral() => string('true').map((_) => true);
  Parser<bool> falseLiteral() => string('false').map((_) => false);
  Parser<void> nullLiteral() => string('null').map((_) {});
  Parser<num> numLiteral() => (char('-').optional() &
          char('0').or(digit().plus()) &
          char('.').seq(digit().plus()).optional() &
          pattern('eE')
              .seq(pattern('-+').optional())
              .seq(digit().plus())
              .optional())
      .flatten()
      .map(num.parse);

  Parser<Token<JsonElement>> literalElement() {
    return token([
      ref0(trueLiteral),
      ref0(falseLiteral),
      ref0(nullLiteral),
      ref0(numLiteral),
      ref0(stringLiteral),
    ].toChoiceParser().token().map(
          (str) => JsonLiteral(value: str),
        ));
  }

  Parser<Token<JsonElement>> mapElement() {
    return token((char('{') &
            ref0(mapEntryElement)
                .plusSeparated(char(','))
                .map((e) => e.elements)
                .optional() &
            ref0<String>(space) &
            char('}'))
        .map((res) {
      return JsonMap(
        children: (res[1] as List? ?? <Object?>[])
            .cast<Token<JsonMapEntry>>()
            .toList(),
        space: res[2] as String,
      );
    }));
  }

  Parser<Token<JsonElement>> arrayElement() {
    return token((char('[') &
            ref0(element)
                .plusSeparated(char(','))
                .map((e) => e.elements)
                .optional() &
            ref0<String>(space) &
            char(']'))
        .map((res) {
      return JsonArray(
        children: (res[1] as List? ?? <Object?>[])
            .cast<Token<JsonElement>>()
            .toList(),
        space: res[2] as String,
      );
    }));
  }

  Parser<Token<JsonMapEntry>> mapEntryElement() {
    return (ref0(space) &
            ref0(stringLiteral).token() &
            ref0<String>(space) &
            char(':') &
            ref0<Object?>(element))
        .map((res) {
      return JsonMapEntry(
        beforeKey: res[0] as String,
        key: res[1] as Token<String>,
        afterKey: res[2] as String,
        value: res[4] as Token<JsonElement>,
      );
    }).token();
  }

  static const escapeChars = {
    '"': '"',
    r'\': r'\',
    '/': '/',
    'b': '\b',
    'f': '\f',
    'n': '\n',
    'r': '\r',
    't': '\t'
  };
}
