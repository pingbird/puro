import 'dart:convert';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

import '../command.dart';
import '../command_result.dart';
import '../env/default.dart';
import '../eval/worker.dart';
import '../logger.dart';

class EvalCommand extends PuroCommand {
  EvalCommand() {
    argParser.addMultiOption(
      'import',
      aliases: ['imports'],
      abbr: 'i',
      help: 'One or more package URIs to import',
    );
    argParser.addMultiOption(
      'package',
      aliases: ['packages'],
      abbr: 'p',
      help: 'One or more packages to depend on',
    );
    argParser.addFlag(
      'no-import-core',
      abbr: 'c',
      help: 'Whether to disable automatic imports of core libraries',
      negatable: false,
    );
  }

  @override
  final name = 'eval';

  @override
  final description = 'Evaluates ephemeral Dart code';

  @override
  String? get argumentUsage => '[code]';

  @override
  bool get allowUpdateCheck => false;

  @override
  Future<CommandResult> run() async {
    final log = PuroLogger.of(scope);
    final noCoreImports = argResults!['no-import-core'] as bool;
    final imports = (argResults!['import'] as List<String>).map((e) {
      if (!e.contains(':')) e = 'package:$e';
      final uri = Uri.parse(e);
      if (uri.pathSegments.length == 1) {
        return Uri.parse('$e/${uri.pathSegments.first}.dart');
      }
      if (uri.pathSegments.last.contains('.')) {
        return uri;
      } else {
        return Uri.parse('$e.dart');
      }
    }).toList();
    final packages = argResults!['package'] as List<String>;
    var code = argResults!.rest.join(' ');
    if (code.isEmpty) {
      code = await utf8.decodeStream(stdin);
    }
    final environment = await getProjectEnvOrDefault(scope: scope);
    final worker = await EvalWorker.spawn(
      scope: scope,
      environment: environment,
    );
    final packageVersions = <String, VersionConstraint?>{
      for (final import in imports)
        if (import.scheme == 'package') import.pathSegments.first: null,
    };
    log.d('packageVersions: $packageVersions');
    for (final package in packages) {
      final index = package.indexOf('=');
      if (index < 0) {
        packageVersions[package] = VersionConstraint.any;
      } else {
        packageVersions[package.substring(0, index)] =
            VersionConstraint.parse(package.substring(index + 1));
      }
    }
    await worker.pullPackages(packages: packageVersions);
    try {
      final result = await worker.evaluate(
        code,
        importCore: !noCoreImports,
        imports: imports.map((e) => EvalImport(e)).toList(),
      );
      if (result != null) {
        stdout.writeln(result);
      }
      await worker.dispose();
      await runner.exitPuro(0);
    } on EvalError catch (e) {
      throw CommandError('$e');
    }
  }
}
