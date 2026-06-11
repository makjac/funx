/// Side effect observation without modifying function result.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/observability/_observability_engines.dart';

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
  }) : _engine = TapEngine<R>(onValue: onValue, onError: onError),
       super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Optional callback invoked with the result on successful execution.
  final void Function(R value)? onValue;

  /// Optional callback invoked with error and stack trace on failure.
  final void Function(Object error, StackTrace stackTrace)? onError;

  final TapEngine<R> _engine;

  @override
  Future<R> call() => _engine.run(_inner.call);
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
  }) : _engine = TapEngine<R>(onValue: onValue, onError: onError),
       super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Optional callback invoked with the result on successful execution.
  final void Function(R value)? onValue;

  /// Optional callback invoked with error and stack trace on failure.
  final void Function(Object error, StackTrace stackTrace)? onError;

  final TapEngine<R> _engine;

  @override
  Future<R> call(T arg) => _engine.run(() => _inner(arg));
}

/// Executes side effects on two-parameter function without modifying
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
/// final logged = Func2<String, int, Data>((id, limit) async {
///   return await api.getData(id, limit);
/// }).tap(
///   onValue: (result) => print('Fetched: $result'),
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
  ///   fetchData,
  ///   onValue: (data) => analytics.track('data_fetched'),
  /// );
  /// ```
  TapExtension2(
    this._inner, {
    this.onValue,
    this.onError,
  }) : _engine = TapEngine<R>(onValue: onValue, onError: onError),
       super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Optional callback invoked with the result on successful execution.
  final void Function(R value)? onValue;

  /// Optional callback invoked with error and stack trace on failure.
  final void Function(Object error, StackTrace stackTrace)? onError;

  final TapEngine<R> _engine;

  @override
  Future<R> call(T1 arg1, T2 arg2) => _engine.run(() => _inner(arg1, arg2));
}
