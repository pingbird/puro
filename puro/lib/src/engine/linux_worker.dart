import 'package:process/process.dart';

import '../command_result.dart';
import '../provider.dart';

Future<void> installLinuxWorkerPackages({required Scope scope}) async {
  final errors = <CommandMessage>[];
  final tryApt = <String>[];

  const pm = LocalProcessManager();
  if (!pm.canRun('python3')) {
    errors.add(CommandMessage('python3 not found in PATH'));
    tryApt.add('python3');
  }
  if (!pm.canRun('curl')) {
    errors.add(CommandMessage('curl not found in PATH'));
    tryApt.add('curl');
  }
  if (!pm.canRun('unzip')) {
    errors.add(CommandMessage('unzip not found in PATH'));
    tryApt.add('unzip');
  }

  if (errors.isNotEmpty) {
    throw CommandError.list([
      ...errors,
      if (tryApt.isNotEmpty)
        CommandMessage('Try running `sudo apt install ${tryApt.join(' ')}`')
    ]);
  }
}
