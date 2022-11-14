import 'dart:async';

import 'package:clock/clock.dart';

/// Debounces an asynchronous operation, calling [onUpdate] after [add] is used
/// to update [value].
///
/// This class makes a few useful guarantees:
///
/// 1. [onUpdate] will not be called more frequent than [minDuration].
/// 2. [onUpdate] will be called at least every [maxDuration] if [add] is called
///    more frequent than [minDuration].
/// 3. [onUpdate] will not be called concurrently, e.g. if [add] is called while
///    an asynchronous [onUpdate] is in progress, the debouncer will wait until
///    it finishes.
class Debouncer<T> {
  Debouncer({
    required this.minDuration,
    this.maxDuration,
    required this.onUpdate,
    T? initialValue,
  }) {
    if (initialValue is T) {
      _value = initialValue;
    }
  }

  final Duration minDuration;
  final Duration? maxDuration;
  final FutureOr<void> Function(T value) onUpdate;

  late T _value;
  T get value => _value;

  Timer? _timer;
  var _isUpdating = false;
  var _shouldUpdate = false;
  DateTime? _lastUpdate;

  Future<void> _update({DateTime? now}) async {
    _timer?.cancel();
    _timer = null;
    if (_isUpdating) {
      _shouldUpdate = true;
      return;
    }
    _lastUpdate = now ?? clock.now();
    _isUpdating = true;
    try {
      await onUpdate(_value);
    } catch (exception, stackTrace) {
      Zone.current.handleUncaughtError(exception, stackTrace);
    }
    _isUpdating = false;
    if (_shouldUpdate) {
      _shouldUpdate = false;
      unawaited(_update());
    }
  }

  void add(T value) {
    _value = value;

    _timer?.cancel();
    _timer = null;

    final now = clock.now();
    _lastUpdate ??= now;

    var duration = minDuration;
    if (maxDuration != null) {
      final newDuration = _lastUpdate!.add(maxDuration!).difference(now);
      if (newDuration < duration) {
        duration = newDuration;
      }
    }

    if (duration.isNegative || duration == Duration.zero) {
      _update(now: now);
    } else {
      _timer = Timer(duration, _update);
    }
  }

  void reset(T value) {
    _timer?.cancel();
    _timer = null;
    _shouldUpdate = false;
    _value = value;
  }
}
