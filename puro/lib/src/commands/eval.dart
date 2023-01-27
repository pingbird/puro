import 'dart:convert';
import 'dart:io';

import '../command.dart';
import '../command_result.dart';
import '../repl/worker.dart';

class EvalCommand extends PuroCommand {
  @override
  final name = 'eval';

  @override
  final description = 'Evaluates ephemeral Dart code';

  @override
  bool get hidden => true;

  @override
  String? get argumentUsage => '<code>';

  @override
  bool get allowUpdateCheck => false;

  @override
  Future<CommandResult> run() async {
    var code = argResults!.rest.join(' ');
    if (code.isEmpty) {
      code = await utf8.decodeStream(stdin);
    }
    final worker = await EvalWorker.spawn(scope: scope);
    try {
      final result = await worker.evaluate(code);
      worker.dispose();
      if (result != null) {
        stdout.writeln(result);
      }
      await runner.exitPuro(0);
    } on EvalError catch (e) {
      throw CommandError('$e');
    }
  }
}
