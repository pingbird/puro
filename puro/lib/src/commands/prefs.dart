import '../command.dart';
import '../command_result.dart';
import '../config.dart';
import '../terminal.dart';

class PrefsCommand extends PuroCommand {
  @override
  final name = '_prefs';

  @override
  final description = 'Manages hidden configuration settings';

  @override
  bool get hidden => true;

  @override
  String? get argumentUsage => '<key> [value]';

  @override
  Future<CommandResult> run() async {
    final args = unwrapArguments(atMost: 2);
    final config = PuroConfig.of(scope);
    if (args.isEmpty) {
      final prefs = await readGlobalPrefs(scope: scope);
      return BasicMessageResult(
        prettyJsonEncoder.convert(prefs.toProto3Json()),
        type: CompletionType.info,
      );
    }
    final vars = PuroInternalPrefsVars(scope: scope, config: config);
    if (args.length > 1) {
      await vars.writeVar(args[0], args[1]);
      return BasicMessageResult('Updated ${args[0]}');
    } else {
      final dynamic value = await vars.readVar(args[0]);
      return BasicMessageResult(
        '${args[0]} = ${prettyJsonEncoder.convert(value)}',
        type: CompletionType.info,
      );
    }
  }
}
