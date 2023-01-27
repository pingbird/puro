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
    final code = argResults!.rest.join(' ');
    final worker = await EvalWorker.spawn(scope: scope);
    try {
      final result = await worker.evaluate(code);
      worker.dispose();
      if (result != null) {
        return BasicMessageResult(result);
      } else {
        await runner.exitPuro(0);
      }
    } on EvalError catch (e) {
      throw CommandError('$e');
    }
  }
}
