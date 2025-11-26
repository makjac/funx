/// Side effect observation without modifying function result.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Executes a side effect without modifying the function result.
///
/// Allows observing function execution and results without affecting
/// the actual return value. Useful for logging, metrics, debugging.
///
/// Example:
/// ```dart
/// final logged = Func<User>(() async {
///   return await api.getUser();
/// }).tap(
///   onValue: (user) => print('Got user: ${user.name}'),
///   onError: (error) => print('Error: $error'),
/// );
///
/// final user = await logged(); // Side effect executes, result unchanged
/// ```
class TapExtension<R> extends Func<R> {
  /// Creates a tap wrapper for a no-parameter function.
  ///
  /// [_inner] is the function to wrap.
  /// [onValue] is called with the result on success.
  /// [onError] is called with the error on failure.
  ///
  /// Example:
  /// ```dart
  /// final tapped = TapExtension(
  ///   fetchData,
  ///   onValue: (data) => log('Success: $data'),
  ///   onError: (error) => log('Error: $error'),
  /// );
  /// ```
  TapExtension(
    this._inner, {
    this.onValue,
    this.onError,
  }) : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Callback called with the result on success.
  final void Function(R value)? onValue;

  /// Callback called with the error on failure.
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

/// Taps into single-parameter function execution.
///
/// Same as [TapExtension] but for functions with one parameter.
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
  /// [_inner] is the function to wrap.
  /// [onValue] is called with the result on success.
  /// [onError] is called with the error on failure.
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

  final Func1<T, R> _inner;

  /// Callback called with the result on success.
  final void Function(R value)? onValue;

  /// Callback called with the error on failure.
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

/// Taps into two-parameter function execution.
///
/// Same as [TapExtension] but for functions with two parameters.
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
  /// [_inner] is the function to wrap.
  /// [onValue] is called with the result on success.
  /// [onError] is called with the error on failure.
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

  final Func2<T1, T2, R> _inner;

  /// Callback called with the result on success.
  final void Function(R value)? onValue;

  /// Callback called with the error on failure.
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
