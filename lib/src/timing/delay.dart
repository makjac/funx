/// Delay mechanism for adding delays before/after function execution.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// Adds a delay before and/or after executing a [Func].
///
/// Example:
/// ```dart
/// final process = Func(() async => await doWork())
///   .delay(Duration(milliseconds: 500), mode: DelayMode.before);
///
/// await process(); // Waits 500ms, then executes
/// ```
class DelayExtension<R> extends Func<R> {
  /// Creates a delayed function wrapper.
  ///
  /// Example:
  /// ```dart
  /// final delayed = DelayExtension(
  ///   myFunc,
  ///   Duration(milliseconds: 500),
  ///   DelayMode.before,
  /// );
  /// ```
  DelayExtension(
    this._inner,
    this._duration,
    this._mode,
  ) : super(() => throw UnimplementedError());

  final Func<R> _inner;
  final Duration _duration;
  final DelayMode _mode;

  @override
  Future<R> call() async {
    // Delay before execution
    if (_mode == DelayMode.before || _mode == DelayMode.both) {
      await Future<void>.delayed(_duration);
    }

    // Execute
    final result = await _inner();

    // Delay after execution
    if (_mode == DelayMode.after || _mode == DelayMode.both) {
      await Future<void>.delayed(_duration);
    }

    return result;
  }
}

/// Adds a delay before and/or after executing a [Func1].
///
/// Example:
/// ```dart
/// final save = Func1<String, void>((data) async {
///   await storage.save(data);
/// }).delay(Duration(milliseconds: 500));
/// ```
class DelayExtension1<T, R> extends Func1<T, R> {
  /// Creates a delayed function wrapper for single-parameter functions.
  ///
  /// Example:
  /// ```dart
  /// final delayed = DelayExtension1(
  ///   myFunc,
  ///   Duration(milliseconds: 500),
  ///   DelayMode.before,
  /// );
  /// ```
  DelayExtension1(
    this._inner,
    this._duration,
    this._mode,
  ) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;
  final Duration _duration;
  final DelayMode _mode;

  @override
  Future<R> call(T arg) async {
    // Delay before execution
    if (_mode == DelayMode.before || _mode == DelayMode.both) {
      await Future<void>.delayed(_duration);
    }

    // Execute
    final result = await _inner(arg);

    // Delay after execution
    if (_mode == DelayMode.after || _mode == DelayMode.both) {
      await Future<void>.delayed(_duration);
    }

    return result;
  }
}

/// Adds a delay before and/or after executing a [Func2].
///
/// Example:
/// ```dart
/// final save = Func2<String, String, void>((key, value) async {
///   await storage.save(key, value);
/// }).delay(Duration(milliseconds: 500));
/// ```
class DelayExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a delayed function wrapper for two-parameter functions.
  ///
  /// Example:
  /// ```dart
  /// final delayed = DelayExtension2(
  ///   myFunc,
  ///   Duration(milliseconds: 500),
  ///   DelayMode.before,
  /// );
  /// ```
  DelayExtension2(
    this._inner,
    this._duration,
    this._mode,
  ) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;
  final Duration _duration;
  final DelayMode _mode;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    // Delay before execution
    if (_mode == DelayMode.before || _mode == DelayMode.both) {
      await Future<void>.delayed(_duration);
    }

    // Execute
    final result = await _inner(arg1, arg2);

    // Delay after execution
    if (_mode == DelayMode.after || _mode == DelayMode.both) {
      await Future<void>.delayed(_duration);
    }

    return result;
  }
}
