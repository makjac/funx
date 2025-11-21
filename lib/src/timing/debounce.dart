/// Debounce mechanism for delaying function execution.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// Debounces a [Func] by delaying execution until after [Duration] has elapsed
/// since the last invocation.
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

  final Func<R> _inner;
  final Duration _duration;
  final DebounceMode _mode;

  Timer? _timer;
  Completer<R>? _completer;
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

  /// Cancels any pending debounced execution.
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

/// Debounces a [Func1] with one parameter.
///
/// Example:
/// ```dart
/// final search = Func1<String, List<Result>>((query) async {
///   return await api.search(query);
/// }).debounce(Duration(milliseconds: 300));
/// ```
class DebounceExtension1<T, R> extends Func1<T, R> {
  /// Creates a debounced function wrapper for single-parameter functions.
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

  final Func1<T, R> _inner;
  final Duration _duration;
  final DebounceMode _mode;

  Timer? _timer;
  Completer<R>? _completer;
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

  /// Cancels any pending debounced execution.
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

/// Debounces a [Func2] with two parameters.
///
/// Example:
/// ```dart
/// final search = Func2<String, int, List<Result>>((query, limit) async {
///   return await api.search(query, limit);
/// }).debounce(Duration(milliseconds: 300));
/// ```
class DebounceExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a debounced function wrapper for two-parameter functions.
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

  final Func2<T1, T2, R> _inner;
  final Duration _duration;
  final DebounceMode _mode;

  Timer? _timer;
  Completer<R>? _completer;
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

  /// Cancels any pending debounced execution.
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
