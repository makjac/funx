import 'package:funx/src/core/func.dart';
import 'package:funx/src/reliability/circuit_breaker.dart';
import 'package:funx/src/reliability/resilience_policy.dart';
import 'package:funx/src/reliability/resilience_policy_builder.dart';

/// Applies a [ResiliencePolicy] to no-parameter functions.
///
/// Example:
/// ```dart
/// final call = Func<String>(() => api.fetch())
///   .withPolicy(ResiliencePolicy<String>(
///     timeout: Duration(seconds: 5),
///     retry: RetryConfig(maxAttempts: 3),
///     fallback: FallbackConfig(fallbackValue: 'default'),
///   ));
/// ```
extension ResilienceExtension<R> on Func<R> {
  /// Applies [policy] to this function.
  ///
  /// Decorators are applied in the order:
  /// `timeout -> retry -> circuitBreaker -> fallback`.
  Func<R> withPolicy(ResiliencePolicy<R> policy) {
    return _applyPolicy(this, policy);
  }

  /// Builds and applies a resilience policy using [builder].
  ///
  /// Example:
  /// ```dart
  /// final call = Func<String>(() => api.fetch())
  ///   .withResilience((b) => b
  ///     .timeout(Duration(seconds: 5))
  ///     .retry(maxAttempts: 3)
  ///     .fallbackValue('default'));
  /// ```
  Func<R> withResilience(
    ResiliencePolicy<R> Function(ResiliencePolicyBuilder<R> builder) builder,
  ) {
    return withPolicy(builder(ResiliencePolicyBuilder<R>()));
  }
}

/// Applies a [ResiliencePolicy] to one-parameter functions.
extension ResilienceExtension1<T, R> on Func1<T, R> {
  /// Applies [policy] to this function.
  Func1<T, R> withPolicy(ResiliencePolicy<R> policy) {
    return Func1<T, R>(
      (arg) => _applyPolicy(Func<R>(() => this(arg)), policy)(),
    );
  }

  /// Builds and applies a resilience policy using [builder].
  Func1<T, R> withResilience(
    ResiliencePolicy<R> Function(ResiliencePolicyBuilder<R> builder) builder,
  ) {
    return withPolicy(builder(ResiliencePolicyBuilder<R>()));
  }
}

/// Applies a [ResiliencePolicy] to two-parameter functions.
extension ResilienceExtension2<T1, T2, R> on Func2<T1, T2, R> {
  /// Applies [policy] to this function.
  Func2<T1, T2, R> withPolicy(ResiliencePolicy<R> policy) {
    return Func2<T1, T2, R>(
      (a, b) => _applyPolicy(Func<R>(() => this(a, b)), policy)(),
    );
  }

  /// Builds and applies a resilience policy using [builder].
  Func2<T1, T2, R> withResilience(
    ResiliencePolicy<R> Function(ResiliencePolicyBuilder<R> builder) builder,
  ) {
    return withPolicy(builder(ResiliencePolicyBuilder<R>()));
  }
}

Func<R> _applyPolicy<R>(Func<R> func, ResiliencePolicy<R> policy) {
  if (policy.isEmpty) return func;

  var decorated = func;

  final timeout = policy.timeout;
  if (timeout != null) {
    decorated = decorated.timeout(timeout);
  }

  final retry = policy.retry;
  if (retry != null) {
    decorated = decorated.retry(
      maxAttempts: retry.maxAttempts,
      backoff: retry.backoff,
      retryIf: retry.retryIf,
      onRetry: retry.onRetry,
    );
  }

  final circuitBreaker = policy.circuitBreaker;
  if (circuitBreaker != null) {
    decorated = decorated.circuitBreaker(
      CircuitBreaker(
        failureThreshold: circuitBreaker.failureThreshold,
        successThreshold: circuitBreaker.successThreshold,
        timeout: circuitBreaker.timeout,
        onStateChange: circuitBreaker.onStateChange,
      ),
    );
  }

  final fallback = policy.fallback;
  if (fallback != null) {
    decorated = _applyFallback(decorated, fallback);
  }

  return decorated;
}

Func<R> _applyFallback<R>(Func<R> func, FallbackConfig<R> config) {
  return Func<R>(() async {
    try {
      return await func();
    } catch (error) {
      final fallbackIf = config.fallbackIf;
      if (fallbackIf != null && !fallbackIf(error)) {
        rethrow;
      }

      config.onFallback?.call(error);

      final fallbackValue = config.fallbackValue;
      if (fallbackValue != null) {
        return fallbackValue;
      }

      final fallbackFunction = config.fallbackFunction;
      if (fallbackFunction != null) {
        return fallbackFunction(error);
      }

      rethrow;
    }
  });
}
