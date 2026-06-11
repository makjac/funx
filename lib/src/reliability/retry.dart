import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/reliability/_reliability_engines.dart';
import 'package:funx/src/reliability/backoff.dart';

/// Applies automatic retry with backoff to no-parameter functions.
///
/// Wraps [Func] to automatically retry on exceptions with
/// configurable backoff strategies and retry conditions. The
/// [maxAttempts] parameter limits total execution attempts. The
/// [backoff] parameter controls delay between retries. The
/// [retryIf] predicate filters which exceptions trigger retry. The
/// [onRetry] callback enables monitoring retry attempts. Defaults
/// to exponential backoff with 100ms initial delay. This pattern
/// handles transient failures gracefully with progressive backoff.
///
/// Example:
/// ```dart
/// final unreliable = Func(() async {
///   if (Random().nextBool()) throw Exception('Random fail');
///   return 'Success';
/// });
///
/// final withRetry = unreliable.retry(
///   maxAttempts: 3,
///   backoff: ExponentialBackoff(
///     initialDelay: Duration(milliseconds: 100),
///   ),
///   onRetry: (attempt, e) => print('Retry $attempt: $e'),
/// );
/// ```
class RetryExtension<R> extends Func<R> {
  /// Creates retry wrapper for no-parameter function.
  ///
  /// The [_inner] parameter is function to wrap. The [maxAttempts]
  /// parameter (defaults to 3) sets maximum execution attempts
  /// including initial call. Must be at least 1. The optional
  /// [backoff] parameter (defaults to exponential backoff with 100ms
  /// initial delay) controls retry delays. The optional [retryIf]
  /// predicate determines which exceptions trigger retry (defaults to
  /// all exceptions). The optional [onRetry] callback is invoked
  /// before each retry with attempt number and exception.
  ///
  /// Throws:
  /// - [AssertionError] if maxAttempts is less than 1
  ///
  /// Example:
  /// ```dart
  /// final withRetry = RetryExtension(
  ///   myFunc,
  ///   maxAttempts: 5,
  ///   backoff: LinearBackoff(
  ///     initialDelay: Duration(seconds: 1),
  ///     increment: Duration(seconds: 1),
  ///   ),
  ///   retryIf: (e) => e is NetworkException,
  /// );
  /// ```
  RetryExtension(
    this._inner, {
    this.maxAttempts = 3,
    BackoffStrategy? backoff,
    this.retryIf,
    this.onRetry,
  }) : backoff =
           backoff ??
           const ExponentialBackoff(
             initialDelay: Duration(milliseconds: 100),
           ),
       _engine = RetryEngine<R>(
         maxAttempts: maxAttempts,
         backoff: backoff,
         retryIf: retryIf,
         onRetry: onRetry,
       ),
       super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Maximum number of execution attempts including initial call.
  final int maxAttempts;

  /// Strategy calculating delays between retry attempts.
  final BackoffStrategy backoff;

  /// Predicate determining which exceptions trigger retry.
  final bool Function(Object error)? retryIf;

  /// Callback invoked before each retry attempt.
  final void Function(int attempt, Object error)? onRetry;

  final RetryEngine<R> _engine;

  @override
  Future<R> call() => _engine.run(_inner.call);
}

/// Applies automatic retry with backoff to one-parameter functions.
///
/// Wraps [Func1] to automatically retry on exceptions with
/// configurable backoff strategies and retry conditions. The
/// [maxAttempts] parameter limits total execution attempts. The
/// [backoff] parameter controls delay between retries. The
/// [retryIf] predicate filters which exceptions trigger retry. The
/// [onRetry] callback enables monitoring retry attempts. Defaults
/// to exponential backoff with 100ms initial delay. This pattern
/// handles transient failures gracefully with progressive backoff.
///
/// Example:
/// ```dart
/// final fetch = Func1<String, Data>((id) async {
///   return await api.fetch(id);
/// }).retry(
///   maxAttempts: 3,
///   retryIf: (e) => e is TimeoutException,
/// );
/// ```
class RetryExtension1<T, R> extends Func1<T, R> {
  /// Creates retry wrapper for one-parameter function.
  ///
  /// The [_inner] parameter is function to wrap. See
  /// [RetryExtension] constructor for parameter documentation.
  ///
  /// Example:
  /// ```dart
  /// final withRetry = RetryExtension1(
  ///   myFunc,
  ///   maxAttempts: 5,
  ///   backoff: ConstantBackoff(Duration(seconds: 2)),
  /// );
  /// ```
  RetryExtension1(
    this._inner, {
    this.maxAttempts = 3,
    BackoffStrategy? backoff,
    this.retryIf,
    this.onRetry,
  }) : backoff =
           backoff ??
           const ExponentialBackoff(
             initialDelay: Duration(milliseconds: 100),
           ),
       _engine = RetryEngine<R>(
         maxAttempts: maxAttempts,
         backoff: backoff,
         retryIf: retryIf,
         onRetry: onRetry,
       ),
       super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Maximum number of execution attempts including initial call.
  final int maxAttempts;

  /// Strategy calculating delays between retry attempts.
  final BackoffStrategy backoff;

  /// Predicate determining which exceptions trigger retry.
  final bool Function(Object error)? retryIf;

  /// Callback invoked before each retry attempt.
  final void Function(int attempt, Object error)? onRetry;

  final RetryEngine<R> _engine;

  @override
  Future<R> call(T arg) => _engine.run(() => _inner(arg));
}

/// Applies automatic retry with backoff to two-parameter functions.
///
/// Wraps [Func2] to automatically retry on exceptions with
/// configurable backoff strategies and retry conditions. The
/// [maxAttempts] parameter limits total execution attempts. The
/// [backoff] parameter controls delay between retries. The
/// [retryIf] predicate filters which exceptions trigger retry. The
/// [onRetry] callback enables monitoring retry attempts. Defaults
/// to exponential backoff with 100ms initial delay. This pattern
/// handles transient failures gracefully with progressive backoff.
///
/// Example:
/// ```dart
/// final update = Func2<String, Data, void>((id, data) async {
///   await db.update(id, data);
/// }).retry(
///   maxAttempts: 3,
///   onRetry: (attempt, e) => print('Retry $attempt: $e'),
/// );
/// ```
class RetryExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates retry wrapper for two-parameter function.
  ///
  /// The [_inner] parameter is function to wrap. See
  /// [RetryExtension] constructor for parameter documentation.
  ///
  /// Example:
  /// ```dart
  /// final withRetry = RetryExtension2(
  ///   myFunc,
  ///   maxAttempts: 5,
  ///   backoff: ConstantBackoff(Duration(seconds: 2)),
  /// );
  /// ```
  RetryExtension2(
    this._inner, {
    this.maxAttempts = 3,
    BackoffStrategy? backoff,
    this.retryIf,
    this.onRetry,
  }) : backoff =
           backoff ??
           const ExponentialBackoff(
             initialDelay: Duration(milliseconds: 100),
           ),
       _engine = RetryEngine<R>(
         maxAttempts: maxAttempts,
         backoff: backoff,
         retryIf: retryIf,
         onRetry: onRetry,
       ),
       super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Maximum number of execution attempts including initial call.
  final int maxAttempts;

  /// Strategy calculating delays between retry attempts.
  final BackoffStrategy backoff;

  /// Predicate determining which exceptions trigger retry.
  final bool Function(Object error)? retryIf;

  /// Callback invoked before each retry attempt.
  final void Function(int attempt, Object error)? onRetry;

  final RetryEngine<R> _engine;

  @override
  Future<R> call(T1 arg1, T2 arg2) => _engine.run(() => _inner(arg1, arg2));
}
