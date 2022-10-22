import 'dart:io';

import 'package:neoansi/neoansi.dart';

import 'debouncer.dart';
import 'provider.dart';

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

  String formatString(
    String input, {
    Ansi8BitColor? foregroundColor,
    Ansi8BitColor? backgroundColor,
    bool bold = false,
    bool underline = false,
  }) {
    if (!enableColor) {
      return input;
    }
    final buffer = StringBuffer();
    final writer = AnsiWriter.from(buffer);
    if (foregroundColor != null) writer.setForegroundColor8(foregroundColor);
    if (backgroundColor != null) writer.setBackgroundColor8(backgroundColor);
    if (bold) writer.setBold();
    if (underline) writer.setUnderlined();
    writer.write(input);
    writer.resetStyles();
    return '$buffer';
  }

  var _status = '';

  String _clearStatus() {
    if (_status.isEmpty) return '';
    final lines = '\n'.allMatches(_status).length;
    _status = '';
    return '\r${lines == 0 ? '' : '\x1b[${lines}A'}\x1b[0J';
  }

  void clearStatus() {
    final output = _clearStatus();
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
    statusDebouncer.add(newStatus);
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
    clearStatus();
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
