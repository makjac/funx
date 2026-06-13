# scheduleCustom

## What it is

`scheduleCustom` lets you define your own scheduling policy through a `scheduler` function. The scheduler receives the last execution time and returns the next execution time, allowing irregular or adaptive schedules.

## When to use it

- Exponential backoff polling.
- Adaptive schedules that respond to load or result values.
- Any schedule that cannot be expressed by `schedule` or `scheduleRecurring`.

## Async / sync support

| Wrapper | Support |
|---|---|
| `Func<R>` | ✅ Async |
| `FuncSync<R>` | ✅ Sync |

## API reference

```dart
// api-reference
// On Func<R>
ScheduleExtension<R> scheduleCustom({
  required DateTime Function(DateTime? lastExecution) scheduler,
  int? maxIterations,
  bool Function(R result)? stopCondition,
  ScheduleTickCallback? onTick,
  ScheduleErrorCallback? onScheduleError,
});

// On FuncSync<R>
ScheduleExtensionSync<R> scheduleCustom({
  required DateTime Function(DateTime? lastExecution) scheduler,
  int? maxIterations,
  bool Function(R result)? stopCondition,
  ScheduleTickCallback? onTick,
  ScheduleErrorCallback? onScheduleError,
});
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `scheduler` | `DateTime Function(DateTime? lastExecution)` | required | Returns the next execution time. |
| `maxIterations` | `int?` | `null` | Stops after this many executions. |
| `stopCondition` | `bool Function(R result)?` | `null` | Optional early-stop predicate. |

### `scheduler` contract

- `lastExecution` is the time of the previous execution; `null` on the first call.
- Return a `DateTime` in the future to schedule the next execution.
- Use `maxIterations` or `stopCondition` to stop the scheduler.

## Examples

### Basic example

```dart
var callCount = 0;
final task = Func<int>(() async => ++callCount).scheduleCustom(
  scheduler: (_) => DateTime.now().add(Duration(milliseconds: 50)),
  maxIterations: 3,
);

final subscription = task.start();
await Future<void>.delayed(Duration(milliseconds: 300));
subscription.cancel();
// callCount == 3
```

### Real-world example

```dart
var iteration = 0;
final pollWithBackoff = Func<Status>(() async => api.status() as Status)
  .scheduleCustom(
    scheduler: (_) {
      final base = Duration(seconds: 1);
      if (iteration > 5) iteration = 5;
      final delay = base * (1 << iteration);
      iteration++;
      return DateTime.now().add(delay);
    },
    stopCondition: (status) => status.ready,
  );

final subscription = pollWithBackoff.start();
await Future<void>.delayed(Duration(seconds: 5));
subscription.cancel();
```

## Best practices

- Cap exponential growth so delays do not become unreasonably long.
- Use `maxIterations` or `stopCondition` to stop the scheduler cleanly.
- Keep the policy pure when possible; side effects make schedules hard to reason about.

## Common pitfalls

- **First-execution timing**: The scheduler is called before the first execution, so `lastExecution` is `null`. Returning the current time starts immediately; returning a future `DateTime` defers the first run.
- **Infinite loops**: If the scheduler never reaches `maxIterations` and `stopCondition` is absent, the scheduler runs forever.
