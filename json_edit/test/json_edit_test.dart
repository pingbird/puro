import 'package:json_edit/src/editor.dart';
import 'package:test/test.dart';

String _indentString(
  String input,
  String indent,
) {
  return input.split('\n').map((e) => '$indent$e').join('\n');
}

void testcase(
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

void main() {
  test('Expand empty map', () {
    testcase(
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
    testcase(
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
    testcase(
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
    testcase(
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
    testcase(
      '{}',
      ['a'],
      'b',
      '''{
  "a": "b"
}''',
    );
  });

  test('Expand empty list with literal', () {
    testcase(
      '[]',
      [0],
      'b',
      '''[
  "b"
]''',
    );
  });

  test('Expand empty map with literal and comment', () {
    testcase(
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
    testcase(
      '[ /*hi*/ ]',
      [0],
      'b',
      '''[
  /*hi*/
  "b"
]''',
    );
  });

  test('Dont expand map single-line siblings', () {
    testcase(
      '{"x": "y"}',
      ['a'],
      {'b': 'c'},
      '{"x": "y", "a": {"b": "c"}}',
    );
  });

  test('Dont expand list single-line siblings', () {
    testcase(
      '["a"]',
      [1],
      {'b': 'c'},
      '["a", {"b": "c"}]',
    );
  });

  test('Dont expand map single-line siblings with comment', () {
    testcase(
      '{"x": "y" /*hi*/ }',
      ['a'],
      {'b': 'c'},
      '{"x": "y" /*hi*/, "a": {"b": "c"}}',
    );
  });

  test('Dont expand list single-line siblings with comment', () {
    testcase(
      '["a" /*hi*/ ]',
      [1],
      {'b': 'c'},
      '["a" /*hi*/, {"b": "c"}]',
    );
  });

  test('Empty multiline map', () {
    testcase(
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
    testcase(
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
    testcase(
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
    testcase(
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
    testcase(
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
    testcase(
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
    testcase(
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
    testcase(
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
    testcase(
      '{"a": "b"}',
      ['a'],
      {'b': 'c'},
      '''{"a": {"b": "c"}}''',
    );
  });

  test('Overwrite in list', () {
    testcase(
      '["a"]',
      [0],
      {'a': 'b'},
      '''[{"a": "b"}]''',
    );
  });

  test('Overwrite in multiline map', () {
    testcase(
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
    testcase(
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
    testcase(
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
}
