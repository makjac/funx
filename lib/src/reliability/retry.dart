import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/reliability/backoff.dart';

/// Extension on [Func] that adds retry capabilities.
///
/// Automatically retries the function when it throws an exception,
/// with configurable backoff strategies and retry conditions.
///
/// Example:
/// ```dart
/// final unreliableFunc = Func(() async {
///   if (Random().nextBool()) throw Exception('Random failure');
///   return 'Success';
/// });
///
/// final withRetry = unreliableFunc.retry(
///   maxAttempts: 3,
///   backoff: ExponentialBackoff(initialDelay: Duration(milliseconds: 100)),
/// );
///
/// final result = await withRetry(); // Retries up to 3 times
/// ```
class RetryExtension<R> extends Func<R> {
  /// Creates a retry wrapper around the given [_inner] function.
  ///
  /// - [maxAttempts]: Maximum number of attempts (including the initial call).
  ///   Must be at least 1. Defaults to 3.
  /// - [backoff]: Strategy for calculating delays between retries.
  ///   Defaults to [ExponentialBackoff] with 100ms initial delay.
  /// - [retryIf]: Optional predicate to determine if an exception should
  ///   trigger a retry. If not provided, all exceptions trigger retries.
  /// - [onRetry]: Optional callback invoked before each retry attempt.
  ///   Receives the attempt number and the exception that triggered the retry.
  RetryExtension(
    this._inner, {
    this.maxAttempts = 3,
    BackoffStrategy? backoff,
    this.retryIf,
    this.onRetry,
  }) : assert(maxAttempts >= 1, 'maxAttempts must be at least 1'),
       backoff =
           backoff ??
           const ExponentialBackoff(
             initialDelay: Duration(milliseconds: 100),
           ),
       super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Maximum number of attempts (including the initial call).
  final int maxAttempts;

  /// Strategy for calculating delays between retries.
  final BackoffStrategy backoff;

  /// Optional predicate to determine if an exception should trigger a retry.
  final bool Function(Object error)? retryIf;

  /// Optional callback invoked before each retry attempt.
  final void Function(int attempt, Object error)? onRetry;

  @override
  Future<R> call() async {
    var attempt = 0;
    Object? lastError;

    while (attempt < maxAttempts) {
      attempt++;
      try {
        return await _inner();
      } catch (error) {
        lastError = error;

        // Check if we should retry this error
        if (retryIf != null && !retryIf!(error)) {
          rethrow;
        }

        // If this was the last attempt, rethrow
        if (attempt >= maxAttempts) {
          rethrow;
        }

        // Calculate backoff delay and notify callback
        final delay = backoff.calculate(attempt: attempt);
        onRetry?.call(attempt, error);

        // Wait before retrying
        await Future<void>.delayed(delay);
      }
    }

    // This should never be reached, but satisfies static analysis
    // If we get here, lastError must be set and we exhausted retries
    Error.throwWithStackTrace(
      lastError!,
      lastError is Error
          ? lastError.stackTrace ?? StackTrace.current
          : StackTrace.current,
    );
  }
}

/// Extension on [Func1] that adds retry capabilities.
///
/// See [RetryExtension] for details.
class RetryExtension1<T, R> extends Func1<T, R> {
  /// Creates a retry wrapper around the given [_inner] function.
  ///
  /// See [RetryExtension] for parameter documentation.
  RetryExtension1(
    this._inner, {
    this.maxAttempts = 3,
    BackoffStrategy? backoff,
    this.retryIf,
    this.onRetry,
  }) : assert(maxAttempts >= 1, 'maxAttempts must be at least 1'),
       backoff =
           backoff ??
           const ExponentialBackoff(
             initialDelay: Duration(milliseconds: 100),
           ),
       super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Maximum number of attempts (including the initial call).
  final int maxAttempts;

  /// Strategy for calculating delays between retries.
  final BackoffStrategy backoff;

  /// Optional predicate to determine if an exception should trigger a retry.
  final bool Function(Object error)? retryIf;

  /// Optional callback invoked before each retry attempt.
  final void Function(int attempt, Object error)? onRetry;

  @override
  Future<R> call(T arg) async {
    var attempt = 0;
    Object? lastError;

    while (attempt < maxAttempts) {
      attempt++;
      try {
        return await _inner(arg);
      } catch (error) {
        lastError = error;

        // Check if we should retry this error
        if (retryIf != null && !retryIf!(error)) {
          rethrow;
        }

        // If this was the last attempt, rethrow
        if (attempt >= maxAttempts) {
          rethrow;
        }

        // Calculate backoff delay and notify callback
        final delay = backoff.calculate(attempt: attempt);
        onRetry?.call(attempt, error);

        // Wait before retrying
        await Future<void>.delayed(delay);
      }
    }

    // This should never be reached, but satisfies static analysis
    // If we get here, lastError must be set and we exhausted retries
    Error.throwWithStackTrace(
      lastError!,
      lastError is Error
          ? lastError.stackTrace ?? StackTrace.current
          : StackTrace.current,
    );
  }
}

/// Extension on [Func2] that adds retry capabilities.
///
/// See [RetryExtension] for details.
class RetryExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a retry wrapper around the given [_inner] function.
  ///
  /// See [RetryExtension] for parameter documentation.
  RetryExtension2(
    this._inner, {
    this.maxAttempts = 3,
    BackoffStrategy? backoff,
    this.retryIf,
    this.onRetry,
  }) : assert(maxAttempts >= 1, 'maxAttempts must be at least 1'),
       backoff =
           backoff ??
           const ExponentialBackoff(
             initialDelay: Duration(milliseconds: 100),
           ),
       super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Maximum number of attempts (including the initial call).
  final int maxAttempts;

  /// Strategy for calculating delays between retries.
  final BackoffStrategy backoff;

  /// Optional predicate to determine if an exception should trigger a retry.
  final bool Function(Object error)? retryIf;

  /// Optional callback invoked before each retry attempt.
  final void Function(int attempt, Object error)? onRetry;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    var attempt = 0;
    Object? lastError;

    while (attempt < maxAttempts) {
      attempt++;
      try {
        return await _inner(arg1, arg2);
      } catch (error) {
        lastError = error;

        // Check if we should retry this error
        if (retryIf != null && !retryIf!(error)) {
          rethrow;
        }

        // If this was the last attempt, rethrow
        if (attempt >= maxAttempts) {
          rethrow;
        }

        // Calculate backoff delay and notify callback
        final delay = backoff.calculate(attempt: attempt);
        onRetry?.call(attempt, error);

        // Wait before retrying
        await Future<void>.delayed(delay);
      }
    }

    // This should never be reached, but satisfies static analysis
    // If we get here, lastError must be set and we exhausted retries
    Error.throwWithStackTrace(
      lastError!,
      lastError is Error
          ? lastError.stackTrace ?? StackTrace.current
          : StackTrace.current,
    );
  }
}
