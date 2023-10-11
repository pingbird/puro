import '../command.dart';
import '../command_result.dart';
import '../env/gc.dart';
import '../extensions.dart';

class GcCommand extends PuroCommand {
  @override
  final name = 'gc';

  @override
  final description = 'Cleans up unused caches';

  @override
  Future<CommandResult> run() async {
    final bytes = await collectGarbage(
      scope: scope,
      maxUnusedCaches: 0,
      maxUnusedFlutterTools: 0,
    );
    if (bytes == 0) {
      return BasicMessageResult('Nothing to clean up');
    } else {
      return BasicMessageResult(
        'Cleaned up caches and reclaimed ${bytes.prettyAbbr(metric: true)}B',
      );
    }
  }
}
