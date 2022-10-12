import 'package:petitparser/petitparser.dart';

import '../lib/src/grammar.dart';

void main() {
  final grammar = JsonGrammar();
  // final value = {
  //   'hello': 'World!',
  // };
  // final input = jsonEncode(value);
  const input = '''{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": {/*awoo*/},
    "configurations": [
        {
            "name": "puro",
            "cwd": "puro",
            "request": "launch",
            "type": "dart",
            "program": "bin/puro.dart"
        }
    ]
}''';
  final result = resolve(grammar.start()).parse(input);
  if (result.isFailure) {
    final lineAndCol = Token.lineAndColumnOf(result.buffer, result.position);
    throw ArgumentError(
      'pos=${result.position} line=${lineAndCol[0]} col=${lineAndCol[1]} ${result.message}',
    );
  }
}
