import 'package:petitparser/petitparser.dart';

class BinaryMdGrammar extends GrammarDefinition<dynamic> {
  @override
  Parser start() => ref0(topLevelDecls).end();

  Parser topLevelDecls() =>
      ref0(topLevelDecl).star().map((e) => e.nonNulls.toList());

  final ignoreDecls = {
    ['Byte flags (flag1, flag2, ..., flagN)'],
    ['Byte byte (10xxxxxx)'],
    ['type Byte = a byte'],
    ['abstract type UInt {}'],
    ['type UInt7 extends UInt {', '  Byte byte1(0xxxxxxx);', '}'],
    [
      'type UInt14 extends UInt {',
      '  Byte byte1(10xxxxxx);',
      '  Byte byte2(xxxxxxxx);',
      '}',
    ],
    [
      'type UInt30 extends UInt {',
      '  Byte byte1(11xxxxxx);',
      '  Byte byte2(xxxxxxxx);',
      '  Byte byte3(xxxxxxxx);',
      '  Byte byte4(xxxxxxxx);',
      '}',
    ],
    ['type List<T> {', '  UInt length;', '  T[length] items;', '}'],
    [
      'type RList<T> {',
      '  T[length] elements;',
      '  Uint32 length;', // lol
      '}',
    ],
    ['type RList<T> {', '  T[length] elements;', '  UInt32 length;', '}'],
    ['type Pair<T0, T1> {', '  T0 first;', '  T1 second;', '}'],
    ['type Option<T> {', '  Byte tag;', '}'],
    ['type Nothing extends Option<T> {', '  Byte tag = 0;', '}'],
    [
      'type Something<T> extends Option<T> {',
      '  Byte tag = 1;',
      '  T value;',
      '}',
    ],
    ['type UInt32 = big endian 32-bit unsigned integer'],
    ['type Double = Double-precision floating-point number.'],
  };

  Parser topLevelDecl() => [
    for (final ignoreDecl in ignoreDecls)
      [
        for (final line in ignoreDecl) string(line.trim()).trim(space()),
      ].toSequenceParser().map((e) => null),
    ref0(typeDecl),
    ref0(enumDecl),
    failure(message: 'Expected top-level declaration'),
  ].map((e) => e.trim(space())).toChoiceParser();

  Parser typeDecl() =>
      (string('abstract ').optional() &
              string('type') &
              ref0(identifier).trim(space()) &
              (string('extends') & ref0(identifier).trim(space()))
                  .pick(1)
                  .optional() &
              string('{') &
              ref0(fieldDecl).star() &
              string('}'))
          .map(
            (e) => {
              'type': [e[0] != null, e[2], e[3], e[5]],
            },
          );

  Parser enumDecl() =>
      (string('enum') &
              ref0(identifier) &
              string('{') &
              ((ref0(identifier) &
                              string('=').trim(space()) &
                              digit().star().flatten().trim(space()) &
                              string(',').trim(space()).optional())
                          .map((e) => [e[0], e[2]]) |
                      (ref0(identifier) & string(',').trim(space()).optional())
                          .map((e) => [e[0], null]))
                  .star() &
              string('}'))
          .map(
            (e) => {
              'enum': [e[1], e[3]],
            },
          );

  Parser tpeInner() => [
    string('Uint').map((e) => 'UInt'), // lol
    string('UInt30').map((e) => 'UInt'), // lol
    (string('List<') & ref0(tpe) & string('>')).pick(1).map((e) => {'list': e}),
    (string('RList<') & ref0(tpe) & string('>'))
        .pick(1)
        .map((e) => {'rlist': e}),
    (string('Option<') & ref0(tpe) & string('>'))
        .pick(1)
        .map((e) => {'option': e}),
    (string('Pair<') &
            ref0(tpe) &
            string(',').trim(space()) &
            ref0(tpe) &
            string('>'))
        .map(
          (e) => {
            'pair': [e[1], e[3]],
          },
        ),
    (string('[') & ref0(tpe) & string(',') & ref0(tpe) & string(']')).map(
      (e) => {
        'pair': [e[1], e[3]],
      },
    ),
    identifier(),
  ].toChoiceParser().trim(space());

  Parser tpeArr() =>
      (ref0(tpeInner) &
              (string('[') &
                      any().starLazy(string(']')).flatten() &
                      string(']'))
                  .optional())
          .map(
            (e) => e[1] != null
                ? {
                    'array': [e[0], e[1][1]],
                  }
                : e[0],
          )
          .trim(space());

  Parser tpe() =>
      (ref0(tpeArr) & (string('|') & ref0(tpe)).pick(1).optional()).map(
        (e) => e[1] != null
            ? {
                'union': [e[0], e[1]],
              }
            : e[0],
      );

  Parser fieldDecl() => [
    (string('Byte') &
            ref0(identifier) &
            ((string('; // Index into') &
                        string(' the').optional() &
                        ref0(identifier) &
                        string(' above.'))
                    .pick(2) |
                (string('; // Index into') &
                        string(' the').optional() &
                        ref0(identifier) &
                        string('enum above.'))
                    .pick(2)))
        .map(
          (e) => {
            'field': [e[2], e[1], null],
          },
        ),
    (ref0(tpe) &
            (ref0(space).optional() & ref0(identifier)).pick(1) &
            ((string('=') & space() & any().plusLazy(string(';')).flatten())
                        .pick(2)
                        .optional() &
                    string(';'))
                .pick(0))
        .map(
          (e) => {
            'field': [e[0], e[1], e[2]],
          },
        ),
    (string('if name begins with \'_\' {') & ref0(fieldDecl) & string('}'))
        .pick(1)
        .map(
          (e) => {
            'field': [
              {'ifPrivate': e['field'][0]},
              e['field'][1],
              e['field'][2],
            ],
          },
        ),
    (ref0(tpe) &
            ref0(identifier) &
            pattern('{(') &
            (ref0(identifier) & string(',').trim(ref0(space)).optional())
                .pick(0)
                .star() &
            pattern('})') &
            string(';'))
        .map(
          (e) => {
            'bitfield': [e[0], e[1], e[3]],
          },
        ),
  ].toChoiceParser(failureJoiner: selectFarthest).trim(ref0(space));

  Parser<String> lineComment() {
    return (string('//') & Token.newlineParser().neg().star()).flatten();
  }

  Parser<String> inlineComment() {
    return (string('/*') & any().starLazy(string('*/')) & string('*/'))
        .flatten();
  }

  Parser<String> space() {
    return (whitespace() | lineComment() | inlineComment()).plus().flatten();
  }

  Parser<String> notSpace() => any().plusLazy(space()).flatten();

  Parser<String> identifier() =>
      (letter() | digit() | string('_')).plus().flatten().trim(space());
}
