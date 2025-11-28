/// Throttle mechanism for limiting function execution rate.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// Limits function execution rate to at most once per duration.
///
/// Throttling prevents excessive function calls by enforcing a minimum
/// time interval between executions. The [_inner] function executes at
/// most once per [_duration] regardless of how many times it's called.
/// The [_mode] determines execution timing: [ThrottleMode.leading]
/// executes immediately on first call then blocks subsequent calls,
/// [ThrottleMode.trailing] schedules execution at end of throttle window,
/// [ThrottleMode.both] executes on both edges. Tracks last execution time
/// to enforce throttle window.
///
/// Returns a [Future] of type [R] from the executed function. For leading
/// mode, returns immediately or throws [StateError] if in throttle window.
/// For trailing mode, returns after scheduled execution completes.
///
/// Throws:
/// - [StateError] when called during active throttle window in leading
/// mode
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
  /// Wraps [_inner] function with throttle behavior using [_duration] to
  /// enforce minimum interval between executions and [_mode] to control
  /// execution timing. The wrapper maintains internal state tracking last
  /// execution time and pending trailing executions.
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

  /// The wrapped function to execute with throttle behavior.
  final Func<R> _inner;

  /// The minimum duration between executions.
  final Duration _duration;

  /// The timing mode controlling when execution occurs.
  final ThrottleMode _mode;

  /// Timer for scheduling trailing execution.
  Timer? _timer;

  /// Timestamp of last successful execution.
  DateTime? _lastExecutionTime;

  /// Completer for pending trailing execution result.
  Completer<R>? _trailingCompleter;

  /// Flag indicating whether trailing execution is pending.
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

  /// Resets throttle state to allow immediate execution on next call.
  ///
  /// Clears last execution timestamp, cancels pending trailing execution, and
  /// resets all internal state. After reset, the next call will execute
  /// immediately regardless of previous throttle window. Useful for manually
  /// clearing throttle constraints when needed. Safe to call even when no
  /// execution is pending.
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

/// Limits execution rate of single-parameter function to at most once per
/// duration.
///
/// Throttling prevents excessive calls to [_inner] function accepting
/// parameter [T] by enforcing minimum time interval between executions.
/// Executes at most once per [_duration] regardless of call frequency. The
/// [_mode] determines timing: [ThrottleMode.leading] executes immediately
/// then blocks, [ThrottleMode.trailing] schedules at window end,
/// [ThrottleMode.both] executes on both edges. Tracks last execution time
/// to enforce window.
///
/// Returns a [Future] of type [R] from the executed function. For leading
/// mode, returns immediately or throws [StateError] if in throttle window.
/// For trailing mode, returns after scheduled execution completes.
///
/// Throws:
/// - [StateError] when called during active throttle window in leading
/// mode
///
/// Example:
/// ```dart
/// final update = Func1<int, void>((value) async {
///   await api.update(value);
/// }).throttle(Duration(milliseconds: 1000));
/// ```
class ThrottleExtension1<T, R> extends Func1<T, R> {
  /// Creates a throttled wrapper for single-parameter functions.
  ///
  /// Wraps [_inner] function accepting parameter [T] with throttle
  /// behavior using [_duration] to enforce minimum interval and [_mode] to
  /// control timing. The wrapper maintains internal state tracking last
  /// execution time and pending trailing executions across calls with
  /// different arguments.
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

  /// The wrapped function to execute with throttle behavior.
  final Func1<T, R> _inner;

  /// The minimum duration between executions.
  final Duration _duration;

  /// The timing mode controlling when execution occurs.
  final ThrottleMode _mode;

  /// Timer for scheduling trailing execution.
  Timer? _timer;

  /// Timestamp of last successful execution.
  DateTime? _lastExecutionTime;

  /// Completer for pending trailing execution result.
  Completer<R>? _trailingCompleter;

  /// Flag indicating whether trailing execution is pending.
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

  /// Resets throttle state to allow immediate execution on next call.
  ///
  /// Clears last execution timestamp, cancels pending trailing execution, and
  /// resets all internal state. After reset, the next call with any argument
  /// will execute immediately regardless of previous throttle window. Useful
  /// for manually clearing throttle constraints. Safe to call even when no
  /// execution is pending.
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

/// Limits execution rate of two-parameter function to at most once per
/// duration.
///
/// Throttling prevents excessive calls to [_inner] function accepting
/// parameters [T1] and [T2] by enforcing minimum time interval between
/// executions. Executes at most once per [_duration] regardless of call
/// frequency. The [_mode] determines timing: [ThrottleMode.leading]
/// executes immediately then blocks, [ThrottleMode.trailing] schedules at
/// window end, [ThrottleMode.both] executes on both edges. Tracks last
/// execution time to enforce window.
///
/// Returns a [Future] of type [R] from the executed function. For leading
/// mode, returns immediately or throws [StateError] if in throttle window.
/// For trailing mode, returns after scheduled execution completes.
///
/// Throws:
/// - [StateError] when called during active throttle window in leading
/// mode
///
/// Example:
/// ```dart
/// final update = Func2<String, int, void>((id, value) async {
///   await api.update(id, value);
/// }).throttle(Duration(milliseconds: 1000));
/// ```
class ThrottleExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a throttled wrapper for two-parameter functions.
  ///
  /// Wraps [_inner] function accepting parameters [T1] and [T2] with
  /// throttle behavior using [_duration] to enforce minimum interval and
  /// [_mode] to control timing. The wrapper maintains internal state
  /// tracking last execution time and pending trailing executions across
  /// calls with different argument combinations.
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

  /// The wrapped function to execute with throttle behavior.
  final Func2<T1, T2, R> _inner;

  /// The minimum duration between executions.
  final Duration _duration;

  /// The timing mode controlling when execution occurs.
  final ThrottleMode _mode;

  /// Timer for scheduling trailing execution.
  Timer? _timer;

  /// Timestamp of last successful execution.
  DateTime? _lastExecutionTime;

  /// Completer for pending trailing execution result.
  Completer<R>? _trailingCompleter;

  /// Flag indicating whether trailing execution is pending.
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

  /// Resets throttle state to allow immediate execution on next call.
  ///
  /// Clears last execution timestamp, cancels pending trailing execution, and
  /// resets all internal state. After reset, the next call with any arguments
  /// will execute immediately regardless of previous throttle window. Useful
  /// for manually clearing throttle constraints. Safe to call even when no
  /// execution is pending.
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
