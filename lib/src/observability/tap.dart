/// Side effect observation without modifying function result.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Executes side effects without modifying function result.
///
/// Allows observing function execution and results through callbacks
/// without affecting the actual return value. The [onValue] callback is
/// invoked with successful results. The [onError] callback is invoked
/// with errors and stack traces. Neither callback affects the function's
/// return value or error propagation. Useful for logging, metrics,
/// debugging, and analytics.
///
/// Returns a [Future] of type [R] with the original execution result.
/// Side effects execute before the result is returned.
///
/// Example:
/// ```dart
/// final logged = Func<User>(() async {
///   return await api.getUser();
/// }).tap(
///   onValue: (user) => print('Got user: ${user.name}'),
///   onError: (error, stack) => print('Error: $error'),
/// );
///
/// final user = await logged(); // Side effect executes, result unchanged
/// ```
class TapExtension<R> extends Func<R> {
  /// Creates a tap wrapper for a no-parameter function.
  ///
  /// Wraps [_inner] function to observe execution without modifying
  /// results. The [onValue] callback is invoked with the result if
  /// execution succeeds. The [onError] callback is invoked with error
  /// and stack trace if execution fails. Both callbacks are optional.
  ///
  /// Example:
  /// ```dart
  /// final tapped = TapExtension(
  ///   fetchData,
  ///   onValue: (data) => log('Success: $data'),
  ///   onError: (error, stack) => log('Error: $error'),
  /// );
  /// ```
  TapExtension(
    this._inner, {
    this.onValue,
    this.onError,
  }) : super(() => throw UnimplementedError());

  /// The wrapped function to execute and observe.
  final Func<R> _inner;

  /// Optional callback invoked with the result on successful execution.
  final void Function(R value)? onValue;

  /// Optional callback invoked with error and stack trace on failure.
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  Future<R> call() async {
    try {
      final result = await _inner();
      onValue?.call(result);
      return result;
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
      rethrow;
    }
  }
}

/// Executes side effects on single-parameter function without modifying
/// result.
///
/// Allows observing function execution and results through callbacks
/// without affecting the actual return value. The [onValue] callback is
/// invoked with successful results. The [onError] callback is invoked
/// with errors and stack traces. Neither callback affects the function's
/// return value or error propagation. Useful for logging, metrics, and
/// analytics.
///
/// Returns a [Future] of type [R] with the original execution result.
/// Side effects execute before the result is returned.
///
/// Example:
/// ```dart
/// final logged = Func1<int, String>((id) async {
///   return await api.fetch(id);
/// }).tap(
///   onValue: (result) => print('Fetched: $result'),
/// );
/// ```
class TapExtension1<T, R> extends Func1<T, R> {
  /// Creates a tap wrapper for a single-parameter function.
  ///
  /// Wraps [_inner] function to observe execution without modifying
  /// results. The [onValue] callback is invoked with the result if
  /// execution succeeds. The [onError] callback is invoked with error
  /// and stack trace if execution fails. Both callbacks are optional.
  ///
  /// Example:
  /// ```dart
  /// final tapped = TapExtension1(
  ///   fetchUser,
  ///   onValue: (user) => analytics.track('user_fetched'),
  /// );
  /// ```
  TapExtension1(
    this._inner, {
    this.onValue,
    this.onError,
  }) : super((arg) => throw UnimplementedError());

  /// The wrapped function to execute and observe.
  final Func1<T, R> _inner;

  /// Optional callback invoked with the result on successful execution.
  final void Function(R value)? onValue;

  /// Optional callback invoked with error and stack trace on failure.
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  Future<R> call(T arg) async {
    try {
      final result = await _inner(arg);
      onValue?.call(result);
      return result;
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
      rethrow;
    }
  }
}

/// Executes side effects on two-parameter function without modifying
/// result.
///
/// Allows observing function execution and results through callbacks
/// without affecting the actual return value. The [onValue] callback is
/// invoked with successful results. The [onError] callback is invoked
/// with errors and stack traces. Neither callback affects the function's
/// return value or error propagation. Useful for logging, caching, and
/// error tracking.
///
/// Returns a [Future] of type [R] with the original execution result.
/// Side effects execute before the result is returned.
///
/// Example:
/// ```dart
/// final logged = Func2<String, int, Data>((url, timeout) async {
///   return await api.fetch(url, timeout);
/// }).tap(
///   onValue: (data) => cache.store(data),
///   onError: (e, s) => errorLog.record(e, s),
/// );
/// ```
class TapExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a tap wrapper for a two-parameter function.
  ///
  /// Wraps [_inner] function to observe execution without modifying
  /// results. The [onValue] callback is invoked with the result if
  /// execution succeeds. The [onError] callback is invoked with error
  /// and stack trace if execution fails. Both callbacks are optional.
  ///
  /// Example:
  /// ```dart
  /// final tapped = TapExtension2(
  ///   saveData,
  ///   onValue: (result) => notifySuccess(),
  /// );
  /// ```
  TapExtension2(
    this._inner, {
    this.onValue,
    this.onError,
  }) : super((arg1, arg2) => throw UnimplementedError());

  /// The wrapped function to execute and observe.
  final Func2<T1, T2, R> _inner;

  /// Optional callback invoked with the result on successful execution.
  final void Function(R value)? onValue;

  /// Optional callback invoked with error and stack trace on failure.
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    try {
      final result = await _inner(arg1, arg2);
      onValue?.call(result);
      return result;
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
      rethrow;
    }
  }
}
