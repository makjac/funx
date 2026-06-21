# Resilience Policy

## What it is

`ResiliencePolicy` composes the most common reliability decorators — `timeout`, `retry`, `circuitBreaker`, and `fallback` — into a single, reusable policy. It applies them in the order recommended for resilient remote calls, so you do not have to remember the correct chaining order.

## When to use it

- HTTP or RPC calls that need timeout, retry, circuit breaker, and fallback together.
- Any function where you want a pre-packaged resilience stack.
- When the same resilience settings are reused across multiple functions.

## Async / sync support

| Wrapper | Support |
|---|---|
| `Func<R>` | ✅ Async |
| `Func1<T, R>` | ✅ Async |
| `Func2<T1, T2, R>` | ✅ Async |
| `FuncSync<R>` | ❌ No |

## How it works

The policy applies decorators from the inside out in this order:

```
timeout -> retry -> circuitBreaker -> fallback
```

1. `timeout` limits how long a single attempt may run.
2. `retry` re-executes the function on transient failures.
3. `circuitBreaker` opens after too many consecutive failures.
4. `fallback` returns a safe default when everything else fails.

## API reference

```dart
// api-reference
// On Func<R>
Func<R> withPolicy(ResiliencePolicy<R> policy);
Func<R> withResilience(
  ResiliencePolicy<R> Function(ResiliencePolicyBuilder<R> builder) build,
);

// On Func1<T, R>
Func1<T, R> withPolicy(ResiliencePolicy<R> policy);
Func1<T, R> withResilience(
  ResiliencePolicy<R> Function(ResiliencePolicyBuilder<R> builder) build,
);

// On Func2<T1, T2, R>
Func2<T1, T2, R> withPolicy(ResiliencePolicy<R> policy);
Func2<T1, T2, R> withResilience(
  ResiliencePolicy<R> Function(ResiliencePolicyBuilder<R> builder) build,
);
```

### ResiliencePolicy

```dart
// api-reference
const ResiliencePolicy<R>({
  Duration? timeout,
  RetryConfig? retry,
  CircuitBreakerConfig? circuitBreaker,
  FallbackConfig<R>? fallback,
});
```

### ResiliencePolicyBuilder

```dart
// api-reference
ResiliencePolicyBuilder<R>()
  .timeout(Duration(seconds: 5))
  .retry(maxAttempts: 3)
  .circuitBreaker(failureThreshold: 5)
  .fallbackValue(defaultValue)
  .fallbackFunction((error) => defaultValue)
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `timeout` | `Duration?` | `null` | Maximum duration for a single attempt. |
| `retry` | `RetryConfig?` | `null` | Retry behavior including attempts and backoff. |
| `circuitBreaker` | `CircuitBreakerConfig?` | `null` | Failure threshold and recovery timeout. |
| `fallback` | `FallbackConfig<R>?` | `null` | Constant value or error-based fallback function. |

## Examples

### Basic example

```dart
final fetch = Func<String>(() async => 'data')
  .withPolicy(
    const ResiliencePolicy<String>(
      timeout: Duration(seconds: 5),
      retry: RetryConfig(maxAttempts: 3),
      fallback: FallbackConfig(fallbackValue: 'default'),
    ),
  );

print(await fetch());
```

### Fluent builder example

```dart
final fetchUser = Func1<String, String>((id) async => 'user:$id')
  .withResilience(
    (b) => b
        .timeout(const Duration(seconds: 3))
        .retry(maxAttempts: 3)
        .circuitBreaker(failureThreshold: 5)
        .fallbackValue('Unknown')
        .build(),
  );

final user = await fetchUser('user-123');
print(user);
```

### Fallback based on error

```dart
final call = Func<String>(() async => await Future.delayed(Duration(seconds: 10)))
  .withResilience(
    (b) => b
        .timeout(const Duration(seconds: 2))
        .fallbackFunction(
          (error) => error is TimeoutException ? 'timed out' : 'failed',
        )
        .build(),
  );

print(await call());
```

## Best practices

- Use `withResilience` when configuring the policy inline; use `withPolicy` when you have a pre-built policy object.
- Keep timeout short enough to fail fast, but long enough to cover normal latency.
- Set `retryIf` so you only retry transient errors, not auth or validation failures.
- Share a single `CircuitBreaker` instance manually when multiple functions target the same service.
- Place `withPolicy` after caching decorators like `memoize` so cached hits skip the resilience stack.

## Common pitfalls

- **Wrong mental model**: the policy wraps from the inside out, so timeout is the innermost layer and fallback the outermost.
- **Fresh circuit breaker**: each `withPolicy` call creates a new `CircuitBreaker` from the config. Share a breaker explicitly if you need cross-function state.
- **Fallback masking bugs**: avoid unconditional fallbacks for errors that should surface to operators.

## See also

- [Retry](./retry.md)
- [Circuit Breaker](./circuit_breaker.md)
- [Fallback](./fallback.md)
- [Timeout](./timeout.md)
