/// Delay mechanism for adding delays before/after function execution.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// Adds configurable delay before and/or after function execution.
///
/// Introduces deliberate pauses in function execution using [Future.delayed].
/// The [_duration] specifies delay length, while [_mode] controls placement:
/// [DelayMode.before] delays before execution, [DelayMode.after] delays after
/// execution, [DelayMode.both] adds delays at both points. Useful for rate
/// limiting, animations, or adding breathing room between operations.
///
/// Returns a [Future] of type [R] that completes after all configured delays
/// and execution finish. The returned value is the result from [_inner].
/// Total time is execution time plus delay(s) based on mode.
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
  /// Wraps [_inner] function with delay behavior using [_duration] for pause
  /// length and [_mode] to control delay placement. The wrapper handles
  /// delay scheduling before and/or after execution based on specified mode.
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

  /// The wrapped function to execute with delay behavior.
  final Func<R> _inner;

  /// The duration to delay before and/or after execution.
  final Duration _duration;

  /// The timing mode controlling delay placement.
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

/// Adds configurable delay before and/or after single-parameter function
/// execution.
///
/// Introduces deliberate pauses for [Func1] functions accepting parameter
/// [T] and returning [R]. The [_duration] specifies delay length, while
/// [_mode] controls placement: [DelayMode.before], [DelayMode.after], or
/// [DelayMode.both]. Uses [Future.delayed] to implement pauses. Useful for
/// throttling API calls or controlling execution timing.
///
/// Returns a [Future] of type [R] that completes after all configured
/// delays and execution finish. The returned value is the result from
/// [_inner] called with the provided argument. Total time is execution
/// time plus delay(s).
///
/// Example:
/// ```dart
/// final save = Func1<String, void>((data) async {
///   await storage.save(data);
/// }).delay(Duration(milliseconds: 500));
/// ```
class DelayExtension1<T, R> extends Func1<T, R> {
  /// Creates a delayed wrapper for single-parameter functions.
  ///
  /// Wraps [_inner] function accepting parameter [T] with delay behavior
  /// using [_duration] for pause length and [_mode] to control delay
  /// placement. The wrapper handles delay scheduling before and/or after
  /// execution with provided argument.
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

  /// The wrapped function to execute with delay behavior.
  final Func1<T, R> _inner;

  /// The duration to delay before and/or after execution.
  final Duration _duration;

  /// The timing mode controlling delay placement.
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

/// Adds configurable delay before and/or after two-parameter function
/// execution.
///
/// Introduces deliberate pauses for [Func2] functions accepting parameters
/// [T1] and [T2] and returning [R]. The [_duration] specifies delay
/// length, while [_mode] controls placement: [DelayMode.before],
/// [DelayMode.after], or [DelayMode.both]. Uses [Future.delayed] to
/// implement pauses. Useful for throttling operations or adding controlled
/// timing between steps.
///
/// Returns a [Future] of type [R] that completes after all configured
/// delays and execution finish. The returned value is the result from
/// [_inner] called with the provided arguments. Total time is execution
/// time plus delay(s).
///
/// Example:
/// ```dart
/// final save = Func2<String, String, void>((key, value) async {
///   await storage.save(key, value);
/// }).delay(Duration(milliseconds: 500));
/// ```
class DelayExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a delayed wrapper for two-parameter functions.
  ///
  /// Wraps [_inner] function accepting parameters [T1] and [T2] with delay
  /// behavior using [_duration] for pause length and [_mode] to control
  /// delay placement. The wrapper handles delay scheduling before and/or
  /// after execution with provided arguments.
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

  /// The wrapped function to execute with delay behavior.
  final Func2<T1, T2, R> _inner;

  /// The duration to delay before and/or after execution.
  final Duration _duration;

  /// The timing mode controlling delay placement.
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
