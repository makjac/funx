/// Configuration classes and the immutable [ResiliencePolicy] used by
/// [withPolicy] and [withResilience].
///
/// A resilience policy composes the existing reliability decorators
/// (`timeout`, `retry`, `circuitBreaker`, `fallback`) in the order
/// recommended for resilient remote calls:
///
/// ```text
/// timeout -> retry -> circuitBreaker -> fallback
/// ```
///
/// This file is part of the `reliability` category and reuses existing
/// `BackoffStrategy` and `CircuitBreaker` types from the same category.
library;

import 'package:funx/src/reliability/backoff.dart';
import 'package:funx/src/reliability/circuit_breaker.dart';

/// Configuration for retry behavior inside a [ResiliencePolicy].
class RetryConfig {
  /// Creates a retry configuration.
  ///
  /// [maxAttempts] is the total number of calls (first attempt plus retries).
  /// [backoff] determines the delay between retries; when omitted the policy
  /// uses [ExponentialBackoff] with a 100 ms initial delay.
  /// [retryIf] filters which errors trigger a retry.
  /// [onRetry] is called before each retry attempt.
  const RetryConfig({
    this.maxAttempts = 3,
    this.backoff,
    this.retryIf,
    this.onRetry,
  }) : assert(maxAttempts >= 1, 'maxAttempts must be at least 1');

  /// Total number of attempts including the initial call.
  final int maxAttempts;

  /// Strategy calculating delays between retry attempts.
  final BackoffStrategy? backoff;

  /// Predicate determining which errors trigger a retry.
  final bool Function(Object error)? retryIf;

  /// Callback invoked before each retry attempt.
  final void Function(int attempt, Object error)? onRetry;
}

/// Configuration for circuit breaker behavior inside a [ResiliencePolicy].
class CircuitBreakerConfig {
  /// Creates a circuit breaker configuration.
  ///
  /// A fresh [CircuitBreaker] instance is built from this config whenever the
  /// policy is applied, so each decorated function gets its own breaker.
  /// Share a breaker explicitly with [CircuitBreaker] if you need one breaker
  /// across multiple functions.
  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.successThreshold = 2,
    this.timeout = const Duration(seconds: 60),
    this.onStateChange,
  }) : assert(failureThreshold > 0, 'failureThreshold must be positive'),
       assert(successThreshold > 0, 'successThreshold must be positive');

  /// Consecutive failures required to open the circuit.
  final int failureThreshold;

  /// Consecutive successes required in half-open state to close the circuit.
  final int successThreshold;

  /// Duration the circuit stays open before moving to half-open.
  final Duration timeout;

  /// Callback invoked on circuit breaker state transitions.
  final void Function(
    CircuitBreakerState oldState,
    CircuitBreakerState newState,
  )?
  onStateChange;
}

/// Configuration for fallback behavior inside a [ResiliencePolicy].
class FallbackConfig<R> {
  /// Creates a fallback configuration.
  ///
  /// Provide either [fallbackValue] or [fallbackFunction]. [fallbackFunction]
  /// receives the thrown error and can compute a fallback result based on it.
  /// [fallbackIf] decides whether a given error should trigger the fallback.
  /// [onFallback] is invoked whenever the fallback is used.
  const FallbackConfig({
    this.fallbackValue,
    this.fallbackFunction,
    this.fallbackIf,
    this.onFallback,
  }) : assert(
         fallbackValue != null || fallbackFunction != null,
         'Either fallbackValue or fallbackFunction must be provided',
       ),
       assert(
         fallbackValue == null || fallbackFunction == null,
         'Only one of fallbackValue or fallbackFunction can be provided',
       );

  /// Constant value returned when the primary function fails.
  final R? fallbackValue;

  /// Function called with the error to compute a fallback value.
  final R Function(Object error)? fallbackFunction;

  /// Predicate determining which errors trigger the fallback.
  final bool Function(Object error)? fallbackIf;

  /// Callback invoked when fallback is used.
  final void Function(Object error)? onFallback;
}

/// An immutable composition of reliability decorators.
///
/// [ResiliencePolicy] is generic only over the return type [R], so the same
/// policy can be applied to [Func], [Func1], and [Func2] wrappers.
class ResiliencePolicy<R> {
  /// Creates a resilience policy from explicit configuration.
  const ResiliencePolicy({
    this.timeout,
    this.retry,
    this.circuitBreaker,
    this.fallback,
  });

  /// Optional per-call timeout applied innermost.
  final Duration? timeout;

  /// Optional retry configuration.
  final RetryConfig? retry;

  /// Optional circuit breaker configuration.
  final CircuitBreakerConfig? circuitBreaker;

  /// Optional fallback configuration applied outermost.
  final FallbackConfig<R>? fallback;

  /// Whether this policy configures any decorator.
  bool get isEmpty =>
      timeout == null &&
      retry == null &&
      circuitBreaker == null &&
      fallback == null;

  /// Returns a copy of this policy with the given fields replaced.
  ResiliencePolicy<R> copyWith({
    Duration? timeout,
    RetryConfig? retry,
    CircuitBreakerConfig? circuitBreaker,
    FallbackConfig<R>? fallback,
    bool clearTimeout = false,
    bool clearRetry = false,
    bool clearCircuitBreaker = false,
    bool clearFallback = false,
  }) {
    return ResiliencePolicy<R>(
      timeout: clearTimeout ? null : (timeout ?? this.timeout),
      retry: clearRetry ? null : (retry ?? this.retry),
      circuitBreaker: clearCircuitBreaker
          ? null
          : (circuitBreaker ?? this.circuitBreaker),
      fallback: clearFallback ? null : (fallback ?? this.fallback),
    );
  }
}
