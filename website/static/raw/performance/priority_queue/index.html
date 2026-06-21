# Priority Queue

## What it is

Priority queue orders pending executions by a priority function. Higher-priority calls run before lower-priority ones.

## When to use it

- Task schedulers where user-facing work should preempt background work.
- Message processing where some messages are urgent.
- Work queues with SLAs.

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
Func1<T, R> priorityQueue({
  required int Function(T arg) priority,
  int? capacity,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> priorityQueue({
  required int Function(T1 arg1, T2 arg2) priority,
  int? capacity,
});
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `priority` | `int Function(...)` | required | Returns priority; higher values run first. |
| `capacity` | `int?` | `null` | Maximum queue size. `null` means unbounded. |

## Examples

### Basic example

```dart
var order = <int>[];
final process = Func1<int, void>((value) async {
  order.add(value);
}).priorityQueue(priorityFn: (int value) => value);

process(1);
process(10);
process(5);

await Future<void>.delayed(Duration(milliseconds: 100));
// order == [10, 5, 1]
print(order);
```

### Real-world example

```dart
final handleTask = Func1<int, void>((priority) async {
  print('handling $priority');
}).priorityQueue(
  priorityFn: (int priority) => priority,
  maxQueueSize: 100,
);

void main() async {
  handleTask(10);
  handleTask(1);
}
```

## Best practices

- Keep the priority function fast and deterministic.
- Set a `capacity` to prevent memory exhaustion under overload.
- Consider using stable sorting so equal-priority tasks preserve FIFO order.

## Common pitfalls

- **Priority inversion**: If a high-priority task is slow, lower-priority tasks can starve.
- **Full queue**: When `capacity` is set and the queue is full, new calls throw `StateError`.
