import 'dart:async';

import 'package:clock/clock.dart';
import 'package:neoansi/neoansi.dart';

import 'provider.dart';
import 'terminal.dart';

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
    required this.terminal,
    this.addOverride,
  });

  LogLevel? level;
  final Terminal terminal;
  void Function(LogEntry event)? addOverride;

  void add(LogEntry event) {
    if (level == null || level! < event.level) return;
    _add(event);
  }

  void _add(LogEntry event) {
    if (addOverride != null) {
      addOverride!(event);
      return;
    }
    final label = terminal.formatString(
      levelPrefixes[event.level]!,
      foregroundColor: levelColors[event.level]!,
      bold: true,
    );
    final labelLength = label.length;
    final lines = '$label ${event.message}'.trim().split('\n');
    terminal.writeln(
      [
        lines.first,
        for (final line in lines.skip(1))
          '${' ' * labelLength} ${line.replaceAll('\t', '    ')}',
      ].join('\n'),
    );
  }

  void d(String message) {
    if (level == null || level! < LogLevel.debug) return;
    _add(LogEntry(DateTime.now(), LogLevel.debug, message));
  }

  void v(String message) {
    if (level == null || level! < LogLevel.verbose) return;
    _add(LogEntry(DateTime.now(), LogLevel.verbose, message));
  }

  void w(String message) {
    if (level == null || level! < LogLevel.warning) return;
    _add(LogEntry(DateTime.now(), LogLevel.warning, message));
  }

  void e(String message) {
    if (level == null || level! < LogLevel.error) return;
    _add(LogEntry(DateTime.now(), LogLevel.error, message));
  }

  void wtf(String message) {
    if (level == null || level! < LogLevel.wtf) return;
    _add(LogEntry(DateTime.now(), LogLevel.wtf, message));
  }

  void complete(String message) {
    terminal.writeln('${terminal.formatString(
      completePrefix,
      foregroundColor: completeColor,
      bold: true,
    )} $message');
  }

  static const levelPrefixes = {
    LogLevel.wtf: '[WTF]',
    LogLevel.error: '[E]',
    LogLevel.warning: '[W]',
    LogLevel.verbose: '[V]',
    LogLevel.debug: '[D]',
  };

  static const levelColors = {
    LogLevel.wtf: Ansi8BitColor.pink1,
    LogLevel.error: Ansi8BitColor.red,
    LogLevel.warning: Ansi8BitColor.orange1,
    LogLevel.verbose: Ansi8BitColor.yellow,
    LogLevel.debug: Ansi8BitColor.grey35,
  };

  static const completePrefix = '[\u2713]';
  static const completeColor = Ansi8BitColor.green;

  static final provider = Provider<PuroLogger>.late();
  static PuroLogger of(Scope scope) => scope.read(provider);
}

FutureOr<T?> runOptional<T>(
  Scope scope,
  String action,
  Future<T> fn(), {
  LogLevel level = LogLevel.error,
  LogLevel? exceptionLevel,
}) async {
  final log = PuroLogger.of(scope);
  log.v(action.substring(0, 1).toUpperCase() + action.substring(1) + '...');
  try {
    return await fn();
  } catch (exception, stackTrace) {
    final time = clock.now();
    log.add(LogEntry(time, level, 'Exception while $action'));
    log.add(LogEntry(time, exceptionLevel ?? level, '$exception\n$stackTrace'));
    return null;
  }
}
