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
    this.terminal,
    this.onAdd,
    this.format = plainFormatter,
  });

  LogLevel? level;
  Terminal? terminal;
  void Function(LogEntry event)? onAdd;
  OutputFormatter format;

  void add(LogEntry event) {
    if (level == null || level! < event.level) return;
    _add(event);
  }

  void _add(LogEntry event) {
    if (onAdd != null) {
      onAdd!(event);
    }
    if (terminal != null) {
      final label = format.color(
        levelPrefixes[event.level]!,
        foregroundColor: levelColors[event.level]!,
        bold: true,
      );
      terminal!.writeln(format.prefix('$label ', event.message));
    }
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
  final lowercaseAction =
      action.substring(0, 1).toUpperCase() + action.substring(1);
  log.v('$lowercaseAction...');
  try {
    return await fn();
  } catch (exception, stackTrace) {
    final time = clock.now();
    log.add(LogEntry(time, level, 'Exception while $lowercaseAction'));
    log.add(LogEntry(time, exceptionLevel ?? level, '$exception\n$stackTrace'));
    return null;
  }
}
