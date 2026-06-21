# Retry

## What it is

Retry re-executes a function when it throws, up to a maximum number of attempts. It supports configurable delay/backoff, jitter, and filtering of retryable exceptions.

## When to use it

- Network requests that fail transiently.
- Flaky external APIs.
- Operations that may briefly contend for locks or resources.

## Async / sync support

| Wrapper | Support |
|---|---|
| `Func<R>` | ✅ Async |
| `Func1<T, R>` | ✅ Async |
| `Func2<T1, T2, R>` | ✅ Async |
| `FuncSync<R>` | ❌ No |

## API reference

```dart
// api-reference
// On Func<R>
Func<R> retry({
  int maxAttempts = 3,
  BackoffStrategy? backoff,
  bool Function(Object error)? retryIf,
  void Function(int attempt, Object error)? onRetry,
});

// On Func1<T, R>
Func1<T, R> retry({
  int maxAttempts = 3,
  BackoffStrategy? backoff,
  bool Function(Object error)? retryIf,
  void Function(int attempt, Object error)? onRetry,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> retry({
  int maxAttempts = 3,
  BackoffStrategy? backoff,
  bool Function(Object error)? retryIf,
  void Function(int attempt, Object error)? onRetry,
});
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `maxAttempts` | `int` | `3` | Maximum total attempts (including the first). |
| `backoff` | `BackoffStrategy?` | `null` | Backoff strategy between attempts. See [Backoff](./backoff.md). |
| `retryIf` | `bool Function(Object error)?` | `null` | Predicate deciding whether an error is retryable. |
| `onRetry` | `void Function(int attempt, Object error)?` | `null` | Called before each retry. |

## Examples

### Basic example

```dart
var attempt = 0;
final flaky = Func<String>(() async {
  attempt++;
  if (attempt < 3) throw Exception('fail');
  return 'success';
}).retry(maxAttempts: 5);

print(await flaky()); // success
// attempt == 3
```

### Real-world example

```dart
final fetchUser = Func1<String, User>((id) async {
  return api.user(id) as User;
}).retry(
  maxAttempts: 4,
  backoff: ExponentialBackoff(
    initialDelay: Duration(milliseconds: 200),
    maxDelay: Duration(seconds: 5),
  ),
  retryIf: (error) => error is NetworkException,
);

// Usage
print(await fetchUser('user-123'));
```

## Best practices

- Always set `maxAttempts` to a finite value.
- Use `retryIf` to avoid retrying programming errors or auth failures.
- Combine with `backoff` to avoid hammering a failing service.
- Place retry outside timeouts if you want each attempt to have its own deadline, or inside if the deadline covers all attempts.

## Common pitfalls

- **Retrying too much**: Without a backoff, retries can overload a recovering service.
- **Retrying everything**: A `retryIf` that returns `true` for every error can mask logic bugs and waste time.
- **Uncaught final failure**: After exhausting attempts, the last exception is rethrown; handle it at the call site.
