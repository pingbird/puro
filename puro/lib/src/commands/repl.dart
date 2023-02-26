import 'dart:async';
import 'dart:io';

import 'package:dart_console/dart_console.dart';

import '../command.dart';
import '../command_result.dart';
import '../env/default.dart';
import '../eval/context.dart';
import '../eval/packages.dart';
import '../eval/worker.dart';
import '../terminal.dart';

class ReplCommand extends PuroCommand {
  ReplCommand() {
    argParser.addFlag(
      'reset',
      abbr: 'r',
      help: 'Resets the pubspec file',
      negatable: false,
    );
    argParser.addMultiOption(
      'extra',
      abbr: 'e',
      help: 'Extra VM options to pass to the dart executable',
      splitCommas: false,
    );
  }

  @override
  final name = 'repl';

  @override
  final description = 'Interactive REPL for dart code';

  @override
  bool get allowUpdateCheck => false;

  @override
  Future<CommandResult> run() async {
    final extra = argResults!['extra'] as List<String>;
    final reset = argResults!['reset'] as bool;
    final environment = await getProjectEnvOrDefault(scope: scope);
    final context = EvalContext(scope: scope, environment: environment);
    context.importCore();

    try {
      await context.pullPackages(packages: const {}, reset: reset);
    } on EvalPubError {
      CommandMessage(
        'Pass `-r` or `--reset` to use a fresh pubspec file',
        type: CompletionType.info,
      ).queue(scope);
      rethrow;
    } on EvalError catch (e) {
      throw CommandError('$e');
    }

    final worker = await EvalWorker.spawn(
      scope: scope,
      context: context,
      extra: extra,
    );

    unawaited(worker.onExit.then((exitCode) async {
      if (exitCode != 0) {
        CommandMessage(
          'Subprocess exited with code $exitCode',
          type: CompletionType.alert,
        ).queue(scope);
      }
      await runner.exitPuro(exitCode);
    }));

    final terminal = Terminal.of(scope);
    final console = Console.scrolling(
      recordBlanks: false,
    );

    var didBreak = false;
    while (true) {
      terminal.flushStatus();
      // TODO(ping): Implement readLine in Terminal
      console.write('>>> ');
      final line = console.readLine(cancelOnBreak: true);

      if (line == null) {
        console.write('^C\n');
        if (!didBreak) {
          didBreak = true;
          continue;
        }
        // Break if ctrl-c is pressed twice in a row
        break;
      }

      try {
        final parseResult = context.transform(line);
        await worker.reload(parseResult);
        final result = await worker.run();
        if (result != null) {
          stdout.writeln(result);
        }
      } catch (e, bt) {
        stdout.writeln(terminal.format.complete(
          '$e${e is EvalError ? '' : '\n$bt'}',
          type: CompletionType.failure,
        ));
      }
    }

    await worker.dispose();
    await runner.exitPuro(0);
  }
}
