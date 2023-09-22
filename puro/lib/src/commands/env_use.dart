import '../command.dart';
import '../command_result.dart';
import '../config.dart';
import '../env/create.dart';
import '../env/default.dart';
import '../env/releases.dart';
import '../env/version.dart';
import '../logger.dart';
import '../terminal.dart';
import '../workspace/install.dart';
import '../workspace/vscode.dart';

class EnvUseCommand extends PuroCommand {
  EnvUseCommand() {
    argParser.addFlag(
      'vscode',
      help: 'Enable or disable generation of VSCode configs',
    );
    argParser.addFlag(
      'intellij',
      help:
          'Enable or disable generation of IntelliJ (or Android Studio) configs',
    );
    argParser.addFlag(
      'global',
      abbr: 'g',
      help: 'Set the global default to the provided environment',
      negatable: false,
    );
  }

  @override
  final name = 'use';

  @override
  final description = 'Selects an environment to use in the current project';

  @override
  String? get argumentUsage => '<name>';

  @override
  Future<CommandResult> run() async {
    final args = unwrapArguments(atMost: 1);
    final config = PuroConfig.of(scope);
    final log = PuroLogger.of(scope);
    final envName = args.isEmpty ? null : args.first;
    if (argResults!['global'] as bool) {
      if (envName == null) {
        final current = await getDefaultEnvName(scope: scope);
        return BasicMessageResult(
          'The current global default environment is `$current`',
          type: CompletionType.info,
        );
      }
      final env = config.getEnv(envName);
      if (!env.exists) {
        if (pseudoEnvironmentNames.contains(env.name)) {
          await createEnvironment(
            scope: scope,
            envName: env.name,
            flutterVersion: await FlutterVersion.query(
              scope: scope,
              version: env.name,
            ),
          );
        } else {
          log.w('Environment `${env.name}` does not exist');
        }
      }
      await setDefaultEnvName(
        scope: scope,
        envName: env.name,
      );
      return BasicMessageResult(
        'Set global default environment to `${env.name}`',
      );
    }
    var vscodeOverride =
        argResults!.wasParsed('vscode') ? argResults!['vscode'] as bool : null;
    if (vscodeOverride == null && await isRunningInVscode(scope: scope)) {
      vscodeOverride = true;
    }
    final environment = await switchEnvironment(
      scope: scope,
      envName: envName,
      vscode: vscodeOverride,
      intellij: argResults!.wasParsed('intellij')
          ? argResults!['intellij'] as bool
          : null,
      projectConfig: config.project,
    );
    return BasicMessageResult(
      'Switched to environment `${environment.name}`',
    );
  }
}
