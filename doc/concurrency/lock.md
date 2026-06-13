# Lock

## What it is

A `Lock` guarantees that only one execution of the wrapped function happens at a time. Concurrent calls queue and run sequentially.

## When to use it

- Protecting a critical section around shared mutable state.
- Preventing duplicate writes to a database or file.
- Serializing access to a non-thread-safe resource.

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
Func<R> lock([Lock? lock]);

// On Func1<T, R>
Func1<T, R> lock([Lock? lock]);

// On Func2<T1, T2, R>
Func2<T1, T2, R> lock([Lock? lock]);

class Lock {
  Future<T> synchronized<T>(FutureOr<T> Function() computation);
}
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `lock` | `Lock?` | `Lock()` | Optional shared lock instance. If omitted, a new lock is created. |

## Examples

### Basic example

```dart
var balance = 0;
final deposit = Func1<int, int>((amount) async {
  final current = balance;
  await Future<void>.delayed(Duration(milliseconds: 10));
  balance = current + amount;
  return balance;
}).lock();

await Future.wait([deposit(10), deposit(20)]);
// balance == 30 (serialised, no lost updates)
```

### Real-world example

```dart
final writeToLog = Func1<String, void>((entry) async {
  await storage.write('$entry\n');
}).lock();

// Many callers can invoke writeToLog safely; writes are serialised.

await writeToLog('entry');
```

## Best practices

- Keep critical sections as short as possible to reduce queuing.
- Reuse the same `Lock` instance across multiple wrapped functions if they access the same resource.
- Avoid calling the wrapped function recursively from within the same lock to prevent self-deadlock.

## Common pitfalls

- **Forgetting the lock parameter**: Without a shared lock, each wrapper has its own lock and they no longer coordinate.
- **Deadlock**: Holding a lock while awaiting another operation that also needs the same lock causes deadlock.
