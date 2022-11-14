import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

import '../command.dart';
import '../command_result.dart';
import '../config.dart';
import '../downloader.dart';
import '../extensions.dart';
import '../http.dart';
import '../process.dart';
import '../terminal.dart';
import '../version.dart';

class PuroUpgradeCommand extends PuroCommand {
  PuroUpgradeCommand() {
    argParser.addFlag(
      'force',
      hide: true,
      help:
          'Installs a new puro executable even if it wont replace an existing one',
      negatable: false,
    );
  }

  @override
  final name = 'upgrade-puro';

  @override
  List<String> get aliases => ['update-puro'];

  @override
  String? get argumentUsage => '[version]';

  @override
  final description = 'Upgrades the puro tool to a new version';

  @override
  bool get allowUpdateCheck => false;

  @override
  Future<CommandResult> run() async {
    final force = argResults!['force'] as bool;
    final http = scope.read(clientProvider);
    final config = PuroConfig.of(scope);
    final puroVersion = await PuroVersion.of(scope);
    final currentVersion = puroVersion.semver;

    if (puroVersion.type == PuroInstallationType.pub) {
      final result = await runProcess(
        scope,
        Platform.resolvedExecutable,
        ['pub', 'global', 'activate', 'puro'],
      );
      if (result.exitCode == 0) {
        final stdout = result.stdout as String;
        if (stdout.contains('already activated at newest available version')) {
          return BasicMessageResult(
            'Puro is up to date with $currentVersion',
          );
        } else {
          return BasicMessageResult(
            'Upgraded puro to latest pub version',
          );
        }
      } else {
        return BasicMessageResult(
          '`dart pub global activate puro` failed with exit code ${result.exitCode}\n${result.stderr}'
              .trim(),
          success: false,
        );
      }
    } else if (puroVersion.type != PuroInstallationType.distribution &&
        !force) {
      return BasicMessageResult(
        "Can't upgrade: ${puroVersion.type.description}",
        success: false,
      );
    }

    var targetVersionString = unwrapSingleOptionalArgument();
    final Version targetVersion;
    if (targetVersionString == null) {
      final latestVersionResponse =
          await http.get(config.puroBuildsUrl.append(path: 'latest'));
      HttpException.ensureSuccess(latestVersionResponse);
      targetVersionString = latestVersionResponse.body.trim();
      targetVersion = Version.parse(targetVersionString);
      if (currentVersion == targetVersion && !force) {
        return BasicMessageResult('Puro is up to date with $targetVersion');
      } else if (currentVersion > targetVersion && !force) {
        return BasicMessageResult(
          'Puro is a newer version $currentVersion than the available $targetVersion',
          type: CompletionType.indeterminate,
        );
      }
    } else {
      targetVersion = Version.parse(targetVersionString);
      if (currentVersion == targetVersion && !force) {
        return BasicMessageResult(
          'Puro is the desired version $targetVersion',
        );
      }
    }
    final buildTarget = config.buildTarget;
    final tempFile = config.puroExecutableTempFile;
    tempFile.parent.createSync(recursive: true);
    await downloadFile(
      scope: scope,
      url: config.puroBuildsUrl.append(
        path: '$targetVersion/'
            '${buildTarget.name}/'
            '${buildTarget.executableName}',
      ),
      file: tempFile,
      description: 'Downloading puro $targetVersion',
    );
    if (!Platform.isWindows) {
      await runProcess(scope, 'chmod', ['+x', '--', tempFile.path]);
    }
    config.puroExecutableFile.deleteOrRenameSync();
    tempFile.renameSync(config.puroExecutableFile.path);

    final terminal = Terminal.of(scope);
    terminal.flushStatus();
    final installProcess = await startProcess(
      scope,
      config.puroExecutableFile.path,
      [
        if (terminal.enableColor) '--color',
        if (terminal.enableStatus) '--progress',
        'install-puro',
      ],
    );
    final stdoutFuture =
        installProcess.stdout.listen(stdout.add).asFuture<void>();
    await installProcess.stderr.listen(stderr.add).asFuture<void>();
    await stdoutFuture;
    await runner.exitPuro(await installProcess.exitCode);
  }
}
