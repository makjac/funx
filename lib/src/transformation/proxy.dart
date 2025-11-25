/// Intercepts and modifies function calls and results.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Proxies a [Func] execution with before/after hooks.
///
/// Allows intercepting calls to observe, modify results,
/// or perform side effects.
///
/// Example:
/// ```dart
/// final logged = Func(() async => await api.call())
///   .proxy(
///     beforeCall: () => print('Starting'),
///     afterCall: (result) {
///       print('Completed: $result');
///       return result;
///     },
///   );
/// ```
class ProxyExtension<R> extends Func<R> {
  /// Creates a proxy wrapper for a function.
  ///
  /// [beforeCall] is invoked before the function executes.
  /// [afterCall] is invoked after successful execution with the result.
  /// [onError] is invoked when an error occurs.
  ///
  /// Example:
  /// ```dart
  /// final proxied = ProxyExtension(
  ///   myFunc,
  ///   beforeCall: () => print('Starting'),
  ///   afterCall: (r) => enrichResult(r),
  /// );
  /// ```
  ProxyExtension(
    this._inner, {
    this.beforeCall,
    this.afterCall,
    this.onError,
  }) : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Optional callback invoked before execution.
  final void Function()? beforeCall;

  /// Optional callback to transform result after execution.
  final R Function(R result)? afterCall;

  /// Optional callback invoked on error.
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

/// Proxies a [Func1] execution with before/after hooks.
///
/// Allows intercepting calls with access to arguments.
///
/// Example:
/// ```dart
/// final validated = Func1<String, int>((s) async => int.parse(s))
///   .proxy(
///     beforeCall: (s) => print('Parsing: $s'),
///     transformArg: (s) => s.trim(),
///   );
/// ```
class ProxyExtension1<T, R> extends Func1<T, R> {
  /// Creates a proxy wrapper for a single-parameter function.
  ///
  /// [beforeCall] is invoked before execution with the argument.
  /// [transformArg] can modify the argument before execution.
  /// [afterCall] can transform the result after execution.
  /// [onError] is invoked when an error occurs.
  ///
  /// Example:
  /// ```dart
  /// final proxied = ProxyExtension1(
  ///   myFunc,
  ///   transformArg: (arg) => arg.toUpperCase(),
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
  final void Function(T arg)? beforeCall;

  /// Optional callback to transform the argument before execution.
  final T Function(T arg)? transformArg;

  /// Optional callback to transform the result after execution.
  final R Function(R result)? afterCall;

  /// Optional callback invoked on error.
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

/// Proxies a [Func2] execution with before/after hooks.
///
/// Allows intercepting calls with access to both arguments.
///
/// Example:
/// ```dart
/// final validated = Func2<int, int, int>((a, b) async => a + b)
///   .proxy(
///     beforeCall: (a, b) => print('Adding: $a + $b'),
///   );
/// ```
class ProxyExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a proxy wrapper for a two-parameter function.
  ///
  /// [beforeCall] is invoked before execution with both arguments.
  /// [transformArgs] can modify the arguments before execution.
  /// [afterCall] can transform the result after execution.
  /// [onError] is invoked when an error occurs.
  ///
  /// Example:
  /// ```dart
  /// final proxied = ProxyExtension2(
  ///   myFunc,
  ///   transformArgs: (a, b) => (a.abs(), b.abs()),
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
  final void Function(T1 arg1, T2 arg2)? beforeCall;

  /// Optional callback to transform the arguments before execution.
  final (T1, T2) Function(T1 arg1, T2 arg2)? transformArgs;

  /// Optional callback to transform the result after execution.
  final R Function(R result)? afterCall;

  /// Optional callback invoked on error.
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
