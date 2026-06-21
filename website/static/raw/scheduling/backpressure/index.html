# Backpressure

## What it is

Backpressure controls what happens when a function receives more requests than it can process. It supports several strategies: `drop`, `dropOldest`, `buffer`, `sample`, `throttle`, and `error`.

## When to use it

- Real-time dashboards that should drop stale sensor readings.
- Click streams where only the latest event matters.
- Message queues that should buffer, drop old messages, or reject overload.

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
BackpressureExtension<T, R> backpressure({
  required BackpressureStrategy strategy,
  int bufferSize = 100,
  double sampleRate = 0.1,
  int maxConcurrent = 10,
  BackpressureCallback? onOverflow,
  BackpressureCallback? onBufferFull,
});

// On Func2<T1, T2, R>
BackpressureExtension2<T1, T2, R> backpressure({
  required BackpressureStrategy strategy,
  int bufferSize = 100,
  double sampleRate = 0.1,
  int maxConcurrent = 10,
  BackpressureCallback? onOverflow,
  BackpressureCallback? onBufferFull,
});

enum BackpressureStrategy {
  drop,
  dropOldest,
  buffer,
  sample,
  throttle,
  error,
}
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `strategy` | `BackpressureStrategy` | required | Strategy used when overloaded. |
| `bufferSize` | `int` | `100` | Maximum number of items to buffer for `buffer` and `dropOldest`. |
| `sampleRate` | `double` | `0.1` | Probability of accepting an item under load for `sample`. |
| `maxConcurrent` | `int` | `10` | Maximum number of executions running at the same time. |
| `onOverflow` | `BackpressureCallback?` | `null` | Called when an item is dropped or rejected. |
| `onBufferFull` | `BackpressureCallback?` | `null` | Called when the buffer is full and cannot accept more items. |

### Strategies

| Strategy | Behavior |
|---|---|
| `drop` | Drops any new request while at `maxConcurrent`. Throws `StateError` on the caller. |
| `dropOldest` | Keeps a queue of up to `bufferSize` pending requests; oldest are dropped when full. |
| `buffer` | Queues requests up to `bufferSize` while under pressure; throws `StateError` when the buffer is full. |
| `sample` | Emits at most one execution per window; extra calls return the latest sampled value. |
| `throttle` | Similar to `sample` but typically aligned to leading edge semantics. |
| `error` | Throws `StateError` immediately when the system is overloaded. |

## Examples

### Drop example

```dart
var callCount = 0;
final worker = Func1<int, int>((_) async {
  await Future<void>.delayed(Duration(milliseconds: 100));
  return ++callCount;
}).backpressure(
  strategy: BackpressureStrategy.drop,
  maxConcurrent: 1,
);

final a = worker(1);
try {
  await worker(2);
} catch (e) {
  print('dropped: $e');
}
print(await a);
// callCount == 1
```

### Buffer example

```dart
var total = 0;
final worker = Func1<List<int>, int>((items) async {
  total += items.length;
  return total;
}).backpressure(
  strategy: BackpressureStrategy.buffer,
  bufferSize: 3,
  maxConcurrent: 1,
);

worker([1]);
worker([2]);
await Future<void>.delayed(Duration(milliseconds: 100));
// total == 2 (or 3 if a third call arrived in time)
```

### Error example

```dart
final worker = Func1<String, String>((_) async => 'done').backpressure(
  strategy: BackpressureStrategy.error,
  maxConcurrent: 1,
);

await worker('a');
try {
  await worker('b');
} on StateError catch (e) {
  print('overloaded: $e');
}
```

## Best practices

- Use `drop` when stale data is useless.
- Use `buffer` when processing batches is cheaper than processing items individually.
- Set `bufferSize` realistically to avoid unbounded memory growth.
- For `drop`, catch `StateError` on concurrent calls.

## Common pitfalls

- **Buffer overflow**: `buffer` throws `StateError` when the buffer is full; set `bufferSize` and handle overload gracefully.
- **Dropped future behavior**: Strategies like `drop` can throw `StateError` on the caller; handle overload gracefully.
