# Scheduling

Scheduling decorators run functions at specific times or intervals. Backpressure controls what happens when a scheduled or invoked function cannot keep up with incoming work.

---

## schedule / scheduleRecurring / scheduleCustom

### What it is

Schedules function execution for a specific time, on a recurring interval, or using a custom scheduler function. Returns a subscription that can be paused, resumed, or canceled.

### When to use it

- Cron-like tasks
- Periodic polling
- One-time delayed jobs
- Sync cleanup tasks (via `FuncSync<R>`)

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ✅ |

### API reference

```dart
// api-reference
// One-time
ScheduleExtension<R> schedule({
  required DateTime at,
  MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
  MissedExecutionCallback? onMissedExecution,
  ScheduleErrorCallback? onScheduleError,
})

// Recurring
ScheduleExtension<R> scheduleRecurring({
  required Duration interval,
  MissedExecutionPolicy onMissed = MissedExecutionPolicy.skip,
  int? maxIterations,
  bool Function(R result)? stopCondition,
  MissedExecutionCallback? onMissedExecution,
  ScheduleTickCallback? onTick,
  ScheduleErrorCallback? onScheduleError,
  bool executeImmediately = false,
})

// Custom
ScheduleExtension<R> scheduleCustom({
  required DateTime Function(DateTime? lastExecution) scheduler,
  int? maxIterations,
  bool Function(R result)? stopCondition,
  ScheduleTickCallback? onTick,
  ScheduleErrorCallback? onScheduleError,
})
```

`ScheduleMode`:

- `once`
- `recurring`
- `custom`

`MissedExecutionPolicy`:

- `skip`
- `executeImmediately`
- `catchUp`
- `reschedule`

### Examples

**Minimal**

```dart
final task = Func<String>(() async => 'tick')
  .scheduleRecurring(interval: Duration(seconds: 1));

void main() async {
  final subscription = task.start();
  await Future<void>.delayed(Duration(milliseconds: 2500));
  subscription.cancel();
}
```

**Real world**

```dart
final backup = Func<bool>(() async {
  await backupService.run();
  return true;
}).scheduleRecurring(
  interval: Duration(hours: 24),
  onMissed: MissedExecutionPolicy.executeImmediately,
  maxIterations: 30,
  onScheduleError: (e) => logger.error('Backup failed', e),
);

backup.start();
```

### Best practices

- Always keep the subscription and call `cancel()` when the schedule is no longer needed.
- Use `maxIterations` or a `stopCondition` to avoid runaway schedules.

### Common pitfalls

- Calling the wrapped function directly throws `StateError('Scheduled functions cannot be called directly. Use start() instead.')`.
- Recurring schedules first run at `now + interval` unless `executeImmediately: true` is set.
- `catchUp` can cause a burst of executions after a long pause.

---

## backpressure

### What it is

Controls what happens when calls arrive faster than the function can process them.

### When to use it

- Streams of tasks with a slow consumer
- Load shedding
- Preventing memory exhaustion during traffic spikes

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ❌ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
BackpressureExtension<T, R> backpressure({
  required BackpressureStrategy strategy,
  int bufferSize = 100,
  double sampleRate = 0.1,
  int maxConcurrent = 10,
  BackpressureCallback? onOverflow,
  BackpressureCallback? onBufferFull,
})
```

`BackpressureStrategy`:

- `drop` — reject new items immediately.
- `dropOldest` — remove oldest buffered items.
- `buffer` — queue items up to `bufferSize`.
- `sample` — accept items probabilistically.
- `throttle` — delay execution.
- `error` — throw `StateError` on overflow.

### Examples

**Minimal**

```dart
final process = Func1<int, int>((n) async {
  await Future<void>.delayed(Duration(milliseconds: 100));
  return n;
}).backpressure(strategy: BackpressureStrategy.drop);

void main() async {
  print(await process(1)); // 1
}
```

**Real world**

```dart
final ingestEvent = Func1<Event, void>((event) async {
  await eventStore.write(event);
}).backpressure(
  strategy: BackpressureStrategy.buffer,
  bufferSize: 1000,
  maxConcurrent: 4,
  onOverflow: () => metrics.increment('events_dropped'),
);

ingestEvent(Event());
```

### Best practices

- Pair `buffer` or `throttle` with `maxConcurrent` to control throughput.
- Use `drop` or `sample` only when losing work is acceptable.

### Common pitfalls

- Overflow throws `StateError` for most strategies; messages vary by strategy.
- `backpressure` is only available on `Func1` and `Func2`.