# Countdown Latch

## What it is

A countdown latch waits until a counter reaches zero. Unlike a barrier, the counter is decremented by calls to the latch, and waiting callers proceed once the count hits zero.

## When to use it

- Waiting for a set of independent initialization tasks to finish.
- Boot sequences where multiple services must be ready before starting the main loop.
- Triggering an action after N events have occurred.

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
Func<R> countdownLatch({required int count, CountdownLatch? latch});

// On Func1<T, R>
Func1<T, R> countdownLatch({required int count, CountdownLatch? latch});

// On Func2<T1, T2, R>
Func2<T1, T2, R> countdownLatch({required int count, CountdownLatch? latch});

class CountdownLatch {
  CountdownLatch(int count);
  void countDown();
  Future<void> awaitLatch();
  int get count;
  bool get isOpen;
}
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `count` | `int` | required | Initial latch count. |
| `latch` | `CountdownLatch?` | `CountdownLatch(count)` | Optional shared latch instance. |

## Examples

### Basic example

```dart
final latch = CountdownLatch(count: 2);
var done = false;

final init = Func<String>(() async {
  done = true;
  return 'ready';
}).countdownLatch(latch);

init();
init();

await latch.await_();
print(done); // true
```

### Real-world example

```dart
final initLatch = CountdownLatch(count: 3);

final loadConfig = Func<Config>(() async => config.load() as Config)
  .countdownLatch(initLatch);
final loadCache = Func<Cache<String, String>>(() async => cache.load() as Cache<String, String>)
  .countdownLatch(initLatch);
final connectDb = Func<Db>(() async => db.connect() as Db)
  .countdownLatch(initLatch);

loadConfig();
loadCache();
connectDb();

// All three finish before the main app proceeds.
await initLatch.await_();
print('App ready');
```

## Best practices

- Call `countDown()` exactly once per expected event.
- Use `awaitLatch()` for the coordinator that must wait for all tasks.
- Share the same latch instance across all participants.

## Common pitfalls

- **Counting down too many times**: If `countDown()` is called more than `count` times, behavior is undefined.
- **Latch never opens**: If a task fails before calling `countDown()`, the latch remains closed. Add error handling or timeouts.
