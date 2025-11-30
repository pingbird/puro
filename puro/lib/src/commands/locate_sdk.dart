import 'dart:async';

import '../command.dart';
import '../command_result.dart';
import '../env/default.dart';
import '../terminal.dart';

class LocateSdkCommand extends PuroCommand {
  @override
  final name = 'sdk';

  @override
  // Command will be used by tools,
  // so there's no way to react anyways
  final allowUpdateCheck = false;

  @override
  final description = '''Prints the SDK path of the current environment.

This can be used to configure vscode://settings/dart.getFlutterSdkCommand
to automatically pick up the SDK of your puro environment.

See https://github.com/Dart-Code/Dart-Code/pull/5377''';

  @override
  Future<CommandResult>? run() async {
    final environment = await getProjectEnvOrDefault(scope: scope);
    final path = environment.flutter.sdkDir.absolute.path;
    return BasicMessageResult(
      path,
      type: CompletionType.plain,
    );
  }
}
