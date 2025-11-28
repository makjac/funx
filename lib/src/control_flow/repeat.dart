/// Repeated execution of functions with control.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Repeats function execution with customizable control options.
///
/// Executes a no-parameter function multiple times with optional
/// delays between iterations and customizable stop conditions. The
/// [times] parameter limits iterations, [interval] adds delays,
/// [until] provides early termination based on results, and
/// [onIteration] enables monitoring. This pattern is essential for
/// polling, retrying operations, batch processing, or periodic tasks.
/// Returns the result of the last execution.
///
/// Example:
/// ```dart
/// final poll = Func(() async => await checkStatus())
///   .repeat(
///     times: 10,
///     interval: Duration(seconds: 5),
///     until: (result) => result.isComplete,
///     onIteration: (i, r) => print('Attempt $i: $r'),
///   );
/// ```
class RepeatExtension<R> extends Func<R> {
  /// Creates a repeat wrapper for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The optional
  /// [times] parameter limits the maximum number of iterations; null
  /// means infinite repetition. The optional [interval] parameter adds
  /// a delay between iterations. The optional [until] predicate
  /// receives each result and stops iteration when it returns true.
  /// The optional [onIteration] callback is invoked after each
  /// iteration with the iteration number and result.
  ///
  /// Example:
  /// ```dart
  /// final repeated = RepeatExtension(
  ///   myFunc,
  ///   times: 5,
  ///   interval: Duration(seconds: 1),
  ///   until: (result) => result.isComplete,
  ///   onIteration: (i, r) => log('Iteration $i'),
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

  /// Maximum number of iterations to execute.
  ///
  /// When null, iterations continue indefinitely until [until]
  /// condition is met. When set to a positive integer, iteration
  /// stops after that many executions.
  final int? times;

  /// Delay duration between consecutive iterations.
  ///
  /// When set, the function waits for this duration after each
  /// iteration before starting the next one. The delay is not applied
  /// after the final iteration. When null, iterations execute
  /// immediately without delay.
  final Duration? interval;

  /// Predicate that determines when to stop iterating.
  ///
  /// Receives the result of each iteration and returns true to stop
  /// or false to continue. Checked after each iteration. When this
  /// returns true, iteration stops immediately even if [times] has
  /// not been reached.
  final bool Function(R result)? until;

  /// Callback invoked after each iteration completes.
  ///
  /// Receives the iteration number (1-based) and the result. Useful
  /// for logging, monitoring progress, or collecting intermediate
  /// results. Invoked before checking the [until] condition.
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

/// Repeats one-parameter function execution with control options.
///
/// Executes a single-parameter function multiple times with the same
/// argument, providing optional delays between iterations and
/// customizable stop conditions. The [times] parameter limits
/// iterations, [interval] adds delays, [until] provides early
/// termination based on results, and [onIteration] enables
/// monitoring. This pattern is essential for retrying operations with
/// the same input, polling endpoints, or batch processing. Returns
/// the result of the last execution.
///
/// Example:
/// ```dart
/// final retry = Func1<String, Response>((url) async => fetch(url))
///   .repeat(
///     times: 3,
///     interval: Duration(seconds: 2),
///     until: (response) => response.statusCode == 200,
///   );
/// ```
class RepeatExtension1<T, R> extends Func1<T, R> {
  /// Creates a repeat wrapper for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The optional
  /// [times] parameter limits the maximum number of iterations; null
  /// means infinite repetition. The optional [interval] parameter adds
  /// a delay between iterations. The optional [until] predicate
  /// receives each result and stops iteration when it returns true.
  /// The optional [onIteration] callback is invoked after each
  /// iteration with the iteration number and result.
  ///
  /// Example:
  /// ```dart
  /// final repeated = RepeatExtension1(
  ///   myFunc,
  ///   times: 10,
  ///   until: (result) => result.isValid,
  ///   onIteration: (i, r) => log('Iteration $i'),
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

  /// Maximum number of iterations to execute.
  ///
  /// When null, iterations continue indefinitely until [until]
  /// condition is met. When set to a positive integer, iteration
  /// stops after that many executions.
  final int? times;

  /// Delay duration between consecutive iterations.
  ///
  /// When set, the function waits for this duration after each
  /// iteration before starting the next one. The delay is not applied
  /// after the final iteration. When null, iterations execute
  /// immediately without delay.
  final Duration? interval;

  /// Predicate that determines when to stop iterating.
  ///
  /// Receives the result of each iteration and returns true to stop
  /// or false to continue. Checked after each iteration. When this
  /// returns true, iteration stops immediately even if [times] has
  /// not been reached.
  final bool Function(R result)? until;

  /// Callback invoked after each iteration completes.
  ///
  /// Receives the iteration number (1-based) and the result. Useful
  /// for logging, monitoring progress, or collecting intermediate
  /// results. Invoked before checking the [until] condition.
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

/// Repeats two-parameter function execution with control options.
///
/// Executes a two-parameter function multiple times with the same
/// arguments, providing optional delays between iterations and
/// customizable stop conditions. The [times] parameter limits
/// iterations, [interval] adds delays, [until] provides early
/// termination based on results, and [onIteration] enables
/// monitoring. This pattern is essential for retrying operations with
/// the same inputs, polling with parameters, or batch processing.
/// Returns the result of the last execution.
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
  /// The [_inner] parameter is the function to wrap. The optional
  /// [times] parameter limits the maximum number of iterations; null
  /// means infinite repetition. The optional [interval] parameter adds
  /// a delay between iterations. The optional [until] predicate
  /// receives each result and stops iteration when it returns true.
  /// The optional [onIteration] callback is invoked after each
  /// iteration with the iteration number and result.
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

  /// Maximum number of iterations to execute.
  ///
  /// When null, iterations continue indefinitely until [until]
  /// condition is met. When set to a positive integer, iteration
  /// stops after that many executions.
  final int? times;

  /// Delay duration between consecutive iterations.
  ///
  /// When set, the function waits for this duration after each
  /// iteration before starting the next one. The delay is not applied
  /// after the final iteration. When null, iterations execute
  /// immediately without delay.
  final Duration? interval;

  /// Predicate that determines when to stop iterating.
  ///
  /// Receives the result of each iteration and returns true to stop
  /// or false to continue. Checked after each iteration. When this
  /// returns true, iteration stops immediately even if [times] has
  /// not been reached.
  final bool Function(R result)? until;

  /// Callback invoked after each iteration completes.
  ///
  /// Receives the iteration number (1-based) and the result. Useful
  /// for logging, monitoring progress, or collecting intermediate
  /// results. Invoked before checking the [until] condition.
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
