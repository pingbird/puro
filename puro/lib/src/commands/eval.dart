import 'dart:convert';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

import '../command.dart';
import '../command_result.dart';
import '../env/default.dart';
import '../eval/context.dart';
import '../eval/packages.dart';
import '../eval/worker.dart';
import '../logger.dart';
import '../terminal.dart';

class EvalCommand extends PuroCommand {
  EvalCommand() {
    argParser.addFlag(
      'reset',
      abbr: 'r',
      help: 'Resets the pubspec file',
      negatable: false,
    );
    argParser.addMultiOption(
      'import',
      aliases: ['imports'],
      abbr: 'i',
      help: 'A package to import, this option accepts a shortened package '
          'URI followed by one or more optional modifiers\n\n'
          'Shortened names expand as follows:\n'
          "  foo     => import 'package:foo/foo.dart'\n"
          "  foo/bar => import 'package:foo/bar.dart'\n\n"
          'The `=` modifier adds `as` to the import:\n'
          "  foo=     => import 'package:foo/foo.dart' as foo\n"
          "  foo=bar  => import 'package:foo/foo.dart' as bar\n\n"
          "  foo/bar= => import 'package:foo/bar.dart' as foo\n\n"
          'The `+` and `-` modifier add `show` and `hide` to the import:\n'
          "  foo+x   => import 'package:foo/foo.dart' show x\n"
          "  foo+x+y => import 'package:foo/foo.dart' show x, y\n"
          "  foo-x   => import 'package:foo/foo.dart' hide x\n"
          "  foo-x-y => import 'package:foo/foo.dart' hide x, y\n\n"
          'Imports for packages also implicitly add a package dependency',
    );
    argParser.addMultiOption(
      'package',
      aliases: ['packages'],
      abbr: 'p',
      help: 'A package to depend on, this option accepts the package name '
          'optionally followed by a version constraint:\n'
          '  name[`=`][constraint]\n'
          'The package is removed from the pubspec if constraint is "none"',
    );
    argParser.addFlag(
      'no-core',
      abbr: 'c',
      help: 'Whether to disable automatic imports of core libraries',
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
    final environment = await getProjectEnvOrDefault(scope: scope);

    final noCoreImports = argResults!['no-core'] as bool;
    final reset = argResults!['reset'] as bool;
    final imports =
        (argResults!['import'] as List<String>).map(EvalImport.parse).toList();
    final packages = argResults!['package'] as List<String>;
    final extra = argResults!['extra'] as List<String>;
    var code = argResults!.rest.join(' ');
    if (code.isEmpty) {
      code = await utf8.decodeStream(stdin);
    }

    final context = EvalContext(scope: scope, environment: environment);
    if (!noCoreImports) context.importCore();
    context.imports.addAll(imports);
    final packageVersions = <String, VersionConstraint?>{
      for (final import in imports)
        if (import.uri.scheme == 'package') import.uri.pathSegments.first: null,
    };
    packageVersions.addEntries(packages.map(parseEvalPackage));
    log.d('packageVersions: $packageVersions');

    try {
      await context.pullPackages(packages: packageVersions, reset: reset);

      final worker = await EvalWorker.spawn(
        scope: scope,
        context: context,
        code: code,
        extra: extra,
      );

      final result = await worker.run();
      if (result != null) {
        stdout.writeln(result);
      }
      await worker.dispose();
      await runner.exitPuro(0);
    } on EvalPubError {
      CommandMessage(
        'Pass `-r` or `--reset` to use a fresh pubspec file',
        type: CompletionType.info,
      ).queue(scope);
      rethrow;
    } on EvalError catch (e) {
      throw CommandError('$e');
    }
  }
}
