# Timeout

## What it is

Timeout caps how long a single function invocation may run. If the inner function does not complete in time, the wrapper either throws a `TimeoutException` or returns a fallback value provided by `onTimeout`.

## When to use it

- Wrapping network calls that might hang.
- Adding a deadline to long-running computations.
- Preventing resource leaks from runaway async operations.

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
Func<R> timeout(
  Duration duration, {
  FutureOr<R> Function()? onTimeout,
});

// On Func1<T, R>
Func1<T, R> timeout(
  Duration duration, {
  FutureOr<R> Function()? onTimeout,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> timeout(
  Duration duration, {
  FutureOr<R> Function()? onTimeout,
});
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `duration` | `Duration` | required | Maximum time allowed for one execution. |
| `onTimeout` | `FutureOr<R> Function()?` | `null` | Optional fallback factory invoked on timeout. If omitted, a `TimeoutException` is thrown. |

## Examples

### Basic example

```dart
final slow = Func<String>(() async {
  await Future<void>.delayed(Duration(seconds: 5));
  return 'done';
}).timeout(Duration(seconds: 2));

try {
  await slow();
} on TimeoutException {
  print('timed out');
}
```

### Real-world example

```dart
final fetchUser = Func1<String, User>(
  (id) async => api.getUser(id) as User,
).timeout(
  Duration(seconds: 5),
  onTimeout: () => User(),
);

final user = await fetchUser('123'); // fallback if API hangs
print(user);
```

## Best practices

- Place `timeout()` as the outer layer when you want the deadline to cover retries, or inner when the deadline should apply to a single attempt.
- Provide `onTimeout` when a degraded result is acceptable; omit it when the caller must handle the failure explicitly.
- Choose deadlines based on the 99th percentile latency of the operation, not the average.

## Common pitfalls

- **Resource leak**: Timing out a future cancels the returned future but does not necessarily cancel the underlying work. The inner operation may continue running in the background.
- **Fallback mismatches**: `onTimeout` must return the same type `R` as the wrapped function, otherwise the code will not compile.
