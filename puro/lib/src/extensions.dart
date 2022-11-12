import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:path/path.dart' as path;

extension ListIntStreamExtensions on Stream<List<int>> {
  Future<Uint8List> toBytes() {
    final completer = Completer<Uint8List>();
    final sink = ByteConversionSink.withCallback(
      (bytes) => completer.complete(Uint8List.fromList(bytes)),
    );
    listen(
      sink.add,
      onError: completer.completeError,
      onDone: sink.close,
      cancelOnError: true,
    );
    return completer.future;
  }
}

extension RandomAccessFileExtensions on RandomAccessFile {
  Future<String> readAllAsString() async {
    setPositionSync(0);
    return utf8.decode(await read(lengthSync()));
  }

  String readAllAsStringSync() {
    setPositionSync(0);
    return utf8.decode(readSync(lengthSync()));
  }

  Future<void> writeAll(List<int> bytes) async {
    await truncate(0);
    setPositionSync(0);
    await writeFrom(bytes);
  }

  Future<void> writeAllString(String string) {
    return writeAll(utf8.encode(string));
  }

  void writeAllSync(List<int> bytes) {
    truncateSync(0);
    setPositionSync(0);
    writeFromSync(bytes);
  }

  void writeAllStringSync(String string) {
    writeAllSync(utf8.encode(string));
  }
}

extension FileSystemEntityExtensions on FileSystemEntity {
  bool pathEquals(FileSystemEntity other) {
    return path.equals(this.path, other.path);
  }
}

extension FileExtensions on File {
  void deleteOrRenameSync() {
    final oldFile = parent.childFile('$basename.old');
    if (oldFile.existsSync()) {
      try {
        oldFile.deleteSync();
      } catch (e) {
        // Might fail if its still open, idk
      }
    }
    try {
      deleteSync();
    } catch (e) {
      if (existsSync()) {
        renameSync(oldFile.path);
      }
    }
  }
}

extension NumExtensions on num {
  static final _triplePattern = RegExp(r'...');
  static final _prefixCommaPattern = RegExp('^,');
  static final _trailingDotPattern = RegExp(r'\.$');

  /// Returns a custom pretty formatted number with an optional precision.
  ///
  /// For example:
  ///
  /// ```dart
  /// 1234.567.pretty() => '1,234.567'
  /// 123456.pretty()   => '123,456'
  /// ```
  String pretty({
    int? precision,
    bool minusSign = true,
    bool plusSign = false,
  }) {
    if (this == double.infinity) {
      return plusSign ? '+∞' : '∞';
    } else if (this == double.negativeInfinity) {
      return minusSign ? '-∞' : '∞';
    } else if (this == double.nan) {
      return 'NaN';
    }
    final nnn = abs().toString();
    var nnnIter = nnn.split('').skipWhile((c) => c != '.').skip(1);
    if (precision != null) {
      nnnIter = nnnIter.take(precision);
    }
    final ndn = abs().floor().toString();
    var o = ndn
        .split('')
        .reversed
        .join()
        .replaceAllMapped(_triplePattern, (m) => '${m.group(0)!},')
        .split('')
        .reversed
        .join()
        .replaceFirst(_prefixCommaPattern, '');
    if (precision != null || nnnIter.isNotEmpty) {
      o += '.${nnnIter.join().padRight(precision ?? 0, '0')}';
    }
    if (minusSign && this < 0) {
      o = '-$o';
    } else if (plusSign && this > 0) {
      o = '+$o';
    }
    if (o.contains('.')) {
      o = o.replaceAll(_trailingDotPattern, '');
    }
    return o;
  }

  /// Returns a pretty formatted percentage with an optional precision.
  ///
  /// For example:
  ///
  /// ```dart
  /// 0.56.prettyPercent(precision: 1) => '56%'
  /// 1.111.prettyPercent(precision: 1) => '111.1%'
  /// ```
  String prettyPercent({
    int? precision,
    bool minusSign = true,
    bool plusSign = true,
  }) {
    precision ??= abs() > 0 && abs() < 1 ? 2 : 0;
    return '${(this * 100).pretty(
      precision: precision,
      minusSign: minusSign,
      plusSign: plusSign,
    )}%';
  }

  /// Returns a short formatted number using abbreviations.
  ///
  /// For example:
  ///
  /// ```dart
  /// 1.prettyAbbr()          => '1'
  /// 12345678.prettyAbbr()   => '123M'
  /// 1234567891.prettyAbbr() => '1.2B'
  /// ```
  String prettyAbbr({
    bool? precision,
    bool minusSign = true,
    bool plusSign = false,
    bool metric = false,
  }) {
    if (this == double.infinity) {
      return plusSign ? '+∞' : '∞';
    } else if (this == double.negativeInfinity) {
      return minusSign ? '-∞' : '∞';
    } else if (this == double.nan) {
      return 'NaN';
    }

    if (this == 0) {
      return pretty(
        precision: 0,
        plusSign: plusSign,
        minusSign: minusSign,
      );
    } else if (this < 1) {
      return pretty(
        precision: 1,
        plusSign: plusSign,
        minusSign: minusSign,
      );
    } else if (this < 100) {
      return pretty(
        precision: 0,
        plusSign: plusSign,
        minusSign: minusSign,
      );
    } else if (this < 5000 /* 5K */) {
      return '${(this / 1000).pretty(
        precision: 1,
        plusSign: plusSign,
        minusSign: minusSign,
      )}K';
    } else if (this < 500000 /* 500K */) {
      return '${(this / 1000).pretty(
        precision: 0,
        plusSign: plusSign,
        minusSign: minusSign,
      )}K';
    } else if (this < 5000000 /* 5M  */) {
      return '${(this / 1000000).pretty(
        precision: 1,
        plusSign: plusSign,
        minusSign: minusSign,
      )}M';
    } else if (this < 500000000 /* 500M */) {
      return '${(this / 1000000).pretty(
        precision: 0,
        plusSign: plusSign,
        minusSign: minusSign,
      )}M';
    } else if (this < 5000000000 /* 5B */) {
      return '${(this / 1000000000).pretty(
        precision: 1,
        plusSign: plusSign,
        minusSign: minusSign,
      )}${metric ? 'G' : 'B'}';
    } else if (this < 500000000000 /* 500B */) {
      return '${(this / 1000000000).pretty(
        precision: 0,
        plusSign: plusSign,
        minusSign: minusSign,
      )}${metric ? 'G' : 'B'}';
    } else if (this < 5000000000000 /* 5T */) {
      return '${(this / 1000000000000).pretty(
        precision: 1,
        plusSign: plusSign,
        minusSign: minusSign,
      )}T';
    } else {
      return '${(this / 1000000000000).pretty(
        precision: 0,
        plusSign: plusSign,
        minusSign: minusSign,
      )}T';
    }
  }
}

extension DurationExtensions on Duration {
  static const _mult = <String, double>{
    'millisecond': 0.001,
    'second': 1.0,
    'minute': 60.0,
    'hour': 3600.0,
    'day': 86400.0,
    'week': 604800.0,
    'month': 2629746.0,
    'year': 31556952.0,
  };

  String pretty({
    String before = 'before',
    bool abbr = false,
  }) {
    if (before.isNotEmpty) before = ' $before';
    var s = inMicroseconds / 1000000;
    if (s == double.infinity) return 'never';
    if (s == double.negativeInfinity) return 'forever$before';
    if (s == double.nan) return 'unknown';

    var sr = '';
    if (s < 0) {
      sr = before;
      s = s.abs();
    }

    String c(String n, String a) {
      final t = (s / _mult[n]!).round();
      return '$t${abbr ? a : ' $n${t != 1 ? 's' : ''}'}';
    }

    if (s < 1) {
      return '${c('millisecond', 'ms')}$sr';
    } else if (s < 60) {
      return '${c('second', 's')}$sr';
    } else if (s < 3600) {
      return '${c('minute', 'm')}$sr';
    } else if (s < 86400) {
      return '${c('hour', 'h')}$sr';
    } else if (s < 604800) {
      return '${c('day', 'd')}$sr';
    } else if (s < 2629800) {
      return '${c('week', 'w')}$sr';
    } else if (s < 31556952) {
      return '${c('month', 'mo')}$sr';
    } else {
      return '${c('year', 'y')}$sr';
    }
  }
}

extension IterableExtensions<T> on Iterable<T> {
  Iterable<T> delimitate(T delimiter) {
    return expand((e) => [delimiter, e]).skip(1);
  }

  Iterable<R> mapWithIndex<R>(R Function(T e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}
