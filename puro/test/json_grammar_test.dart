import 'package:puro/src/json_edit/element.dart';
import 'package:puro/src/json_edit/grammar.dart';
import 'package:test/test.dart';

void main() {
  test('Special chars', () {
    for (final entry in JsonGrammar.escapeChars.entries) {
      final result = JsonGrammar.parse('"\\${entry.key}"');
      final value = result.value;
      expect(value, isA<JsonLiteral>());
      expect((value as JsonLiteral).value.value, entry.value);
    }
  });
}
