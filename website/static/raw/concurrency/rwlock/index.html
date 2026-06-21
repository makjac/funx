# RWLock

## What it is

`RWLock` allows multiple concurrent readers or a single writer. Read operations do not block each other, but a writer blocks all readers and other writers.

## When to use it

- Caches or lookup tables that are read often and written rarely.
- Shared configuration that multiple isolates or async tasks read.
- Any read-heavy workload where reader concurrency matters.

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
Func<R> readLock([RWLock? lock]);
Func<R> writeLock([RWLock? lock]);

// On Func1<T, R>
Func1<T, R> readLock([RWLock? lock]);
Func1<T, R> writeLock([RWLock? lock]);

// On Func2<T1, T2, R>
Func2<T1, T2, R> readLock([RWLock? lock]);
Func2<T1, T2, R> writeLock([RWLock? lock]);

class RWLock {
  void acquireRead();
  void releaseRead();
  Future<void> acquireWrite();
  void releaseWrite();
}
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `lock` | `RWLock?` | `RWLock()` | Optional shared `RWLock` instance. |

## Examples

### Basic example

```dart
var value = 0;
final rwLock = RWLock();

final read = Func<int>(() async => value).readLock(rwLock);
final write = Func1<int, void>((v) async {
  value = v;
}).writeLock(rwLock);

await write(42);
print(await read()); // 42
```

### Real-world example

```dart
final config = <String, String>{};
final rwLock = RWLock();

final getConfig = Func1<String, String?>(
  (key) async => config[key],
).readLock(rwLock);

final setConfig = Func2<String, String, void>(
  (key, value) async {
    config[key] = value;
  },
).writeLock(rwLock);

await setConfig('theme', 'dark');
print(await getConfig('theme'));

// Multiple readers can run concurrently; writes are exclusive.
```

## Best practices

- Use `readLock` for pure read operations.
- Use `writeLock` for any operation that mutates shared state.
- Share the same `RWLock` instance between readers and writers.

## Common pitfalls

- **Writer starvation**: If readers keep arriving continuously, a writer may wait indefinitely.
- **Mixing lock types**: Using a plain `lock()` on writers while readers use `readLock()` will not coordinate; use the same `RWLock`.
