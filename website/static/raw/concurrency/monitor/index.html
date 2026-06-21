# Monitor

## What it is

A monitor is a concurrency primitive that combines mutual exclusion with a condition-wait mechanism. A wrapped function can wait until a predicate becomes true while holding the monitor.

## When to use it

- Producer-consumer patterns where consumers must wait for data.
- Scenarios requiring both locking and signaling between tasks.
- Complex critical-section coordination.

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
Func<R> monitor([Monitor? monitor]);

// On Func1<T, R>
Func1<T, R> monitor([Monitor? monitor]);

// On Func2<T1, T2, R>
Func2<T1, T2, R> monitor([Monitor? monitor]);

class Monitor {
  Future<T> synchronized<T>(FutureOr<T> Function() computation);
  Future<void> waitUntil(bool Function() predicate);
}
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `monitor` | `Monitor?` | `Monitor()` | Optional shared monitor instance. |

## Examples

### Basic example

```dart
final monitor = Monitor();
var ready = false;

final waitForReady = Func<String>(() async {
  await monitor.synchronized(() async {
    await monitor.waitUntil(() => ready);
  });
  return 'go';
}).monitor(monitor);

waitForReady();
await Future<void>.delayed(Duration(milliseconds: 50));
ready = true;
await Future<void>.delayed(Duration(milliseconds: 50));
// Future resolves with 'go'
```

### Real-world example

```dart
final queueMonitor = Monitor();
final queue = <Task>[];

final consumer = Func<Task?>(() async {
  return await queueMonitor.synchronized<Task?>(() async {
    await queueMonitor.waitUntil(() => queue.isNotEmpty);
    return queue.removeAt(0);
  });
}).monitor(queueMonitor);

// Producer adds tasks and the consumer wakes up automatically.

await consumer();
```

## Best practices

- Always acquire the monitor with `synchronized()` before calling `waitUntil()`.
- Keep predicate checks fast because they are polled internally.
- Signal state changes by mutating shared state while holding the monitor.

## Common pitfalls

- **Calling `waitUntil` outside `synchronized`**: This leads to races; always enter the monitor first.
- **Spurious wakeups**: The predicate is re-checked on each wake, so write predicates that are correct even if they fire multiple times.
