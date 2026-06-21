# scheduleRecurring

## What it is

`scheduleRecurring` runs a function repeatedly at a fixed interval until cancelled or until a predicate tells it to stop.

## When to use it

- Background polling of an API.
- Heartbeat or keep-alive pings.
- Periodic cleanup or cache refresh.

## Async / sync support

| Wrapper | Support |
|---|---|
| `Func<R>` | ✅ Async |
| `FuncSync<R>` | ✅ Sync |

## API reference

```dart
// api-reference
// On Func<R>
ScheduleExtension<R> scheduleRecurring({
  required Duration interval,
  int? maxIterations,
  bool Function(R result)? stopCondition,
  MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
  MissedExecutionCallback? onMissedExecution,
  ScheduleTickCallback? onTick,
  ScheduleErrorCallback? onScheduleError,
  bool executeImmediately = false,
});

// On FuncSync<R>
ScheduleExtensionSync<R> scheduleRecurring({
  required Duration interval,
  int? maxIterations,
  bool Function(R result)? stopCondition,
  MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
  MissedExecutionCallback? onMissedExecution,
  ScheduleTickCallback? onTick,
  ScheduleErrorCallback? onScheduleError,
  bool executeImmediately = false,
});
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `interval` | `Duration` | required | Delay between executions. |
| `stopCondition` | `bool Function(R result)?` | `null` | If provided, the scheduler stops when this predicate returns `true`. |

### Returned `ScheduleExtension` methods

```dart
// api-reference
ScheduleSubscription<R> start(); // Begins recurring execution.
// ScheduleSubscription exposes pause(), resume(), and cancel().
```

## Examples

### Basic example

```dart
var counter = 0;
final ticker = Func<int>(() async => ++counter).scheduleRecurring(
  interval: Duration(milliseconds: 50),
  stopCondition: (value) => value >= 3,
);

final subscription = ticker.start();
await Future<void>.delayed(Duration(milliseconds: 300));
subscription.cancel();
// counter == 3
```

### Real-world example

```dart
final pollStatus = Func<Status>(() async => api.status() as Status)
  .scheduleRecurring(
    interval: Duration(seconds: 10),
    stopCondition: (status) => status.ready,
  );

final subscription = pollStatus.start();
await Future<void>.delayed(Duration(seconds: 5));
subscription.cancel();
```

## Best practices

- Always call `cancel()` on the subscription when the component is disposed to avoid memory leaks.
- Keep the interval longer than the expected execution time; otherwise executions will queue up or overlap.
- Use `stopCondition` for finite tasks to avoid manual cleanup.

## Common pitfalls

- **No automatic start**: Calling `scheduleRecurring` returns a controller; you must call `start()` to begin execution.
- **Overlapping executions**: If the function is slower than the interval, executions may overlap; add a lock or use `throttle` if this is a problem.
