import '../command.dart';
import '../env/gc.dart';
import '../extensions.dart';

class GcCommand extends PuroCommand {
  @override
  final name = 'gc';

  @override
  final description = 'Cleans up unused caches';

  @override
  Future<CommandResult> run() async {
    final bytes = await collectGarbage(scope: scope);
    if (bytes == 0) {
      return BasicMessageResult(
        success: true,
        message: 'Nothing to clean up',
      );
    } else {
      return BasicMessageResult(
        success: true,
        message:
            'Cleaned up caches and reclaimed ${bytes.prettyAbbr(metric: true)}B',
      );
    }
  }
}
