# schedule

## What it is

`schedule` executes a function once after a specified delay. It is the simplest one-shot timer decorator.

## When to use it

- Showing a tooltip after the user hovers for a short time.
- Firing a one-time analytics beacon.
- Kicking off async work later in the event loop or after a delay.

## Async / sync support

| Wrapper | Support |
|---|---|
| `Func<R>` | ✅ Async |
| `Func1<T, R>` | ✅ Async |
| `Func2<T1, T2, R>` | ✅ Async |
| `FuncSync<R>` | ✅ Sync |

## API reference

```dart
// api-reference
// On Func<R>
ScheduleExtension<R> schedule({
  required DateTime at,
  MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
  MissedExecutionCallback? onMissedExecution,
  ScheduleErrorCallback? onScheduleError,
});

// On Func1<T, R>
ScheduleExtension1<T, R> schedule({
  required DateTime at,
  MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
  MissedExecutionCallback? onMissedExecution,
  ScheduleErrorCallback? onScheduleError,
});

// On Func2<T1, T2, R>
ScheduleExtension2<T1, T2, R> schedule({
  required DateTime at,
  MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
  MissedExecutionCallback? onMissedExecution,
  ScheduleErrorCallback? onScheduleError,
});

// On FuncSync<R>
ScheduleExtensionSync<R> schedule({
  required DateTime at,
  MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
  MissedExecutionCallback? onMissedExecution,
  ScheduleErrorCallback? onScheduleError,
});
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `at` | `DateTime` | required | Time at which to execute the function. |

### Returned wrapper methods

```dart
// api-reference
ScheduleSubscription<R> start(); // Starts the schedule and returns a subscription.
// ScheduleSubscription exposes pause(), resume(), and cancel().
```

## Examples

### Basic example

```dart
final greet = Func<String>(() async => 'hello').schedule(
  at: DateTime.now().add(Duration(milliseconds: 50)),
);

final subscription = greet.start();
await Future<void>.delayed(Duration(milliseconds: 100));
subscription.cancel();
```

### Real-world example

```dart
final showHint = Func<void>(() async => logger.info('tooltip')).schedule(
  at: DateTime.now().add(Duration(milliseconds: 400)),
);

// On hover:
final subscription = showHint.start();

// On unhover:
subscription.cancel();
```

## Best practices

- Always keep the subscription returned by `start()` so you can call `cancel()`.
- Use `schedule` for one-shot delays; use `scheduleRecurring` for repeated execution.
- For Flutter widgets, cancel in `dispose()`.

## Common pitfalls

- **Lost timers**: Calling `start()` begins the timer; keep the subscription so you can cancel it later.
- **Forgetting to await**: If you do not await the returned future and the widget is disposed, the function may still run.
