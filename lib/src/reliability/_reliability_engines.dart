/// Internal reliability engines shared by the arity-specific extensions.
///
/// The public extension classes are thin wrappers that capture original
/// arguments into zero-arg closures and forward execution to these engines.
library;

import 'dart:async';

import 'package:funx/src/reliability/backoff.dart';

/// Shared retry logic for all function arities.
class RetryEngine<R> {
  /// Creates a retry engine.
  RetryEngine({
    required this.maxAttempts,
    required BackoffStrategy? backoff,
    required this.retryIf,
    required this.onRetry,
  }) : backoff = backoff ??
             const ExponentialBackoff(
               initialDelay: Duration(milliseconds: 100),
             ),
       assert(maxAttempts >= 1, 'maxAttempts must be at least 1');

  /// Maximum number of execution attempts including initial call.
  final int maxAttempts;

  /// Strategy calculating delays between retry attempts.
  final BackoffStrategy backoff;

  /// Predicate determining which exceptions trigger retry.
  final bool Function(Object error)? retryIf;

  /// Callback invoked before each retry attempt.
  final void Function(int attempt, Object error)? onRetry;

  /// Runs [invoke] with the configured retry policy.
  Future<R> run(Future<R> Function() invoke) async {
    var attempt = 0;
    Object? lastError;

    while (attempt < maxAttempts) {
      attempt++;
      try {
        return await invoke();
      } catch (error) {
        lastError = error;

        if (retryIf != null && !retryIf!(error)) {
          rethrow;
        }

        if (attempt >= maxAttempts) {
          rethrow;
        }

        final delay = backoff.calculate(attempt: attempt);
        onRetry?.call(attempt, error);
        await Future<void>.delayed(delay);
      }
    }

    // coverage:ignore-start
    Error.throwWithStackTrace(
      lastError!,
      lastError is Error
          ? lastError.stackTrace ?? StackTrace.current
          : StackTrace.current,
    );
    // coverage:ignore-end
  }
}

/// Shared fallback logic for all function arities.
class FallbackEngine<R> {
  /// Creates a fallback engine.
  FallbackEngine({
    required R? fallbackValue,
    required this.fallbackIf,
    required this.onFallback,
  }) : _fallbackValue = fallbackValue;

  final R? _fallbackValue;

  /// Predicate determining if error should trigger fallback.
  final bool Function(Object error)? fallbackIf;

  /// Callback invoked when fallback is used.
  final void Function(Object error)? onFallback;

  /// Runs [invoke] and applies the configured fallback on failure.
  ///
  /// The [fallback] function is invoked when a computed fallback is needed.
  /// It must be provided by wrappers that do not supply a constant
  /// [fallbackValue].
  Future<R> run(
    Future<R> Function() invoke,
    Future<R> Function()? fallback,
  ) async {
    try {
      return await invoke();
    } catch (error) {
      if (fallbackIf != null && !fallbackIf!(error)) {
        rethrow;
      }

      onFallback?.call(error);

      if (_fallbackValue != null) {
        return _fallbackValue as R;
      }
      return fallback!();
    }
  }
}

/// Defines error recovery behavior for function execution.
///
/// Recovery strategies specify actions executed when errors occur
/// during function execution. The [onError] callback performs
/// recovery actions like state reset, service reconnection, or
/// resource cleanup. The [shouldRecover] predicate controls which
/// errors trigger recovery. The [rethrowAfterRecovery] flag
/// determines whether errors are rethrown after recovery.
class RecoveryStrategy {
  /// Creates recovery strategy with specified behavior.
  const RecoveryStrategy({
    required this.onError,
    this.shouldRecover,
    this.rethrowAfterRecovery = true,
  });

  /// Recovery action executed when error occurs.
  final Future<void> Function(Object error) onError;

  /// Predicate determining which errors trigger recovery.
  final bool Function(Object error)? shouldRecover;

  /// Whether to rethrow error after recovery completes.
  final bool rethrowAfterRecovery;
}

/// Shared recovery logic for all function arities.
class RecoverEngine<R> {
  /// Creates a recovery engine.
  RecoverEngine(this._strategy);

  final RecoveryStrategy _strategy;

  /// Runs [invoke] and applies the configured recovery strategy on failure.
  Future<R> run(Future<R> Function() invoke) async {
    try {
      return await invoke();
    } catch (error) {
      if (_strategy.shouldRecover != null &&
          !_strategy.shouldRecover!(error)) {
        rethrow;
      }

      await _strategy.onError(error);

      if (_strategy.rethrowAfterRecovery) {
        rethrow;
      }

      throw StateError(
        'Recovery strategy did not rethrow, but no return value is available',
      );
    }
  }
}
