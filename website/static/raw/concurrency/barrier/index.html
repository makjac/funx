# Barrier

## What it is

A barrier blocks all callers until a predetermined number of participants have arrived. Once the expected count is reached, all waiting callers proceed at once.

## When to use it

- Synchronising multiple parallel workers before a shared phase.
- Coordinated startup of services or isolates.
- Junit-style test fixtures where all async setups must complete before assertions.

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
Func<R> barrier({required int count, Barrier? barrier});

// On Func1<T, R>
Func1<T, R> barrier({required int count, Barrier? barrier});

// On Func2<T1, T2, R>
Func2<T1, T2, R> barrier({required int count, Barrier? barrier});

class Barrier {
  Barrier(int count);
  Future<void> arrive();
  Future<void> arriveAndWait();
  void reset();
}
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `count` | `int` | required | Number of participants required to open the barrier. |
| `barrier` | `Barrier?` | `Barrier(count)` | Optional shared barrier instance. |

## Examples

### Basic example

```dart
final b = Barrier(parties: 3);
var results = <int>[];

final task = Func1<int, int>((id) async {
  results.add(id);
  return id;
}).barrier(b);

await Future.wait([task(1), task(2), task(3)]);
// results.length == 3 (all passed the barrier together)
```

### Real-world example

```dart
const workerCount = 3;
final readyBarrier = Barrier(parties: workerCount);

final worker = Func1<int, void>((id) async {
  await Future<void>.delayed(Duration(milliseconds: 10));
  // All workers start processing at the same moment.
}).barrier(readyBarrier);

await Future.wait([for (var i = 0; i < workerCount; i++) worker(i)]);
```

## Best practices

- Reuse the same `Barrier` instance across all participants.
- Always await `arriveAndWait()`; failing to do so will not block the caller.
- Reset the barrier only when all participants have passed and you want to reuse it.

## Common pitfalls

- **Wrong count**: If `count` is larger than the number of callers, the barrier never opens.
- **Missing participants**: If a caller throws before arriving, remaining callers hang forever unless you add a timeout or cancellation.
