import 'package:puro/src/json_edit/editor.dart';
import 'package:test/test.dart';

String _indentString(
  String input,
  String indent,
) {
  return input.split('\n').map((e) => '$indent$e').join('\n');
}

void testUpdate(
  String input,
  List<Object> selectors,
  Object? value,
  String output, {
  bool create = false,
}) {
  final editor = JsonEditor(source: input, indentLevel: 2);
  editor.update(selectors, value, create: create);
  expect(editor.source, output);

  // Test again but nested inside a list:
  final editor2 = JsonEditor(
    source: '[\n${_indentString(input, '  ')}\n]',
    indentLevel: 2,
  );
  editor2.update([0, ...selectors], value, create: create);
  expect(editor2.source, '[\n${_indentString(output, '  ')}\n]');
}

void testRemove(
  String input,
  List<Object> selectors,
  String output,
) {
  final editor = JsonEditor(source: input, indentLevel: 2);
  editor.remove(selectors);
  expect(editor.source, output);

  // Test again but nested inside a list:
  final editor2 = JsonEditor(
    source: '[\n${_indentString(input, '  ')}\n]',
    indentLevel: 2,
  );
  editor2.remove([0, ...selectors]);
  expect(editor2.source, '[\n${_indentString(output, '  ')}\n]');
}

void main() {
  test('Expand empty map', () {
    testUpdate(
      '{}',
      ['a'],
      {'b': 'c'},
      '''{
  "a": {
    "b": "c"
  }
}''',
    );
  });

  test('Expand empty list', () {
    testUpdate(
      '[]',
      [0],
      {'b': 'c'},
      '''[
  {
    "b": "c"
  }
]''',
    );
  });

  test('Expand empty map with comment', () {
    testUpdate(
      '{ /*hi*/ }',
      ['a'],
      {'b': 'c'},
      '''{
  /*hi*/
  "a": {
    "b": "c"
  }
}''',
    );
  });

  test('Expand empty list with comment', () {
    testUpdate(
      '[ /*hi*/ ]',
      [0],
      {'b': 'c'},
      '''[
  /*hi*/
  {
    "b": "c"
  }
]''',
    );
  });

  test('Expand empty map with literal', () {
    testUpdate(
      '{}',
      ['a'],
      'b',
      '''{
  "a": "b"
}''',
    );
  });

  test('Expand empty list with literal', () {
    testUpdate(
      '[]',
      [0],
      'b',
      '''[
  "b"
]''',
    );
  });

  test('Expand empty map with literal and comment', () {
    testUpdate(
      '{ /*hi*/ }',
      ['a'],
      'b',
      '''{
  /*hi*/
  "a": "b"
}''',
    );
  });

  test('Expand empty list with literal and comment', () {
    testUpdate(
      '[ /*hi*/ ]',
      [0],
      'b',
      '''[
  /*hi*/
  "b"
]''',
    );
  });

  test('Test empty settings file in .vscode', () {
    testUpdate(
      '',
      ['a'],
      {'b': 'c'},
      '''{
          "a": {
            "b": "c"
          }
        }''',
    );
  });

  test('Dont expand map single-line siblings', () {
    testUpdate(
      '{"x": "y"}',
      ['a'],
      {'b': 'c'},
      '{"x": "y", "a": {"b": "c"}}',
    );
  });

  test('Dont expand list single-line siblings', () {
    testUpdate(
      '["a"]',
      [1],
      {'b': 'c'},
      '["a", {"b": "c"}]',
    );
  });

  test('Dont expand map single-line siblings with comment', () {
    testUpdate(
      '{"x": "y" /*hi*/ }',
      ['a'],
      {'b': 'c'},
      '{"x": "y" /*hi*/, "a": {"b": "c"}}',
    );
  });

  test('Dont expand list single-line siblings with comment', () {
    testUpdate(
      '["a" /*hi*/ ]',
      [1],
      {'b': 'c'},
      '["a" /*hi*/, {"b": "c"}]',
    );
  });

  test('Empty multiline map', () {
    testUpdate(
      '{\n}',
      ['a'],
      {'b': 'c'},
      '''{
  "a": {
    "b": "c"
  }
}''',
    );
  });

  test('Empty multiline list', () {
    testUpdate(
      '[\n]',
      [0],
      {'b': 'c'},
      '''[
  {
    "b": "c"
  }
]''',
    );
  });

  test('Empty multiline map with comment', () {
    testUpdate(
      '{/*a*/\n  /*b*/}',
      ['a'],
      {'b': 'c'},
      '''{/*a*/
  /*b*/
  "a": {
    "b": "c"
  }
}''',
    );
  });

  test('Empty multiline list with comment', () {
    testUpdate(
      '[/*a*/\n  /*b*/]',
      [0],
      {'b': 'c'},
      '''[/*a*/
  /*b*/
  {
    "b": "c"
  }
]''',
    );
  });

  test('Multiline map with siblings', () {
    testUpdate(
      '{\n  "a": "b"\n}',
      ['x'],
      {'y': 'z'},
      '''{
  "a": "b",
  "x": {
    "y": "z"
  }
}''',
    );
  });

  test('Multiline list with siblings', () {
    testUpdate(
      '[\n  "a"\n]',
      [1],
      {'b': 'c'},
      '''[
  "a",
  {
    "b": "c"
  }
]''',
    );
  });

  test('Multiline map with siblings and comment', () {
    testUpdate(
      '{\n  "a": "b" /*a*/ \n}',
      ['x'],
      {'y': 'z'},
      '''{
  "a": "b", /*a*/
  "x": {
    "y": "z"
  }
}''',
    );
  });

  test('Multiline list with siblings and comment', () {
    testUpdate(
      '[\n  "a" /*a*/ \n]',
      [1],
      {'b': 'c'},
      '''[
  "a", /*a*/
  {
    "b": "c"
  }
]''',
    );
  });

  test('Overwrite in map', () {
    testUpdate(
      '{"a": "b"}',
      ['a'],
      {'b': 'c'},
      '''{"a": {"b": "c"}}''',
    );
  });

  test('Overwrite in list', () {
    testUpdate(
      '["a"]',
      [0],
      {'a': 'b'},
      '''[{"a": "b"}]''',
    );
  });

  test('Overwrite in multiline map', () {
    testUpdate(
      '{\n  "a": "b",\n  "c": "d"\n}',
      ['c'],
      ['deez'],
      '''{
  "a": "b",
  "c": [
    "deez"
  ]
}''',
    );
  });

  test('Overwrite in multiline list', () {
    testUpdate(
      '[\n  "a",\n  "b"\n]',
      [1],
      ['b'],
      '''[
  "a",
  [
    "b"
  ]
]''',
    );
  });

  test('Create nested', () {
    testUpdate(
      '{}',
      ['a', 0, 'b'],
      'c',
      '''{
  "a": [
    {
      "b": "c"
    }
  ]
}''',
      create: true,
    );
  });

  test('Remove from map', () {
    testRemove(
      '{"a": "b"}',
      ['a'],
      '{}',
    );
  });

  test('Remove from list', () {
    testRemove(
      '["a"]',
      [0],
      '[]',
    );
  });

  test('Remove from map with comments', () {
    testRemove(
      '{ /*a*/ "a": "b" /*b*/ }',
      ['a'],
      '{}',
    );
  });

  test('Remove from list with comments', () {
    testRemove(
      '[ /*a*/ "a" /*b*/ ]',
      [0],
      '[]',
    );
  });

  test('Remove first from map', () {
    testRemove(
      '{"a": "b", "c": "d"}',
      ['a'],
      '{"c": "d"}',
    );
  });

  test('Remove first from list', () {
    testRemove(
      '["a", "b"]',
      [0],
      '["b"]',
    );
  });

  test('Remove first from map with comments', () {
    testRemove(
      '{ /*a*/ "a": "b" /*b*/ , /*c*/ "c": "d"}',
      ['a'],
      '{/*c*/ "c": "d"}',
    );
  });

  test('Remove first from list with comments', () {
    testRemove(
      '[ /*a*/ "a" /*b*/ , /*c*/ "b"]',
      [0],
      '[/*c*/ "b"]',
    );
  });

  test('Remove last from map', () {
    testRemove(
      '{"a": "b", "c": "d"}',
      ['c'],
      '{"a": "b"}',
    );
  });

  test('Remove last from list', () {
    testRemove(
      '["a", "b"]',
      [1],
      '["a"]',
    );
  });

  test('Remove last from map with comments', () {
    testRemove(
      '{"a": "b" /*a*/ , /*b*/ "c": "d" /*c*/}',
      ['c'],
      '{"a": "b" /*a*/}',
    );
  });

  test('Remove last from list with comments', () {
    testRemove(
      '["a" /*a*/ , /*b*/ "b" /*c*/]',
      [1],
      '["a" /*a*/]',
    );
  });

  test('Remove middle from map', () {
    testRemove(
      '{"a": "b", "c": "d", "e": "f"}',
      ['c'],
      '{"a": "b", "e": "f"}',
    );
  });

  test('Remove middle from list', () {
    testRemove(
      '["a", "b", "c"]',
      [1],
      '["a", "c"]',
    );
  });

  test('Remove middle from map with comments', () {
    testRemove(
      '{"a": "b" /*a*/ , /*b*/ "c": "d" /*c*/ , /*d*/ "e": "f"}',
      ['c'],
      '{"a": "b" /*a*/ , /*d*/ "e": "f"}',
    );
  });

  test('Remove middle from list with comments', () {
    testRemove(
      '["a" /*a*/ , /*b*/ "b" /*c*/ , /*d*/ "c"]',
      [1],
      '["a" /*a*/ , /*d*/ "c"]',
    );
  });

  test('Remove from multiline map', () {
    testRemove(
      '''{
  "a": "b"
}''',
      ['a'],
      '{}',
    );
  });

  test('Remove from multiline list', () {
    testRemove(
      '''[
  "a"
]''',
      [0],
      '[]',
    );
  });

  test('Remove from multiline map with comments', () {
    testRemove(
      '''{ /*a*/
  /*b*/ 
  "x": "y" /*c*/ 
  /*d*/ 
}''',
      ['x'],
      '''{
  /*d*/ 
}''',
    );
  });

  test('Remove from multiline list with comments', () {
    testRemove(
      '''[ /*a*/
  /*b*/ 
  "x" /*c*/ 
  /*d*/ 
]''',
      [0],
      '''[
  /*d*/ 
]''',
    );
  });

  test('Remove first from multiline map', () {
    testRemove(
      '''{
  "a": "b",
  "c": "d"
}''',
      ['a'],
      '''{
  "c": "d"
}''',
    );
  });

  test('Remove first from multiline list', () {
    testRemove(
      '''[
  "a",
  "b"
]''',
      [0],
      '''[
  "b"
]''',
    );
  });

  test('Remove first from multiline map with comments', () {
    testRemove(
      '''{ /*a*/ 
  /*b*/ 
  "a": "b", /*c*/ 
  /*d*/ 
  "c": "d"
}''',
      ['a'],
      '''{
  /*d*/ 
  "c": "d"
}''',
    );
  });

  test('Remove first from multiline list with comments', () {
    testRemove(
      '''[ /*a*/ 
  /*b*/ 
  "a", /*c*/ 
  /*d*/ 
  "b"
]''',
      [0],
      '''[
  /*d*/ 
  "b"
]''',
    );
  });

  test('Remove last from multiline map', () {
    testRemove(
      '''{
  "a": "b",
  "c": "d"
}''',
      ['c'],
      '''{
  "a": "b"
}''',
    );
  });

  test('Remove last from multiline list', () {
    testRemove(
      '''[
  "a",
  "b"
]''',
      [1],
      '''[
  "a"
]''',
    );
  });

  test('Remove last from multiline map with comments', () {
    testRemove(
      '''{
  "a": "b" /*a*/ , /*b*/ 
  /*c*/ "c": "d" /*d*/
}''',
      ['c'],
      '''{
  "a": "b" /*a*/ /*b*/ 
}''',
    );
  });

  test('Remove last from multiline list with comments', () {
    testRemove(
      '''[
  "a" /*a*/ , /*b*/ 
  /*c*/ "b" /*d*/
]''',
      [1],
      '''[
  "a" /*a*/ /*b*/ 
]''',
    );
  });

  test('Remove middle from multiline map', () {
    testRemove(
      '''{
  "a": "b",
  "c": "d",
  "e": "f"
}''',
      ['c'],
      '''{
  "a": "b",
  "e": "f"
}''',
    );
  });

  test('Remove middle from multiline list', () {
    testRemove(
      '''[
  "a",
  "b",
  "c"
]''',
      [1],
      '''[
  "a",
  "c"
]''',
    );
  });

  test('Remove middle from multiline map with comments', () {
    testRemove(
      '''{
  "a": "b" /*a*/ , /*b*/ 
  /*c*/ "c": "d" /*d*/ , /*e*/ 
  /*f*/ "e": "f"
}''',
      ['c'],
      '''{
  "a": "b" /*a*/ , /*b*/ 
  /*f*/ "e": "f"
}''',
    );
  });

  test('Remove middle from multiline list with comments', () {
    testRemove(
      '''[
  "a" /*a*/ , /*b*/ 
  /*c*/ "b" /*d*/ , /*e*/ 
  /*f*/ "c"
]''',
      [1],
      '''[
  "a" /*a*/ , /*b*/ 
  /*f*/ "c"
]''',
    );
  });
}
