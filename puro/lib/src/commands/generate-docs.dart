import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import '../command.dart';
import '../config.dart';

class GenerateDocsCommand extends PuroCommand {
  @override
  String get name => '_generate-docs';

  @override
  bool get hidden => true;

  @override
  Future<CommandResult> run() async {
    final scriptPath = Platform.script.toFilePath();
    final config = PuroConfig.of(scope);
    if (!scriptPath.endsWith('.dart')) {
      throw AssertionError('Development only');
    }
    final scriptFile = config.fileSystem.file(scriptPath);
    final puroDir = scriptFile.parent.parent;
    final rootDir = puroDir.parent;
    final docsDir = rootDir.childDirectory('website').childDirectory('docs');
    if (!docsDir.existsSync()) {
      throw AssertionError('Development only');
    }
    final referenceDir = docsDir.childDirectory('reference');
    referenceDir.createSync(recursive: true);

    await referenceDir
        .childFile('commands.md')
        .writeAsString(generateCommands());

    await puroDir.childFile('CHANGELOG.md').copy(
          referenceDir.childFile('changelog.md').path,
        );

    return BasicMessageResult(success: true, message: 'Generated docs');
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
      buffer.writeln([
        if (option.abbr != null) '`-${option.abbr}`',
        '`${optionString(option)}`',
      ].join(', '));
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
          final defaults =
              defaultsTo.map((dynamic value) => '`"$value"`').join(', ');
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
    final commands = runner.commands.values;
    for (final command in commands) {
      if (command.hidden) continue;
      buffer.writeln('## ${command.name.substring(0, 1).toUpperCase()}'
          '${command.name.substring(1)}');
      buffer.writeln();
      buffer.writeln('```sh');
      buffer.writeln('${command.invocation}');
      buffer.writeln('```');
      buffer.writeln();
      buffer.writeln(command.description);
      buffer.writeln();
      final options =
          command.argParser.options.values.where((e) => e.name != 'help');
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
