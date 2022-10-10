import 'dart:async';

import 'package:neoansi/neoansi.dart';
import 'package:puro/src/provider.dart';

enum LogLevel {
  wtf,
  error,
  warning,
  verbose,
  debug;

  bool operator >(LogLevel other) {
    return index > other.index;
  }

  bool operator <(LogLevel other) {
    return index < other.index;
  }

  bool operator >=(LogLevel other) {
    return index >= other.index;
  }

  bool operator <=(LogLevel other) {
    return index <= other.index;
  }
}

class LogEntry {
  LogEntry(this.timestamp, this.level, this.message);

  final DateTime timestamp;
  final LogLevel level;
  final String message;
}

class PuroLogger {
  PuroLogger({
    this.level,
    required this.onEvent,
  });

  final LogLevel? level;
  final void Function(LogEntry entry) onEvent;

  void add(LogEntry event) => onEvent(event);

  void d(String message) {
    if (level == null || level! < LogLevel.debug) return;
    add(LogEntry(DateTime.now(), LogLevel.debug, message));
  }

  void v(String message) {
    if (level == null || level! < LogLevel.verbose) return;
    add(LogEntry(DateTime.now(), LogLevel.verbose, message));
  }

  void w(String message) {
    if (level == null || level! < LogLevel.warning) return;
    add(LogEntry(DateTime.now(), LogLevel.warning, message));
  }

  void e(String message) {
    if (level == null || level! < LogLevel.error) return;
    add(LogEntry(DateTime.now(), LogLevel.error, message));
  }

  void wtf(String message) {
    if (level == null || level! < LogLevel.wtf) return;
    add(LogEntry(DateTime.now(), LogLevel.wtf, message));
  }

  static final provider = Provider<PuroLogger>.late();
  static PuroLogger of(Scope scope) => scope.read(provider);
}

class PuroLogPrinter extends Sink<LogEntry> {
  PuroLogPrinter({
    required this.sink,
    required this.enableColor,
  });

  final StringSink sink;
  final bool enableColor;

  static const levelPrefixes = {
    LogLevel.verbose: '[V]',
    LogLevel.debug: '[D]',
    LogLevel.warning: '[W]',
    LogLevel.error: '[E]',
    LogLevel.wtf: '[WTF]',
  };

  static const levelColors = {
    LogLevel.verbose: Ansi8BitColor.grey35,
    LogLevel.debug: Ansi8BitColor.grey,
    LogLevel.warning: Ansi8BitColor.orange1,
    LogLevel.error: Ansi8BitColor.red,
    LogLevel.wtf: Ansi8BitColor.pink1,
  };

  @override
  void add(LogEntry data) {
    var label = levelPrefixes[data.level]!;
    final labelLength = label.length;
    if (enableColor) {
      final buffer = StringBuffer();
      AnsiWriter.from(buffer)
        ..setBold()
        ..setForegroundColor8(levelColors[data.level]!)
        ..write(label)
        ..resetStyles();
      label = '$buffer';
    }
    final lines = '$label ${data.message}'.trim().split('\n');
    sink.writeln(
      [
        lines.first,
        for (final line in lines.skip(1)) '${' ' * labelLength} $line',
      ].join('\n'),
    );
  }

  @override
  void close() {}
}
