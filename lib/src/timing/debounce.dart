/// Debounce mechanism for delaying function execution.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// Delays function execution until specified duration elapses since last
/// invocation.
///
/// Debouncing prevents excessive function calls by delaying execution until a
/// quiet period occurs. Each new invocation cancels the previous scheduled
/// execution and starts a new delay timer. The [_inner] function executes only
/// after [_duration] elapses without any new calls. The [_mode] determines when
/// execution occurs: [DebounceMode.leading] executes immediately on first call,
/// [DebounceMode.trailing]executes after delay, [DebounceMode.both] executes on
/// both edges.
///
/// Returns a [Future] that completes when the debounced function executes. For
/// trailing mode, returns the result after delay. For leading mode, returns
/// immediately or throws [StateError] if already executed in current window.
///
/// Throws:
/// - [StateError] when called during debounce window in leading mode
///
/// Example:
/// ```dart
/// final search = Func(() async => await api.search())
///   .debounce(Duration(milliseconds: 300));
///
/// // Rapid calls
/// search(); // scheduled
/// search(); // cancels previous, schedules new
/// search(); // cancels previous, schedules new
/// // Only the last call executes after 300ms
/// ```
class DebounceExtension<R> extends Func<R> {
  /// Creates a debounced function wrapper.
  ///
  /// Wraps [_inner] function with debounce behavior using [_duration] delay and
  /// [_mode] execution strategy. The wrapper maintains internal state to track
  /// timers and execution windows.
  ///
  /// Example:
  /// ```dart
  /// final debounced = DebounceExtension(
  ///   myFunc,
  ///   Duration(milliseconds: 300),
  ///   DebounceMode.trailing,
  /// );
  /// ```
  DebounceExtension(
    this._inner,
    this._duration,
    this._mode,
  ) : super(() => throw UnimplementedError());

  /// The wrapped function to execute with debounce behavior.
  final Func<R> _inner;

  /// The minimum duration between executions.
  final Duration _duration;

  /// The timing mode controlling when execution occurs.
  final DebounceMode _mode;

  /// Timer for scheduling trailing execution and window resets.
  Timer? _timer;

  /// Completer for pending trailing execution result.
  Completer<R>? _completer;

  /// Flag indicating whether leading execution occurred in current window.
  bool _hasLeadingExecuted = false;

  @override
  Future<R> call() async {
    // Leading mode: execute immediately on first call
    if (_mode == DebounceMode.leading) {
      if (!_hasLeadingExecuted) {
        _hasLeadingExecuted = true;
        final result = await _inner();

        // Schedule reset
        _timer?.cancel();
        _timer = Timer(_duration, () {
          _hasLeadingExecuted = false;
        });

        return result;
      } else {
        // Already executed in current window - ignore
        throw StateError('Function is debounced');
      }
    }

    // Both mode
    if (_mode == DebounceMode.both) {
      if (!_hasLeadingExecuted) {
        _hasLeadingExecuted = true;
        final result = await _inner();

        // Schedule reset
        _timer?.cancel();
        _timer = Timer(_duration, () {
          _hasLeadingExecuted = false;
        });

        return result;
      } else {
        // Already executed leading, schedule trailing
        return _scheduleTrailing();
      }
    }

    // Trailing mode: delay execution
    return _scheduleTrailing();
  }

  Future<R> _scheduleTrailing() {
    _timer?.cancel();
    _completer = Completer<R>();

    _timer = Timer(_duration, () async {
      try {
        final result = await _inner();
        _completer?.complete(result);
      } catch (error, stackTrace) {
        _completer?.completeError(error, stackTrace);
      }
    });

    return _completer!.future;
  }

  /// Cancels pending debounced execution and resets internal state.
  ///
  /// Stops any scheduled timer, clears pending completers, and resets execution
  /// flags. After cancellation, the next call will behave as if no previous
  /// calls occurred. Safe to call even when no execution is pending.
  ///
  /// Example:
  /// ```dart
  /// final debounced = myFunc.debounce(Duration(milliseconds: 300));
  /// debounced();
  /// debounced.cancel(); // Cancels pending execution
  /// ```
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _hasLeadingExecuted = false;
    _completer = null;
  }
}

/// Delays execution of single-parameter function until duration elapses
/// since last call.
///
/// Provides debounce behavior for [Func1] functions with one parameter.
/// Each invocation with parameter [T] cancels previous scheduled execution
/// and starts new delay timer. The [_inner] function executes only after
/// [_duration] elapses without new calls. The [_mode] determines execution
/// timing strategy.
///
/// Returns a [Future] completing with result of type [R] when debounced
/// function executes. For trailing mode, result arrives after delay. For
/// leading mode, returns immediately or throws [StateError] if in debounce
/// window.
///
/// Throws:
/// - [StateError] when called during active debounce window in leading
/// mode
///
/// Example:
/// ```dart
/// final search = Func1<String, List<Result>>((query) async {
///   return await api.search(query);
/// }).debounce(Duration(milliseconds: 300));
/// ```
class DebounceExtension1<T, R> extends Func1<T, R> {
  /// Creates a debounced wrapper for single-parameter functions.
  ///
  /// Wraps [_inner] function accepting parameter [T] with debounce
  /// behavior using [_duration] delay and [_mode] execution strategy.
  /// Maintains internal state to track timers and execution windows across
  /// calls with different arguments.
  ///
  /// Example:
  /// ```dart
  /// final debounced = DebounceExtension1(
  ///   myFunc,
  ///   Duration(milliseconds: 300),
  ///   DebounceMode.trailing,
  /// );
  /// ```
  DebounceExtension1(
    this._inner,
    this._duration,
    this._mode,
  ) : super((arg) => throw UnimplementedError());

  /// The wrapped function to execute with debounce behavior.
  final Func1<T, R> _inner;

  /// The minimum duration between executions.
  final Duration _duration;

  /// The timing mode controlling when execution occurs.
  final DebounceMode _mode;

  /// Timer for scheduling trailing execution and window resets.
  Timer? _timer;

  /// Completer for pending trailing execution result.
  Completer<R>? _completer;

  /// Flag indicating whether leading execution occurred in current window.
  bool _hasLeadingExecuted = false;

  @override
  Future<R> call(T arg) async {
    // Leading mode: execute immediately on first call
    if (_mode == DebounceMode.leading || _mode == DebounceMode.both) {
      if (!_hasLeadingExecuted) {
        _hasLeadingExecuted = true;
        final result = await _inner(arg);

        // Schedule reset
        _timer?.cancel();
        _timer = Timer(_duration, () {
          _hasLeadingExecuted = false;
        });

        return result;
      }
    }

    // Trailing mode: delay execution
    if (_mode == DebounceMode.trailing || _mode == DebounceMode.both) {
      return _scheduleTrailing(arg);
    }

    throw StateError('Invalid debounce mode');
  }

  Future<R> _scheduleTrailing(T arg) {
    _timer?.cancel();
    _completer = Completer<R>();

    _timer = Timer(_duration, () async {
      try {
        final result = await _inner(arg);
        _completer?.complete(result);
      } catch (error, stackTrace) {
        _completer?.completeError(error, stackTrace);
      }
    });

    return _completer!.future;
  }

  /// Cancels pending debounced execution and resets internal state.
  ///
  /// Stops any scheduled timer, clears pending completers, and resets execution
  /// flags. After cancellation, the next call with any argument will behave as
  /// if no previous calls occurred. Safe to call even when no execution is
  /// pending.
  ///
  /// Example:
  /// ```dart
  /// final debounced = myFunc.debounce(Duration(milliseconds: 300));
  /// debounced('test');
  /// debounced.cancel(); // Cancels pending execution
  /// ```
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _hasLeadingExecuted = false;
    _completer = null;
  }
}

/// Delays execution of two-parameter function until duration elapses since
/// last call.
///
/// Provides debounce behavior for [Func2] functions with two parameters.
/// Each invocation with parameters [T1] and [T2] cancels previous scheduled
/// execution and starts new delay timer. The [_inner] function executes
/// only after [_duration] elapses without new calls. The [_mode] determines
/// execution timing strategy.
///
/// Returns a [Future] completing with result of type [R] when debounced
/// function executes. For trailing mode, result arrives after delay. For
/// leading mode, returns immediately or throws [StateError] if in debounce
/// window.
///
/// Throws:
/// - [StateError] when called during active debounce window in leading
/// mode
///
/// Example:
/// ```dart
/// final search = Func2<String, int, List<Result>>((query, limit) async {
///   return await api.search(query, limit);
/// }).debounce(Duration(milliseconds: 300));
/// ```
class DebounceExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a debounced wrapper for two-parameter functions.
  ///
  /// Wraps [_inner] function accepting parameters [T1] and [T2] with
  /// debounce behavior using [_duration] delay and [_mode] execution
  /// strategy. Maintains internal state to track timers and execution
  /// windows across calls with different argument combinations.
  ///
  /// Example:
  /// ```dart
  /// final debounced = DebounceExtension2(
  ///   myFunc,
  ///   Duration(milliseconds: 300),
  ///   DebounceMode.trailing,
  /// );
  /// ```
  DebounceExtension2(
    this._inner,
    this._duration,
    this._mode,
  ) : super((arg1, arg2) => throw UnimplementedError());

  /// The wrapped function to execute with debounce behavior.
  final Func2<T1, T2, R> _inner;

  /// The minimum duration between executions.
  final Duration _duration;

  /// The timing mode controlling when execution occurs.
  final DebounceMode _mode;

  /// Timer for scheduling trailing execution and window resets.
  Timer? _timer;

  /// Completer for pending trailing execution result.
  Completer<R>? _completer;

  /// Flag indicating whether leading execution occurred in current window.
  bool _hasLeadingExecuted = false;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    // Leading mode: execute immediately on first call
    if (_mode == DebounceMode.leading) {
      if (!_hasLeadingExecuted) {
        _hasLeadingExecuted = true;
        final result = await _inner(arg1, arg2);

        // Schedule reset
        _timer?.cancel();
        _timer = Timer(_duration, () {
          _hasLeadingExecuted = false;
        });

        return result;
      } else {
        throw StateError('Function is debounced');
      }
    }

    // Both mode
    if (_mode == DebounceMode.both) {
      if (!_hasLeadingExecuted) {
        _hasLeadingExecuted = true;
        final result = await _inner(arg1, arg2);

        // Schedule reset
        _timer?.cancel();
        _timer = Timer(_duration, () {
          _hasLeadingExecuted = false;
        });

        return result;
      } else {
        return _scheduleTrailing(arg1, arg2);
      }
    }

    // Trailing mode: delay execution
    return _scheduleTrailing(arg1, arg2);
  }

  Future<R> _scheduleTrailing(T1 arg1, T2 arg2) {
    _timer?.cancel();
    _completer = Completer<R>();

    _timer = Timer(_duration, () async {
      try {
        final result = await _inner(arg1, arg2);
        _completer?.complete(result);
      } catch (error, stackTrace) {
        _completer?.completeError(error, stackTrace);
      }
    });

    return _completer!.future;
  }

  /// Cancels pending debounced execution and resets internal state.
  ///
  /// Stops any scheduled timer, clears pending completers, and resets execution
  /// flags. After cancellation, the next call with any arguments will behave as
  /// if no previous calls occurred. Safe to call even when no execution is
  /// pending.
  ///
  /// Example:
  /// ```dart
  /// final debounced = myFunc.debounce(Duration(milliseconds: 300));
  /// debounced('test', 10);
  /// debounced.cancel(); // Cancels pending execution
  /// ```
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _hasLeadingExecuted = false;
    _completer = null;
  }
}
