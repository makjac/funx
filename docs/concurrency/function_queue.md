# Function Queue

## What it is

Function queue serializes calls through a FIFO queue. Unlike a lock, which simply waits for the resource, a queued function gives explicit queue semantics and is available only for unary (`Func1`) and binary (`Func2`) wrappers.

## When to use it

- Sequencing user actions (e.g., undo/redo, command queue).
- Ordered processing of messages or jobs.
- Any workload where order of arrival must be preserved.

## Async / sync support

| Wrapper | Support |
|---|---|
| `Func<R>` | ❌ No |
| `Func1<T, R>` | ✅ Async |
| `Func2<T1, T2, R>` | ✅ Async |
| `FuncSync<R>` | ❌ No |

## API reference

```dart
// api-reference
// On Func1<T, R>
Func1<T, R> functionQueue({int? capacity});

// On Func2<T1, T2, R>
Func2<T1, T2, R> functionQueue({int? capacity});
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `capacity` | `int?` | `null` | Maximum number of queued calls. `null` means unbounded. |

### Returned wrapper methods

```dart
// api-reference
int get queueLength; // Current number of pending items in the queue.
```

## Examples

### Basic example

```dart
var log = <int>[];
final process = Func1<int, void>((value) async {
  await Future<void>.delayed(Duration(milliseconds: 10));
  log.add(value);
}).queue(concurrency: 1);

process(1);
process(2);
process(3);

await Future<void>.delayed(Duration(milliseconds: 100));
// log == [1, 2, 3]
```

### Real-world example

```dart
final submitCommand = Func1<Command, void>((command) async {
  await Future<void>.delayed(Duration(milliseconds: 10));
}).queue(concurrency: 1, maxQueueSize: 100);

// UI calls submitCommand(...) in order; commands run one at a time.

await submitCommand(Command());
```

## Best practices

- Set a `capacity` if callers can enqueue faster than the function can process to avoid unbounded memory growth.
- Monitor `queueLength` in UI code to show a loading indicator.
- Keep queue items small; avoid queuing large objects.

## Common pitfalls

- **Capacity overflow**: If `capacity` is set and the queue is full, additional calls throw `StateError`.
- **Assuming lock semantics**: A queue preserves order but still runs one at a time; use `lock()` if order is irrelevant.
