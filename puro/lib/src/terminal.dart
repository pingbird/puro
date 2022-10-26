import 'dart:io';

import 'package:neoansi/neoansi.dart';

import 'debouncer.dart';
import 'provider.dart';

class _StripAnsiWriter extends AnsiListener {
  final buffer = StringBuffer();

  @override
  void write(String text) {
    buffer.write(text);
  }
}

String stripAnsiEscapes(String str) {
  final writer = _StripAnsiWriter();
  AnsiReader(writer).read(str);
  return '${writer.buffer}';
}

const plainFormatter = OutputFormatter();
const colorFormatter = ColorOutputFormatter();

enum CompletionType {
  plain('', null),
  success('[\u2713] ', Ansi8BitColor.green),
  failure('[x] ', Ansi8BitColor.red),
  indeterminate('[~] ', Ansi8BitColor.grey),
  info('[i] ', Ansi8BitColor.blue);

  const CompletionType(this.prefix, this.color);
  final String prefix;
  final Ansi8BitColor? color;
}

class OutputFormatter {
  const OutputFormatter();

  String color(
    String content, {
    Ansi8BitColor? foregroundColor,
    Ansi8BitColor? backgroundColor,
    bool bold = false,
    bool underline = false,
  }) {
    return content;
  }

  String prefix(String prefix, String content) {
    if (prefix.isEmpty) return content;
    final prefixLength = stripAnsiEscapes(prefix).length;
    final lines = '$prefix$content'.split('\n');
    return [
      lines.first,
      for (final line in lines.skip(1))
        '${' ' * prefixLength}${line.replaceAll('\t', '    ')}',
    ].join('\n');
  }

  String complete(
    String content, {
    CompletionType type = CompletionType.success,
  }) {
    return prefix(
      color(
        type.prefix,
        foregroundColor: type.color,
        bold: true,
      ),
      content,
    );
  }

  String success(String content) =>
      complete(content, type: CompletionType.success);
  String failure(String content) =>
      complete(content, type: CompletionType.failure);
  String indeterminate(String content) =>
      complete(content, type: CompletionType.indeterminate);
  String info(String content) => complete(content, type: CompletionType.info);

  static const indeterminatePrefix = '[~]';
  static const indeterminateColor = Ansi8BitColor.grey;
}

class ColorOutputFormatter extends OutputFormatter {
  const ColorOutputFormatter();

  @override
  String color(
    String content, {
    Ansi8BitColor? foregroundColor,
    Ansi8BitColor? backgroundColor,
    bool bold = false,
    bool underline = false,
  }) {
    final buffer = StringBuffer();
    final writer = AnsiWriter.from(buffer);
    if (foregroundColor != null) writer.setForegroundColor8(foregroundColor);
    if (backgroundColor != null) writer.setBackgroundColor8(backgroundColor);
    if (bold) writer.setBold();
    if (underline) writer.setUnderlined();
    writer.write(content);
    writer.resetStyles();
    return '$buffer';
  }
}

class Terminal extends StringSink {
  Terminal({
    required this.stdout,
  });

  final Stdout stdout;
  late var enableColor = stdout.supportsAnsiEscapes;
  late var enableStatus = enableColor;
  late final statusDebouncer = Debouncer<String>(
    minDuration: const Duration(milliseconds: 50),
    maxDuration: const Duration(milliseconds: 100),
    onUpdate: flushStatus,
    initialValue: '',
  );

  OutputFormatter get format => enableColor ? colorFormatter : plainFormatter;

  var _status = '';

  String _clearStatus() {
    if (_status.isEmpty) return '';
    final lines = '\n'.allMatches(_status).length;
    _status = '';
    return '\r${lines == 0 ? '' : '\x1b[${lines}A'}\x1b[0J';
  }

  void resetStatus() {
    final output = _clearStatus();
    statusDebouncer.reset('');
    if (output.isNotEmpty) stdout.write(output);
  }

  String _flushStatus(String pendingStatus) {
    if (pendingStatus == _status) return '';
    final clear = _clearStatus();
    _status = pendingStatus;
    return '$clear$pendingStatus';
  }

  void flushStatus(String pendingStatus) {
    final output = _flushStatus(pendingStatus);
    if (output.isNotEmpty) stdout.write(output);
  }

  String get status => _status;
  set status(String newStatus) {
    if (enableStatus) statusDebouncer.add(newStatus);
  }

  void preserveStatus() {
    final pendingStatus = statusDebouncer.value;
    if (pendingStatus.isNotEmpty) {
      final flush = _flushStatus(pendingStatus);
      stdout.writeln(flush);
      _status = '';
    }
  }

  void close() {
    resetStatus();
  }

  static final provider = Provider<Terminal>.late();
  static Terminal of(Scope scope) => scope.read(provider);

  @override
  void write(Object? object) {
    stdout.write(
      '${_clearStatus()}$object${_flushStatus(statusDebouncer.value)}',
    );
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    write(objects.map((Object? e) => '$e').join(separator));
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  void writeln([Object? object = '']) {
    write('$object\n');
  }
}
