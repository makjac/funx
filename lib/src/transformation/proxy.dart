/// Intercepts and modifies function calls and results.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Intercepts function execution with before/after hooks.
///
/// Provides a proxy pattern for functions, allowing observation,
/// modification of results, or side effects without changing the
/// original function. The [beforeCall] hook executes before the
/// function, [afterCall] can transform the result, and [onError]
/// handles exceptions. This pattern is useful for logging, metrics,
/// validation, result enrichment, or debugging. All hooks are
/// optional, allowing flexible interception scenarios.
///
/// Example:
/// ```dart
/// int callCount = 0;
/// final logged = Func(() async => await api.getData())
///   .proxy(
///     beforeCall: () => callCount++,
///     afterCall: (result) {
///       print('Got result: $result');
///       return result;
///     },
///     onError: (e, s) => print('Error: $e'),
///   );
/// ```
class ProxyExtension<R> extends Func<R> {
  /// Creates a proxy wrapper for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The optional
  /// [beforeCall] callback is invoked before execution for side
  /// effects like logging or metrics. The optional [afterCall]
  /// callback can transform or enrich the result after execution.
  /// The optional [onError] callback handles exceptions and receives
  /// both the error and stack trace.
  ///
  /// Example:
  /// ```dart
  /// final proxied = ProxyExtension(
  ///   myFunc,
  ///   beforeCall: () => print('Starting'),
  ///   afterCall: (r) => enrichResult(r),
  ///   onError: (e, s) => logError(e, s),
  /// );
  /// ```
  ProxyExtension(
    this._inner, {
    this.beforeCall,
    this.afterCall,
    this.onError,
  }) : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Optional callback invoked before function execution.
  ///
  /// Executes before the wrapped function is called. Useful for side
  /// effects like logging, incrementing counters, or starting timers.
  /// Does not receive any arguments or affect execution flow.
  final void Function()? beforeCall;

  /// Optional callback that transforms the result after execution.
  ///
  /// Receives the function result and can modify, enrich, or transform
  /// it before returning. The transformed value becomes the final
  /// result. Only invoked on successful execution, not on errors.
  final R Function(R result)? afterCall;

  /// Optional callback invoked when an exception occurs.
  ///
  /// Receives both the error object and stack trace for logging or
  /// handling. The exception is re-thrown after this callback, so it
  /// does not suppress the error.
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  Future<R> call() async {
    beforeCall?.call();

    try {
      var result = await _inner();
      if (afterCall != null) {
        result = afterCall!(result);
      }
      return result;
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
      rethrow;
    }
  }
}

/// Intercepts one-parameter function execution with hooks.
///
/// Provides a proxy pattern for single-parameter functions, allowing
/// observation, argument transformation, result modification, or side
/// effects. The [beforeCall] hook executes before the function with
/// access to the argument, [transformArg] can modify the argument,
/// [afterCall] can transform the result, and [onError] handles
/// exceptions. This pattern is useful for validation, normalization,
/// logging, metrics, or debugging. All hooks are optional.
///
/// Example:
/// ```dart
/// final validated = Func1<String, int>((s) async => int.parse(s))
///   .proxy(
///     beforeCall: (s) => print('Parsing: $s'),
///     transformArg: (s) => s.trim(),
///     afterCall: (n) => n.abs(),
///     onError: (e, s) => print('Parse failed: $e'),
///   );
/// ```
class ProxyExtension1<T, R> extends Func1<T, R> {
  /// Creates a proxy wrapper for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The optional
  /// [beforeCall] callback is invoked before execution with the
  /// argument for logging or validation. The optional [transformArg]
  /// callback can modify the argument before passing it to the
  /// function. The optional [afterCall] callback can transform the
  /// result. The optional [onError] callback handles exceptions.
  ///
  /// Example:
  /// ```dart
  /// final proxied = ProxyExtension1(
  ///   myFunc,
  ///   transformArg: (arg) => arg.toUpperCase(),
  ///   afterCall: (r) => enrichResult(r),
  /// );
  /// ```
  ProxyExtension1(
    this._inner, {
    this.beforeCall,
    this.transformArg,
    this.afterCall,
    this.onError,
  }) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Optional callback invoked before execution with the argument.
  ///
  /// Receives the original argument before any transformation. Useful
  /// for logging, validation, or metrics. Does not affect the
  /// argument passed to the function.
  final void Function(T arg)? beforeCall;

  /// Optional callback that transforms the argument before execution.
  ///
  /// Receives the original argument and returns a modified version
  /// that will be passed to the wrapped function. Useful for
  /// normalization, validation, or preprocessing.
  final T Function(T arg)? transformArg;

  /// Optional callback that transforms the result after execution.
  ///
  /// Receives the function result and can modify, enrich, or transform
  /// it before returning. The transformed value becomes the final
  /// result. Only invoked on successful execution, not on errors.
  final R Function(R result)? afterCall;

  /// Optional callback invoked when an exception occurs.
  ///
  /// Receives both the error object and stack trace for logging or
  /// handling. The exception is re-thrown after this callback, so it
  /// does not suppress the error.
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  Future<R> call(T arg) async {
    var modifiedArg = arg;

    beforeCall?.call(arg);

    if (transformArg != null) {
      modifiedArg = transformArg!(arg);
    }

    try {
      var result = await _inner(modifiedArg);
      if (afterCall != null) {
        result = afterCall!(result);
      }
      return result;
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
      rethrow;
    }
  }
}

/// Intercepts two-parameter function execution with hooks.
///
/// Provides a proxy pattern for two-parameter functions, allowing
/// observation, argument transformation, result modification, or side
/// effects. The [beforeCall] hook executes before the function with
/// access to both arguments, [transformArgs] can modify the arguments,
/// [afterCall] can transform the result, and [onError] handles
/// exceptions. This pattern is useful for validation, normalization,
/// logging, metrics, or debugging. All hooks are optional.
///
/// Example:
/// ```dart
/// final validated = Func2<int, int, int>((a, b) async => a / b)
///   .proxy(
///     beforeCall: (a, b) => print('Dividing: $a / $b'),
///     transformArgs: (a, b) => (a.abs(), b == 0 ? 1 : b),
///     onError: (e, s) => print('Division failed: $e'),
///   );
/// ```
class ProxyExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a proxy wrapper for a two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The optional
  /// [beforeCall] callback is invoked before execution with both
  /// arguments for logging or validation. The optional [transformArgs]
  /// callback can modify the arguments before passing them to the
  /// function. The optional [afterCall] callback can transform the
  /// result. The optional [onError] callback handles exceptions.
  ///
  /// Example:
  /// ```dart
  /// final proxied = ProxyExtension2(
  ///   myFunc,
  ///   transformArgs: (a, b) => (a.abs(), b.abs()),
  ///   afterCall: (r) => enrichResult(r),
  /// );
  /// ```
  ProxyExtension2(
    this._inner, {
    this.beforeCall,
    this.transformArgs,
    this.afterCall,
    this.onError,
  }) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Optional callback invoked before execution with both arguments.
  ///
  /// Receives both original arguments before any transformation.
  /// Useful for logging, validation, or metrics. Does not affect the
  /// arguments passed to the function.
  final void Function(T1 arg1, T2 arg2)? beforeCall;

  /// Optional callback that transforms arguments before execution.
  ///
  /// Receives both original arguments and returns modified versions
  /// as a tuple that will be passed to the wrapped function. Useful
  /// for normalization, validation, or preprocessing.
  final (T1, T2) Function(T1 arg1, T2 arg2)? transformArgs;

  /// Optional callback that transforms the result after execution.
  ///
  /// Receives the function result and can modify, enrich, or transform
  /// it before returning. The transformed value becomes the final
  /// result. Only invoked on successful execution, not on errors.
  final R Function(R result)? afterCall;

  /// Optional callback invoked when an exception occurs.
  ///
  /// Receives both the error object and stack trace for logging or
  /// handling. The exception is re-thrown after this callback, so it
  /// does not suppress the error.
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    var modifiedArg1 = arg1;
    var modifiedArg2 = arg2;

    beforeCall?.call(arg1, arg2);

    if (transformArgs != null) {
      (modifiedArg1, modifiedArg2) = transformArgs!(arg1, arg2);
    }

    try {
      var result = await _inner(modifiedArg1, modifiedArg2);
      if (afterCall != null) {
        result = afterCall!(result);
      }
      return result;
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
      rethrow;
    }
  }
}
