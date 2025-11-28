/// Timeout mechanism for limiting function execution time.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Enforces time limit on function execution by throwing exception on
/// timeout.
///
/// Wraps [_inner] function with timeout constraint using [_duration] as
/// maximum execution time. If execution exceeds the limit, throws
/// [TimeoutException] unless [_onTimeout] callback is provided. The
/// optional [_onTimeout] callback executes when timeout occurs, providing
/// opportunity to return default value or handle timeout gracefully. Uses
/// [Future.timeout] to implement time limit enforcement.
///
/// Returns a [Future] of type [R] from the executed function if it
/// completes within the time limit, or the result from [_onTimeout]
/// callback if provided and timeout occurs.
///
/// Throws:
/// - [TimeoutException] when execution exceeds [_duration] and no
/// [_onTimeout] callback is provided
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
  /// Creates a timeout wrapper for function.
  ///
  /// Wraps [_inner] function with timeout enforcement using [_duration] as
  /// time limit. The optional [_onTimeout] callback handles timeout events
  /// and can provide fallback values. If omitted, timeout throws
  /// [TimeoutException]. The wrapper applies timeout to each execution
  /// independently.
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

  /// The wrapped function to execute with timeout constraint.
  final Func<R> _inner;

  /// The maximum duration allowed for execution.
  final Duration _duration;

  /// Optional callback to handle timeout events and provide fallback.
  final FutureOr<R> Function()? _onTimeout;

  @override
  Future<R> call() async {
    if (_onTimeout != null) {
      return _inner().timeout(_duration, onTimeout: _onTimeout);
    }
    return _inner().timeout(_duration);
  }
}

/// Enforces time limit on single-parameter function execution.
///
/// Wraps [_inner] function accepting parameter [T] with timeout constraint
/// using [_duration] as maximum execution time. If execution exceeds the
/// limit, throws [TimeoutException] unless [_onTimeout] callback is
/// provided. The optional [_onTimeout] callback executes when timeout
/// occurs, providing opportunity to return default value or handle timeout
/// gracefully. Uses [Future.timeout] to implement time limit enforcement.
///
/// Returns a [Future] of type [R] from the executed function if it
/// completes within the time limit, or the result from [_onTimeout]
/// callback if provided and timeout occurs.
///
/// Throws:
/// - [TimeoutException] when execution exceeds [_duration] and no
/// [_onTimeout] callback is provided
///
/// Example:
/// ```dart
/// final fetch = Func1<String, Data>((id) async {
///   return await api.fetch(id);
/// }).timeout(Duration(seconds: 5));
/// ```
class TimeoutExtension1<T, R> extends Func1<T, R> {
  /// Creates a timeout wrapper for single-parameter function.
  ///
  /// Wraps [_inner] function accepting parameter [T] with timeout
  /// enforcement using [_duration] as time limit. The optional [_onTimeout]
  /// callback handles timeout events and can provide fallback values. If
  /// omitted, timeout throws [TimeoutException]. The wrapper applies
  /// timeout to each execution independently.
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

  /// The wrapped function to execute with timeout constraint.
  final Func1<T, R> _inner;

  /// The maximum duration allowed for execution.
  final Duration _duration;

  /// Optional callback to handle timeout events and provide fallback.
  final FutureOr<R> Function()? _onTimeout;

  @override
  Future<R> call(T arg) async {
    if (_onTimeout != null) {
      return _inner(arg).timeout(_duration, onTimeout: _onTimeout);
    }
    return _inner(arg).timeout(_duration);
  }
}

/// Enforces time limit on two-parameter function execution.
///
/// Wraps [_inner] function accepting parameters [T1] and [T2] with timeout
/// constraint using [_duration] as maximum execution time. If execution
/// exceeds the limit, throws [TimeoutException] unless [_onTimeout]
/// callback is provided. The optional [_onTimeout] callback executes when
/// timeout occurs, providing opportunity to return default value or handle
/// timeout gracefully. Uses [Future.timeout] to implement time limit
/// enforcement.
///
/// Returns a [Future] of type [R] from the executed function if it
/// completes within the time limit, or the result from [_onTimeout]
/// callback if provided and timeout occurs.
///
/// Throws:
/// - [TimeoutException] when execution exceeds [_duration] and no
/// [_onTimeout] callback is provided
///
/// Example:
/// ```dart
/// final fetch = Func2<String, int, Data>((id, version) async {
///   return await api.fetch(id, version);
/// }).timeout(Duration(seconds: 5));
/// ```
class TimeoutExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a timeout wrapper for two-parameter function.
  ///
  /// Wraps [_inner] function accepting parameters [T1] and [T2] with
  /// timeout enforcement using [_duration] as time limit. The optional
  /// [_onTimeout] callback handles timeout events and can provide fallback
  /// values. If omitted, timeout throws [TimeoutException]. The wrapper
  /// applies timeout to each execution independently.
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

  /// The wrapped function to execute with timeout constraint.
  final Func2<T1, T2, R> _inner;

  /// The maximum duration allowed for execution.
  final Duration _duration;

  /// Optional callback to handle timeout events and provide fallback.
  final FutureOr<R> Function()? _onTimeout;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    if (_onTimeout != null) {
      return _inner(arg1, arg2).timeout(_duration, onTimeout: _onTimeout);
    }
    return _inner(arg1, arg2).timeout(_duration);
  }
}
