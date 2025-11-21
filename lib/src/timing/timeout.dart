/// Timeout mechanism for limiting function execution time.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Adds a timeout to a [Func], throwing [TimeoutException] if execution
/// exceeds [Duration].
///
/// Example:
/// ```dart
/// final fetch = Func(() async => await api.fetch())
///   .timeout(Duration(seconds: 5));
///
/// try {
///   await fetch();
/// } on TimeoutException {
///   print('Request timed out');
/// }
/// ```
class TimeoutExtension<R> extends Func<R> {
  /// Creates a timeout wrapper for a function.
  ///
  /// Example:
  /// ```dart
  /// final timedOut = TimeoutExtension(
  ///   myFunc,
  ///   Duration(seconds: 5),
  ///   () async => defaultValue,
  /// );
  /// ```
  TimeoutExtension(
    this._inner,
    this._duration, [
    this._onTimeout,
  ]) : super(() => throw UnimplementedError());

  final Func<R> _inner;
  final Duration _duration;
  final FutureOr<R> Function()? _onTimeout;

  @override
  Future<R> call() async {
    if (_onTimeout != null) {
      return _inner().timeout(_duration, onTimeout: _onTimeout);
    }
    return _inner().timeout(_duration);
  }
}

/// Adds a timeout to a [Func1] with one parameter.
///
/// Example:
/// ```dart
/// final fetch = Func1<String, Data>((id) async {
///   return await api.fetch(id);
/// }).timeout(Duration(seconds: 5));
/// ```
class TimeoutExtension1<T, R> extends Func1<T, R> {
  /// Creates a timeout wrapper for a single-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final timedOut = TimeoutExtension1(
  ///   myFunc,
  ///   Duration(seconds: 5),
  ///   () async => defaultValue,
  /// );
  /// ```
  TimeoutExtension1(
    this._inner,
    this._duration, [
    this._onTimeout,
  ]) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;
  final Duration _duration;
  final FutureOr<R> Function()? _onTimeout;

  @override
  Future<R> call(T arg) async {
    if (_onTimeout != null) {
      return _inner(arg).timeout(_duration, onTimeout: _onTimeout);
    }
    return _inner(arg).timeout(_duration);
  }
}

/// Adds a timeout to a [Func2] with two parameters.
///
/// Example:
/// ```dart
/// final fetch = Func2<String, int, Data>((id, version) async {
///   return await api.fetch(id, version);
/// }).timeout(Duration(seconds: 5));
/// ```
class TimeoutExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a timeout wrapper for a two-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final timedOut = TimeoutExtension2(
  ///   myFunc,
  ///   Duration(seconds: 5),
  ///   () async => defaultValue,
  /// );
  /// ```
  TimeoutExtension2(
    this._inner,
    this._duration, [
    this._onTimeout,
  ]) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;
  final Duration _duration;
  final FutureOr<R> Function()? _onTimeout;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    if (_onTimeout != null) {
      return _inner(arg1, arg2).timeout(_duration, onTimeout: _onTimeout);
    }
    return _inner(arg1, arg2).timeout(_duration);
  }
}
