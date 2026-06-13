# Throttle

## What it is

Throttle limits a function to at most one execution per time window. Unlike debounce, which waits for activity to stop, throttle enforces a strict minimum interval between executions.

## When to use it

- Button click handlers that should not fire more than once per second.
- Scroll or drag event handlers that need periodic updates without overwhelming the UI.
- Metrics/reporting calls that should sample at a fixed rate.

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
Func<R> throttle(
  Duration duration, {
  ThrottleMode mode = ThrottleMode.leading,
});

// On Func1<T, R>
Func1<T, R> throttle(
  Duration duration, {
  ThrottleMode mode = ThrottleMode.leading,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> throttle(
  Duration duration, {
  ThrottleMode mode = ThrottleMode.leading,
});

enum ThrottleMode { leading, trailing, both }
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `duration` | `Duration` | required | Minimum interval between executions. |
| `mode` | `ThrottleMode` | `leading` | When to execute: `leading`, `trailing`, or `both`. |

### Returned wrapper methods

```dart
// api-reference
void reset(); // Clears the throttle window so the next call executes immediately.
```

### Modes

- `leading` (default): first call executes immediately; calls inside the window throw `StateError`.
- `trailing`: first call schedules execution at the end of the window; subsequent calls inside the window return the same pending future.
- `both`: executes immediately and schedules a trailing execution.

## Examples

### Basic example

```dart
var callCount = 0;
final track = Func1<double, void>((position) async {
  callCount++;
}).throttle(Duration(milliseconds: 50));

await track(100);
try {
  await track(200);
} catch (e) {
  print('throttled: $e');
}

print('calls: $callCount'); // 1
```

### Real-world example

```dart
final saveProgress = Func1<Progress, void>(
  (progress) async {
    await cloud.save(progress);
  },
).throttle(
  Duration(seconds: 2),
  mode: ThrottleMode.trailing,
);

await saveProgress(Progress());

// Game loop calls saveProgress(progress) frequently;
// only the latest progress is saved every 2 seconds.
```

## Best practices

- Use `leading` for actions where the first user interaction must be immediate (e.g., a save button).
- Use `trailing` when you care about the final state (e.g., tracking the last scroll position).
- Call `reset()` after a major state change when you want to allow an immediate re-execution.

## Common pitfalls

- **Unhandled `StateError` in leading mode**: Calls inside the window throw. Wrap them in `try/catch` or switch to `trailing` mode.
- **Losing results in trailing mode**: Multiple calls inside the window share the same pending future, which is usually what you want, but be aware that arguments from intermediate calls are ignored.
