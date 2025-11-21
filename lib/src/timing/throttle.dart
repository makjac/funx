/// Throttle mechanism for limiting function execution rate.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// Throttles a [Func] to execute at most once per [Duration].
///
/// Example:
/// ```dart
/// final onClick = Func(() async => await handleClick())
///   .throttle(Duration(milliseconds: 1000));
///
/// // Rapid calls
/// onClick(); // executes immediately
/// onClick(); // ignored (within throttle window)
/// onClick(); // ignored (within throttle window)
/// // Next call executes after 1000ms
/// ```
class ThrottleExtension<R> extends Func<R> {
  /// Creates a throttled function wrapper.
  ///
  /// Example:
  /// ```dart
  /// final throttled = ThrottleExtension(
  ///   myFunc,
  ///   Duration(milliseconds: 1000),
  ///   ThrottleMode.leading,
  /// );
  /// ```
  ThrottleExtension(
    this._inner,
    this._duration,
    this._mode,
  ) : super(() => throw UnimplementedError());

  final Func<R> _inner;
  final Duration _duration;
  final ThrottleMode _mode;

  Timer? _timer;
  DateTime? _lastExecutionTime;
  Completer<R>? _trailingCompleter;
  bool _hasPendingTrailing = false;

  @override
  Future<R> call() async {
    final now = DateTime.now();

    // Check if we're in throttle window
    if (_lastExecutionTime != null) {
      final elapsed = now.difference(_lastExecutionTime!);
      if (elapsed < _duration) {
        // In throttle window
        if (_mode == ThrottleMode.trailing || _mode == ThrottleMode.both) {
          return _scheduleTrailing();
        }
        // For leading mode, throw or return cached result
        throw StateError('Function is throttled');
      }
    }

    // Not in throttle window - execute
    if (_mode == ThrottleMode.leading || _mode == ThrottleMode.both) {
      _lastExecutionTime = now;
      final result = await _inner();

      // For 'both' mode, also schedule trailing
      if (_mode == ThrottleMode.both) {
        await _scheduleTrailing();
      }

      return result;
    }

    // Trailing mode
    if (_mode == ThrottleMode.trailing) {
      _lastExecutionTime = now;
      return _scheduleTrailing();
    }

    throw StateError('Invalid throttle mode');
  }

  Future<R> _scheduleTrailing() {
    if (_hasPendingTrailing) {
      return _trailingCompleter!.future;
    }

    _hasPendingTrailing = true;
    _trailingCompleter = Completer<R>();

    final remaining =
        _duration -
        DateTime.now().difference(_lastExecutionTime ?? DateTime.now());

    _timer?.cancel();
    _timer = Timer(remaining, () async {
      try {
        final result = await _inner();
        _trailingCompleter?.complete(result);
      } catch (error, stackTrace) {
        _trailingCompleter?.completeError(error, stackTrace);
      } finally {
        _hasPendingTrailing = false;
        _lastExecutionTime = DateTime.now();
      }
    });

    return _trailingCompleter!.future;
  }

  /// Resets the throttle state, allowing immediate execution on next call.
  ///
  /// Example:
  /// ```dart
  /// final throttled = myFunc.throttle(Duration(seconds: 1));
  /// throttled();
  /// throttled.reset(); // Allows immediate execution
  /// throttled(); // Executes immediately
  /// ```
  void reset() {
    _timer?.cancel();
    _timer = null;
    _lastExecutionTime = null;
    _hasPendingTrailing = false;
  }
}

/// Throttles a [Func1] with one parameter.
///
/// Example:
/// ```dart
/// final update = Func1<int, void>((value) async {
///   await api.update(value);
/// }).throttle(Duration(milliseconds: 1000));
/// ```
class ThrottleExtension1<T, R> extends Func1<T, R> {
  /// Creates a throttled function wrapper for single-parameter functions.
  ///
  /// Example:
  /// ```dart
  /// final throttled = ThrottleExtension1(
  ///   myFunc,
  ///   Duration(milliseconds: 1000),
  ///   ThrottleMode.leading,
  /// );
  /// ```
  ThrottleExtension1(
    this._inner,
    this._duration,
    this._mode,
  ) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;
  final Duration _duration;
  final ThrottleMode _mode;

  Timer? _timer;
  DateTime? _lastExecutionTime;
  Completer<R>? _trailingCompleter;
  bool _hasPendingTrailing = false;

  @override
  Future<R> call(T arg) async {
    final now = DateTime.now();

    // Check if we're in throttle window
    if (_lastExecutionTime != null) {
      final elapsed = now.difference(_lastExecutionTime!);
      if (elapsed < _duration) {
        // In throttle window
        if (_mode == ThrottleMode.trailing || _mode == ThrottleMode.both) {
          return _scheduleTrailing(arg);
        }
        throw StateError('Function is throttled');
      }
    }

    // Not in throttle window - execute
    if (_mode == ThrottleMode.leading || _mode == ThrottleMode.both) {
      _lastExecutionTime = now;
      final result = await _inner(arg);

      if (_mode == ThrottleMode.both) {
        await _scheduleTrailing(arg);
      }

      return result;
    }

    // Trailing mode
    if (_mode == ThrottleMode.trailing) {
      _lastExecutionTime = now;
      return _scheduleTrailing(arg);
    }

    throw StateError('Invalid throttle mode');
  }

  Future<R> _scheduleTrailing(T arg) {
    if (_hasPendingTrailing) {
      return _trailingCompleter!.future;
    }

    _hasPendingTrailing = true;
    _trailingCompleter = Completer<R>();

    final remaining =
        _duration -
        DateTime.now().difference(_lastExecutionTime ?? DateTime.now());

    _timer?.cancel();
    _timer = Timer(remaining, () async {
      try {
        final result = await _inner(arg);
        _trailingCompleter?.complete(result);
      } catch (error, stackTrace) {
        _trailingCompleter?.completeError(error, stackTrace);
      } finally {
        _hasPendingTrailing = false;
        _lastExecutionTime = DateTime.now();
      }
    });

    return _trailingCompleter!.future;
  }

  /// Resets the throttle state.
  ///
  /// Example:
  /// ```dart
  /// final throttled = myFunc.throttle(Duration(seconds: 1));
  /// throttled(42);
  /// throttled.reset(); // Allows immediate execution
  /// ```
  void reset() {
    _timer?.cancel();
    _timer = null;
    _lastExecutionTime = null;
    _hasPendingTrailing = false;
  }
}

/// Throttles a [Func2] with two parameters.
///
/// Example:
/// ```dart
/// final update = Func2<String, int, void>((id, value) async {
///   await api.update(id, value);
/// }).throttle(Duration(milliseconds: 1000));
/// ```
class ThrottleExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a throttled function wrapper for two-parameter functions.
  ///
  /// Example:
  /// ```dart
  /// final throttled = ThrottleExtension2(
  ///   myFunc,
  ///   Duration(milliseconds: 1000),
  ///   ThrottleMode.leading,
  /// );
  /// ```
  ThrottleExtension2(
    this._inner,
    this._duration,
    this._mode,
  ) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;
  final Duration _duration;
  final ThrottleMode _mode;

  Timer? _timer;
  DateTime? _lastExecutionTime;
  Completer<R>? _trailingCompleter;
  bool _hasPendingTrailing = false;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final now = DateTime.now();

    // Check if we're in throttle window
    if (_lastExecutionTime != null) {
      final elapsed = now.difference(_lastExecutionTime!);
      if (elapsed < _duration) {
        // In throttle window
        if (_mode == ThrottleMode.trailing || _mode == ThrottleMode.both) {
          return _scheduleTrailing(arg1, arg2);
        }
        throw StateError('Function is throttled');
      }
    }

    // Not in throttle window - execute
    if (_mode == ThrottleMode.leading || _mode == ThrottleMode.both) {
      _lastExecutionTime = now;
      final result = await _inner(arg1, arg2);

      if (_mode == ThrottleMode.both) {
        await _scheduleTrailing(arg1, arg2);
      }

      return result;
    }

    // Trailing mode
    if (_mode == ThrottleMode.trailing) {
      _lastExecutionTime = now;
      return _scheduleTrailing(arg1, arg2);
    }

    throw StateError('Invalid throttle mode');
  }

  Future<R> _scheduleTrailing(T1 arg1, T2 arg2) {
    if (_hasPendingTrailing) {
      return _trailingCompleter!.future;
    }

    _hasPendingTrailing = true;
    _trailingCompleter = Completer<R>();

    final remaining =
        _duration -
        DateTime.now().difference(_lastExecutionTime ?? DateTime.now());

    _timer?.cancel();
    _timer = Timer(remaining, () async {
      try {
        final result = await _inner(arg1, arg2);
        _trailingCompleter?.complete(result);
      } catch (error, stackTrace) {
        _trailingCompleter?.completeError(error, stackTrace);
      } finally {
        _hasPendingTrailing = false;
        _lastExecutionTime = DateTime.now();
      }
    });

    return _trailingCompleter!.future;
  }

  /// Resets the throttle state.
  ///
  /// Example:
  /// ```dart
  /// final throttled = myFunc.throttle(Duration(seconds: 1));
  /// throttled('id', 42);
  /// throttled.reset(); // Allows immediate execution
  /// ```
  void reset() {
    _timer?.cancel();
    _timer = null;
    _lastExecutionTime = null;
    _hasPendingTrailing = false;
  }
}
