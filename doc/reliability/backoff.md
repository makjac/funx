# Backoff

## What it is

Backoff strategies determine how long to wait between retry attempts. `funx` provides several built-in strategies and a factory for custom ones.

## When to use it

- Pairing with `retry()` to space out repeated attempts.
- Implementing polling loops that should slow down over time.
- Any retry logic that should avoid fixed-interval hammering.

## Async / sync support

Backoff is a pure utility; it is not tied to a wrapper type.

## API reference

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

### Built-in strategies

| Strategy | Behavior |
|---|---|
| `ConstantBackoff` | Same delay every attempt. |
| `LinearBackoff` | Delay grows by a constant increment each attempt. |
| `ExponentialBackoff` | Delay multiplies by `multiplier` each attempt, capped at `maxDelay`. |
| `FibonacciBackoff` | Delay grows by Fibonacci multiples of `baseDelay`. |
| `DecorrelatedJitterBackoff` | Randomized exponential jitter to avoid thundering herd. |
| `CustomBackoff` | Delegate to your own function. |

## Examples

### Basic example

```dart
final backoff = ExponentialBackoff(
  initialDelay: Duration(milliseconds: 100),
  multiplier: 2,
  maxDelay: Duration(seconds: 5),
);

print(backoff.calculate(attempt: 1)); // 100ms
print(backoff.calculate(attempt: 2)); // 200ms
print(backoff.calculate(attempt: 3)); // 400ms
```

### Real-world example

```dart
final apiCall = Func<Data>(() async => await api.fetch() as Data)
  .retry(
    maxAttempts: 5,
    backoff: DecorrelatedJitterBackoff(
      baseDelay: Duration(milliseconds: 200),
      maxDelay: Duration(seconds: 10),
    ),
  );

// Usage
print(await apiCall());
```

## Best practices

- Always cap exponential backoff with `maxDelay`.
- Add jitter to prevent synchronized retry storms across many clients.
- Keep the first delay small so transient blips recover quickly.

## Common pitfalls

- **Attempt numbering**: Strategies are zero-indexed; verify `getDelay(0)` matches your expectations.
- **Jitter overflowing maxDelay**: Jitter is applied on top of the base delay; ensure the resulting duration is still bounded.
