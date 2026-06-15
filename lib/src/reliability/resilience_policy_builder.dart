// Builder methods intentionally return `this` to enable a fluent API.
// ignore_for_file: avoid_returning_this

import 'package:funx/src/reliability/backoff.dart';
import 'package:funx/src/reliability/circuit_breaker.dart';
import 'package:funx/src/reliability/resilience_policy.dart';

/// Fluent builder for constructing a [ResiliencePolicy].
///
/// Example:
/// ```dart
/// final policy = ResiliencePolicyBuilder<String>()
///   .timeout(Duration(seconds: 5))
///   .retry(maxAttempts: 3)
///   .circuitBreaker(failureThreshold: 5)
///   .fallback(fallbackValue: 'default')
///   .build();
/// ```
class ResiliencePolicyBuilder<R> {
  Duration? _timeout;
  RetryConfig? _retry;
  CircuitBreakerConfig? _circuitBreaker;
  FallbackConfig<R>? _fallback;

  /// Sets a per-call timeout applied innermost.
  ResiliencePolicyBuilder<R> timeout(Duration duration) {
    _timeout = duration;
    return this;
  }

  /// Sets retry configuration.
  ///
  /// [maxAttempts] defaults to 3. When [backoff] is omitted the policy uses
  /// [ExponentialBackoff] with a 100 ms initial delay.
  ResiliencePolicyBuilder<R> retry({
    int maxAttempts = 3,
    BackoffStrategy? backoff,
    bool Function(Object error)? retryIf,
    void Function(int attempt, Object error)? onRetry,
  }) {
    _retry = RetryConfig(
      maxAttempts: maxAttempts,
      backoff: backoff,
      retryIf: retryIf,
      onRetry: onRetry,
    );
    return this;
  }

  /// Sets circuit breaker configuration.
  ///
  /// A fresh [CircuitBreaker] is created from this config when the policy is
  /// applied.
  ResiliencePolicyBuilder<R> circuitBreaker({
    int failureThreshold = 5,
    int successThreshold = 2,
    Duration timeout = const Duration(seconds: 60),
    void Function(
      CircuitBreakerState oldState,
      CircuitBreakerState newState,
    )?
    onStateChange,
  }) {
    _circuitBreaker = CircuitBreakerConfig(
      failureThreshold: failureThreshold,
      successThreshold: successThreshold,
      timeout: timeout,
      onStateChange: onStateChange,
    );
    return this;
  }

  /// Sets a constant fallback value applied outermost.
  ResiliencePolicyBuilder<R> fallbackValue(R value) {
    _fallback = FallbackConfig<R>(fallbackValue: value);
    return this;
  }

  /// Sets a fallback function that receives the thrown error.
  ResiliencePolicyBuilder<R> fallbackFunction(
    R Function(Object error) function, {
    bool Function(Object error)? fallbackIf,
    void Function(Object error)? onFallback,
  }) {
    _fallback = FallbackConfig<R>(
      fallbackFunction: function,
      fallbackIf: fallbackIf,
      onFallback: onFallback,
    );
    return this;
  }

  /// Builds the immutable [ResiliencePolicy].
  ResiliencePolicy<R> build() {
    return ResiliencePolicy<R>(
      timeout: _timeout,
      retry: _retry,
      circuitBreaker: _circuitBreaker,
      fallback: _fallback,
    );
  }
}
