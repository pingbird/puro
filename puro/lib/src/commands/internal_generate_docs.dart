import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:pub_semver/pub_semver.dart';

import '../command.dart';
import '../command_result.dart';
import '../config.dart';
import '../http.dart';

class GenerateDocsCommand extends PuroCommand {
  GenerateDocsCommand() {
    argParser.addFlag(
      'deploy',
      help: 'Whether or not this is part of a production deploy',
      negatable: false,
    );
  }

  @override
  String get name => '_generate-docs';

  @override
  Future<CommandResult> run() async {
    final scriptPath = Platform.script.toFilePath();
    final config = PuroConfig.of(scope);
    if (!scriptPath.endsWith('.dart')) {
      throw CommandError('Development only');
    }
    final scriptFile = config.fileSystem.file(scriptPath);
    final puroDir = scriptFile.parent.parent;
    final rootDir = puroDir.parent;
    final docsDir = rootDir.childDirectory('website').childDirectory('docs');
    if (!docsDir.existsSync()) {
      throw CommandError('Could not find ${docsDir.path}');
    }
    final referenceDir = docsDir.childDirectory('reference');
    referenceDir.createSync(recursive: true);

    await referenceDir
        .childFile('commands.md')
        .writeAsString(generateCommands());

    await puroDir
        .childFile('CHANGELOG.md')
        .copy(referenceDir.childFile('changelog.md').path);

    if (argResults!['deploy'] as bool) {
      // Replace master in the installation instructions with the latest version
      final httpClient = scope.read(clientProvider);
      var latestVersion = Platform.environment['CIRCLE_TAG'];
      if (latestVersion == null || latestVersion.isEmpty) {
        final response = await httpClient.get(config.puroLatestVersionUrl);
        HttpException.ensureSuccess(response);
        latestVersion = response.body;
      }
      latestVersion = latestVersion.trim();
      // Make sure it's a valid version string
      Version.parse(latestVersion);

      final builds = config.puroBuildsUrl;
      final indexFile = docsDir.childFile('index.md');
      var index = await indexFile.readAsString();
      index = index.replaceAll(
        builds.append(path: 'master').toString(),
        builds.append(path: latestVersion).toString(),
      );
      index = index.replaceAll(
        'PURO_VERSION="master"',
        'PURO_VERSION="$latestVersion"',
      );
      await indexFile.writeAsString(index);
    }

    return BasicMessageResult('Generated docs');
  }

  String allowedTitle(Option option, String allowed) {
    final dynamic defaultsTo = option.defaultsTo;
    final bool isDefault = defaultsTo is List
        ? defaultsTo.contains(allowed)
        : defaultsTo == allowed;
    return '[$allowed]' + (isDefault ? ' (default)' : '');
  }

  String optionString(Option option) {
    String result;
    if (option.negatable!) {
      result = '--[no-]${option.name}';
    } else {
      result = '--${option.name}';
    }
    if (option.valueHelp != null) result += '=<${option.valueHelp}>';
    return result;
  }

  String generateOptions(Iterable<Option> options) {
    final buffer = StringBuffer();
    for (final option in options) {
      buffer.write('#### ');
      buffer.writeln(
        [
          if (option.abbr != null) '`-${option.abbr}`',
          '`${optionString(option)}`',
        ].join(', '),
      );
      buffer.writeln();
      if (option.help != null) {
        buffer.writeln(option.help);
        buffer.writeln();
      }
      if (option.allowedHelp != null) {
        for (final name in option.allowedHelp!.keys.toList()..sort()) {
          buffer.writeln(
            '* `${allowedTitle(option, name)}`'
            ' ${option.allowedHelp![name]}',
          );
        }
        buffer.writeln();
      } else if (option.allowed != null) {
        final dynamic defaultsTo = option.defaultsTo;
        final isDefault = defaultsTo is List
            ? defaultsTo.contains
            : (dynamic value) => value == option.defaultsTo;
        final allowedBuffer = StringBuffer();
        allowedBuffer.write('[');
        var first = true;
        for (final allowed in option.allowed!) {
          if (!first) allowedBuffer.write(', ');
          allowedBuffer.write(allowed);
          if (isDefault(allowed)) {
            allowedBuffer.write(' (default)');
          }
          first = false;
        }
        allowedBuffer.write(']');
        buffer.writeln('$allowedBuffer');
        buffer.writeln();
      } else if (option.isFlag) {
        if (option.defaultsTo == true) {
          buffer.writeln('(defaults to on)');
          buffer.writeln();
        }
      } else if (option.isMultiple) {
        final defaultsTo = option.defaultsTo as List?;
        if (defaultsTo != null && defaultsTo.isNotEmpty) {
          final defaults = defaultsTo
              .map((dynamic value) => '`"$value"`')
              .join(', ');
          buffer.writeln('(defaults to $defaults)');
          buffer.writeln();
        }
      } else if (option.defaultsTo != null) {
        buffer.writeln('(defaults to `${jsonEncode(option.defaultsTo)}`)');
        buffer.writeln();
      }
    }
    return '$buffer';
  }

  String generateCommands() {
    final buffer = StringBuffer();
    buffer.writeln('# Commands');
    buffer.writeln();
    for (final command in runner.commands.values.toSet()) {
      if (command.hidden) continue;
      buffer.writeln(
        '## ${command.name.substring(0, 1).toUpperCase()}'
        '${command.name.substring(1)}',
      );
      buffer.writeln();
      buffer.writeln('```sh');
      buffer.writeln('${command.invocation}');
      buffer.writeln('```');
      buffer.writeln();
      buffer.writeln(command.description);
      buffer.writeln();
      final options = command.argParser.options.values.where(
        (e) => e.name != 'help' && !e.hide,
      );
      if (options.isNotEmpty) {
        buffer.writeln('#### Options');
        buffer.writeln();
      }
      buffer.write(generateOptions(options));
      buffer.writeln('---');
      buffer.writeln();
    }
    buffer.writeln('# Global Options');
    buffer.writeln();
    buffer.write(generateOptions(runner.argParser.options.values));
    return '$buffer';
  }
}
