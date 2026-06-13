# Reliability

Reliability decorators make functions resilient to transient failures. Combine them to build retry, circuit-breaker, fallback, and recovery pipelines.

---

## retry

### What it is

Automatically retries a failed function with a configurable backoff strategy.

### When to use it

- Transient network errors
- Flaky external APIs
- Idempotent operations

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> retry({
  int maxAttempts = 3,
  BackoffStrategy? backoff,
  bool Function(Object error)? retryIf,
  void Function(int attempt, Object error)? onRetry,
})

Func1<T, R> retry({
  int maxAttempts = 3,
  BackoffStrategy? backoff,
  bool Function(Object error)? retryIf,
  void Function(int attempt, Object error)? onRetry,
})

Func2<T1, T2, R> retry({
  int maxAttempts = 3,
  BackoffStrategy? backoff,
  bool Function(Object error)? retryIf,
  void Function(int attempt, Object error)? onRetry,
})
```

- `maxAttempts` — total attempts including the first one.
- `backoff` — delay strategy between attempts. See [backoff](#backoff).
- `retryIf` — predicate to decide whether an error is retryable.
- `onRetry` — called before each retry.

### Examples

**Minimal**

```dart
var attempts = 0;

final flaky = Func<String>(() async {
  attempts++;
  if (attempts < 3) throw Exception('fail');
  return 'ok';
}).retry(maxAttempts: 3);

void main() async {
  print(await flaky()); // ok
}
```

**Real world**

```dart
final fetchReport = Func1<String, Report>((id) async {
  return await reportingApi.fetch(id) as Report;
}).retry(
  maxAttempts: 5,
  backoff: ExponentialBackoff(
    initialDelay: Duration(milliseconds: 100),
    maxDelay: Duration(seconds: 5),
  ),
  retryIf: (e) => e is NetworkException,
  onRetry: (attempt, e) => logger.warn('Retry $attempt', e),
);

// Usage
print(await fetchReport('report-1'));
```

### Best practices

- Make sure the wrapped function is idempotent before retrying.
- Set `maxDelay` to cap backoff growth.

### Common pitfalls

- Non-retryable errors are re-thrown immediately.
- The total elapsed time can be large with many attempts and exponential backoff.

---

## backoff

### What it is

A family of delay strategies used by `retry` (and other mechanisms) to decide how long to wait between attempts.

### When to use it

- Configuring retry delays
- Jittering requests to avoid thundering herd

### Async / sync support

Backoff classes are standalone; they are not decorators.

### API reference

```dart
// api-reference
abstract class BackoffStrategy {
  Duration calculate({required int attempt});
}

class ConstantBackoff implements BackoffStrategy {
  const ConstantBackoff(this.delay);
}

class LinearBackoff implements BackoffStrategy {
  const LinearBackoff({
    required Duration initialDelay,
    required Duration increment,
    Duration? maxDelay,
  });
}

class ExponentialBackoff implements BackoffStrategy {
  const ExponentialBackoff({
    required Duration initialDelay,
    double multiplier = 2.0,
    Duration? maxDelay,
  });
}

class FibonacciBackoff implements BackoffStrategy {
  const FibonacciBackoff({
    required Duration baseDelay,
    Duration? maxDelay,
  });
}

class DecorrelatedJitterBackoff implements BackoffStrategy {
  DecorrelatedJitterBackoff({
    required Duration baseDelay,
    Duration? maxDelay,
    Random? random,
  });
  void reset();
}

class CustomBackoff implements BackoffStrategy {
  const CustomBackoff({
    required Duration Function(int attempt) calculator,
  });
}
```

### Examples

**Minimal**

```dart
final backoff = ExponentialBackoff(
  initialDelay: Duration(milliseconds: 100),
  maxDelay: Duration(seconds: 1),
);

void main() {
  print(backoff.calculate(attempt: 1)); // ~100ms
  print(backoff.calculate(attempt: 4)); // capped at 1s
}
```

**Real world**

```dart
final apiCall = Func<Data>(() async => await api.fetch() as Data)
  .retry(
    maxAttempts: 5,
    backoff: DecorrelatedJitterBackoff(
      baseDelay: Duration(milliseconds: 100),
      maxDelay: Duration(seconds: 5),
    ),
  );

// Usage
print(await apiCall());
```

### Best practices

- Prefer jittered backoff for distributed systems.
- Always set `maxDelay` to bound worst-case latency.

### Common pitfalls

- `DecorrelatedJitterBackoff` uses randomness; delays are non-deterministic.
- Fibonacci backoff grows faster than linear but slower than exponential.

---

## circuitBreaker

### What it is

Stops calling a failing function after a threshold of failures, then periodically allows a test call in the half-open state.

### When to use it

- Protecting against cascading failures
- Giving overloaded downstream services time to recover
- Failing fast when a dependency is unhealthy

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> circuitBreaker(CircuitBreaker breaker)
Func1<T, R> circuitBreaker(CircuitBreaker breaker)
Func2<T1, T2, R> circuitBreaker(CircuitBreaker breaker)
```

Standalone `CircuitBreaker` class:

```dart
// api-reference
final cb = CircuitBreaker(
  failureThreshold: 5,
  successThreshold: 2,
  timeout: Duration(seconds: 60),
);
cb.recordSuccess();
cb.recordFailure();
cb.reset();
print(cb.state); // closed, open, or halfOpen
```

`CircuitBreakerState`:

- `closed` — normal operation.
- `open` — calls fail fast with `CircuitBreakerOpenException`.
- `halfOpen` — one probe call is allowed to test recovery.

### Examples

**Minimal**

```dart
final fragile = Func<String>(() async {
  throw Exception('boom');
}).circuitBreaker(CircuitBreaker(failureThreshold: 2));

void main() async {
  await fragile().catchError((_) => 'ignored');
  await fragile().catchError((_) => 'ignored');
  try {
    await fragile();
  } on CircuitBreakerOpenException {
    print('breaker open');
  }
}
```

**Real world**

```dart
final breaker = CircuitBreaker(
  failureThreshold: 5,
  successThreshold: 3,
  timeout: Duration(seconds: 30),
  onStateChange: (oldState, newState) =>
      logger.info('Breaker state: $newState'),
);
final paymentCharge = Func1<ChargeRequest, ChargeResult>((request) async {
  return await paymentGateway.charge(request) as ChargeResult;
}).circuitBreaker(breaker);

// Usage
print(await paymentCharge(ChargeRequest()));
```

### Best practices

- Combine with `fallback` so open-circuit calls degrade gracefully.
- Tune `timeout` to match the downstream service's recovery time.

### Common pitfalls

- The breaker counts only actual failures; swallowed exceptions inside the function are not counted.
- `CircuitBreakerOpenException` is thrown immediately while open.

---

## fallback

### What it is

Returns a fallback value or runs a fallback function when the wrapped function fails.

### When to use it

- Graceful degradation
- Returning cached or default data on error

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> fallback({
  R? fallbackValue,
  Func<R>? fallbackFunction,
  bool Function(Object error)? fallbackIf,
  void Function(Object error)? onFallback,
})

Func1<T, R> fallback({
  R? fallbackValue,
  Func1<T, R>? fallbackFunction,
  bool Function(Object error)? fallbackIf,
  void Function(Object error)? onFallback,
})

Func2<T1, T2, R> fallback({
  R? fallbackValue,
  Func2<T1, T2, R>? fallbackFunction,
  bool Function(Object error)? fallbackIf,
  void Function(Object error)? onFallback,
})
```

Provide exactly one of `fallbackValue` or `fallbackFunction`.

### Examples

**Minimal**

```dart
final risky = Func<String>(() async {
  throw Exception('fail');
}).fallback(fallbackValue: 'default');

void main() async {
  print(await risky()); // default
}
```

**Real world**

```dart
final fetchPrice = Func1<String, Price>((symbol) async {
  return await marketApi.price(symbol) as Price;
}).fallback(
  fallbackFunction: Func1<String, Price>((symbol) async {
    return cache.latestPrice(symbol) as Price;
  }),
  fallbackIf: (e) => e is NetworkException,
  onFallback: (e) => metrics.increment('price_fallback'),
);

// Usage
print(await fetchPrice('AAPL'));
```

### Best practices

- Use `fallbackIf` to avoid masking programming errors.
- Keep fallback values cheap and deterministic.

### Common pitfalls

- Providing both `fallbackValue` and `fallbackFunction` is a usage error checked at runtime.
- The fallback itself can throw; it is not automatically retried.

---

## recover

### What it is

Runs a recovery action when the wrapped function fails. By default the original error is rethrown after the action runs.

### When to use it

- Error recovery workflows
- Logging + compensating actions
- Cleanup or state reset after a failure

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> recover(RecoveryStrategy strategy)
Func1<T, R> recover(RecoveryStrategy strategy)
Func2<T1, T2, R> recover(RecoveryStrategy strategy)
```

`RecoveryStrategy` runs a side-effect on error and rethrows by default.

### Examples

**Minimal**

```dart
final risky = Func<String>(() async {
  throw Exception('fail');
}).recover(
  RecoveryStrategy(
    onError: (error) async => print('Recovered from $error'),
  ),
);

void main() async {
  try {
    await risky();
  } catch (_) {
    print('recovered'); // recovery action ran before rethrow
  }
}
```

**Real world**

```dart
final reserveSeat = Func1<String, Ticket>((flightId) async {
  return await bookingApi.reserve(flightId) as Ticket;
}).recover(
  RecoveryStrategy(
    onError: (error) async => logger.warning(
      'Waitlisted after reservation failure',
      error,
    ),
  ),
);

// Usage
await reserveSeat('FL-123').catchError((_) => Ticket());
```

### Best practices

- Log the original error inside the recovery strategy.
- Do not use `recover` to hide non-recoverable errors silently.

### Common pitfalls

- If the recovery strategy throws, the final error is from recovery, not the original function.