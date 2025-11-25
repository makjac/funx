/// Repeated execution of functions with control.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Repeats a [Func] execution with control options.
///
/// Executes the function multiple times with optional delays and
/// stop conditions.
///
/// Example:
/// ```dart
/// final poll = Func(() async => await checkStatus())
///   .repeat(
///     times: 10,
///     interval: Duration(seconds: 5),
///     until: (result) => result.isComplete,
///   );
/// ```
class RepeatExtension<R> extends Func<R> {
  /// Creates a repeat wrapper for a function.
  ///
  /// [times] is the maximum number of iterations (null for infinite).
  /// [interval] is the delay between iterations.
  /// [until] stops when this predicate returns true.
  /// [onIteration] is called after each iteration.
  ///
  /// Example:
  /// ```dart
  /// final repeated = RepeatExtension(
  ///   myFunc,
  ///   times: 5,
  ///   interval: Duration(seconds: 1),
  ///   until: (result) => result.isComplete,
  /// );
  /// ```
  RepeatExtension(
    this._inner, {
    this.times,
    this.interval,
    this.until,
    this.onIteration,
  }) : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Maximum number of iterations (null for infinite).
  final int? times;

  /// Delay between iterations.
  final Duration? interval;

  /// Stop condition predicate.
  final bool Function(R result)? until;

  /// Callback after each iteration.
  final void Function(int iteration, R result)? onIteration;

  @override
  Future<R> call() async {
    var iteration = 0;
    late R lastResult;

    while (times == null || iteration < times!) {
      lastResult = await _inner();
      iteration++;

      onIteration?.call(iteration, lastResult);

      // Check stop condition
      if (until != null && until!(lastResult)) {
        break;
      }

      // Wait before next iteration (except for last)
      if (interval != null && (times == null || iteration < times!)) {
        await Future<void>.delayed(interval!);
      }
    }

    return lastResult;
  }
}

/// Repeats a [Func1] execution with control options.
///
/// Executes the function multiple times with the same argument.
///
/// Example:
/// ```dart
/// final retry = Func1<String, Response>((url) async => await fetch(url))
///   .repeat(
///     times: 3,
///     interval: Duration(seconds: 2),
///     until: (response) => response.statusCode == 200,
///   );
/// ```
class RepeatExtension1<T, R> extends Func1<T, R> {
  /// Creates a repeat wrapper for a single-parameter function.
  ///
  /// [times] is the maximum number of iterations (null for infinite).
  /// [interval] is the delay between iterations.
  /// [until] stops when this predicate returns true.
  /// [onIteration] is called after each iteration.
  ///
  /// Example:
  /// ```dart
  /// final repeated = RepeatExtension1(
  ///   myFunc,
  ///   times: 10,
  ///   until: (result) => result.isValid,
  /// );
  /// ```
  RepeatExtension1(
    this._inner, {
    this.times,
    this.interval,
    this.until,
    this.onIteration,
  }) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Maximum number of iterations (null for infinite).
  final int? times;

  /// Delay between iterations.
  final Duration? interval;

  /// Stop condition predicate.
  final bool Function(R result)? until;

  /// Callback after each iteration.
  final void Function(int iteration, R result)? onIteration;

  @override
  Future<R> call(T arg) async {
    var iteration = 0;
    late R lastResult;

    while (times == null || iteration < times!) {
      lastResult = await _inner(arg);
      iteration++;

      onIteration?.call(iteration, lastResult);

      // Check stop condition
      if (until != null && until!(lastResult)) {
        break;
      }

      // Wait before next iteration (except for last)
      if (interval != null && (times == null || iteration < times!)) {
        await Future<void>.delayed(interval!);
      }
    }

    return lastResult;
  }
}

/// Repeats a [Func2] execution with control options.
///
/// Executes the function multiple times with the same arguments.
///
/// Example:
/// ```dart
/// final retry = Func2<String, int, Data>((url, timeout) async {
///   return await fetch(url, timeout);
/// }).repeat(
///   times: 5,
///   interval: Duration(milliseconds: 500),
///   until: (data) => data.isComplete,
/// );
/// ```
class RepeatExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a repeat wrapper for a two-parameter function.
  ///
  /// [times] is the maximum number of iterations (null for infinite).
  /// [interval] is the delay between iterations.
  /// [until] stops when this predicate returns true.
  /// [onIteration] is called after each iteration.
  ///
  /// Example:
  /// ```dart
  /// final repeated = RepeatExtension2(
  ///   myFunc,
  ///   times: 3,
  ///   onIteration: (i, r) => print('Iteration $i: $r'),
  /// );
  /// ```
  RepeatExtension2(
    this._inner, {
    this.times,
    this.interval,
    this.until,
    this.onIteration,
  }) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Maximum number of iterations (null for infinite).
  final int? times;

  /// Delay between iterations.
  final Duration? interval;

  /// Stop condition predicate.
  final bool Function(R result)? until;

  /// Callback after each iteration.
  final void Function(int iteration, R result)? onIteration;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    var iteration = 0;
    late R lastResult;

    while (times == null || iteration < times!) {
      lastResult = await _inner(arg1, arg2);
      iteration++;

      onIteration?.call(iteration, lastResult);

      // Check stop condition
      if (until != null && until!(lastResult)) {
        break;
      }

      // Wait before next iteration (except for last)
      if (interval != null && (times == null || iteration < times!)) {
        await Future<void>.delayed(interval!);
      }
    }

    return lastResult;
  }
}
