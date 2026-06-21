# Batch

## What it is

Batch collects multiple individual requests and invokes the inner function with a list of items. It is available for `Func1` and `Func2`.

## When to use it

- Combining multiple single-row database inserts into one bulk insert.
- Batching analytics events before sending.
- Any workload where a single bulk operation is cheaper than many small ones.

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
Func1<T, R> batch({
  required int maxSize,
  Duration? maxWait,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> batch({
  required int maxSize,
  Duration? maxWait,
});
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `maxSize` | `int` | required | Maximum number of items in one batch. |
| `maxWait` | `Duration?` | `null` | Maximum time to wait for the batch to fill. |

### How it changes the inner function signature

```dart
// api-reference
// Before:
Func1<T, R> inner = Func1<T, R>((T item) async => ...);

// After batch:
// inner is passed as Func1<List<T>, List<R>> to the batch executor.
```

### Returned wrapper methods

```dart
// api-reference
void flush(); // Immediately flushes any pending batch.
```

## Examples

### Basic example

```dart
var total = 0;
final add = Func1<int, int>((n) async => n).batch(
  executor: Func1<List<int>, void>((items) async {
    total += items.length;
  }),
  maxSize: 3,
  maxWait: Duration(milliseconds: 50),
);

await add(1);
await add(2);
await Future<void>.delayed(Duration(milliseconds: 100));
// total == 2 (batch flushed by maxWait)
print(total);
```

### Real-world example

```dart
final insertUsers = Func1<User, User>((user) async => user).batch(
  executor: Func1<List<User>, void>((users) async {
    await db.batchInsert(users);
  }),
  maxSize: 50,
  maxWait: Duration(milliseconds: 100),
);

// Each call to insertUsers(user) is automatically batched.
await insertUsers(User());
```

## Best practices

- Set `maxWait` low enough to keep latency acceptable.
- Make sure the inner function can handle empty batches gracefully.
- Call `flush()` during shutdown to avoid losing pending items.

## Common pitfalls

- **Wrong inner signature**: The wrapped function must accept `List<T>` (or `List<T1>`/`List<T2>` for `Func2`), not a single item.
- **Result ordering**: The returned list of results must correspond to the input order.
