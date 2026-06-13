# Delay

## What it is

Delay inserts a fixed pause before, after, or around each function execution.

## When to use it

- Adding a small artificial delay to match user expectations (e.g., "saving..." animations).
- Pacing outgoing requests to avoid bursts.
- Combining with `repeat()` to create simple polling loops.

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
Func<R> delay(
  Duration duration, {
  DelayMode mode = DelayMode.before,
});

// On Func1<T, R>
Func1<T, R> delay(
  Duration duration, {
  DelayMode mode = DelayMode.before,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> delay(
  Duration duration, {
  DelayMode mode = DelayMode.before,
});

enum DelayMode { before, after, both }
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `duration` | `Duration` | required | Duration of the pause. |
| `mode` | `DelayMode` | `before` | When to pause: `before`, `after`, or `both`. |

## Examples

### Basic example

```dart
final ping = Func<String>(() async => 'pong').delay(
  Duration(seconds: 1),
  mode: DelayMode.before,
);

print(await ping()); // waits 1s, then prints "pong"
```

### Real-world example

```dart
final poll = Func<Status>(() async => api.status() as Status).delay(
  Duration(seconds: 5),
  mode: DelayMode.before,
);

final ready = await poll
  .repeat(times: 10, until: (s) => s.ready);
print(ready);
```

## Best practices

- Use `before` for pacing and rate smoothing.
- Use `after` when you want to guarantee a minimum visible duration (e.g., animations).
- Avoid very long `after` delays in hot paths because they block the caller.

## Common pitfalls

- **Unexpected total latency**: `DelayMode.both` adds the delay twice plus execution time.
- **Not composable with sync code**: Delay is async-only; it cannot wrap synchronous functions.
