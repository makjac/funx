# Repeat

## What it is

`repeat` executes the wrapped function multiple times, optionally until a condition is met. It can be used as a decorator or as a standalone helper.

## When to use it

- Polling loops.
- Retrying with a custom condition.
- Executing a side effect a fixed number of times.

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
// As a decorator on Func<R>
Func<R> repeat({
  int? times,
  Duration? interval,
  bool Function(R result)? until,
  void Function(int iteration, R result)? onIteration,
});

// As a decorator on Func1<T, R>
Func1<T, R> repeat({
  int? times,
  Duration? interval,
  bool Function(R result)? until,
  void Function(int iteration, R result)? onIteration,
});

// As a decorator on Func2<T1, T2, R>
Func2<T1, T2, R> repeat({
  int? times,
  Duration? interval,
  bool Function(R result)? until,
  void Function(int iteration, R result)? onIteration,
});
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `times` | `int?` | `null` | Maximum number of repetitions. `null` means infinite, so always provide `times` or `until`. |
| `interval` | `Duration?` | `null` | Optional delay between repetitions. |
| `until` | `bool Function(R)?` | `null` | If provided, stops early when the predicate returns `true`. |
| `onIteration` | `void Function(int, R)?` | `null` | Callback invoked after each iteration. |

## Examples

### Basic example

```dart
var calls = 0;
final counter = Func<int>(() async => ++calls).repeat(times: 3);

print(await counter()); // 3
```

### Real-world example

```dart
final waitForReady = Func<Status>(() async => await api.status() as Status).repeat(
  times: 20,
  until: (status) => status.ready,
  interval: Duration(seconds: 1),
);

print(await waitForReady());
```

## Best practices

- Always set a finite `times` to avoid infinite loops.
- Use `delay` to avoid tight polling loops.
- Combine with `timeout()` to add a hard deadline.

## Common pitfalls

- **No delay polling**: Without a delay, the loop can consume excessive CPU.
- **Until predicate never true**: If `until` never matches, `repeat` returns the last result after `times` attempts.
