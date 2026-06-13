# Semaphore

## What it is

A semaphore limits the number of concurrent executions. Once the limit is reached, additional calls wait until a slot becomes free.

## When to use it

- Limiting concurrent network requests to the same host.
- Controlling CPU or memory usage by bounding parallel work.
- Pool-style resource access.

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
Func<R> semaphore(int maxConcurrent, {Semaphore? semaphore});

// On Func1<T, R>
Func1<T, R> semaphore(int maxConcurrent, {Semaphore? semaphore});

// On Func2<T1, T2, R>
Func2<T1, T2, R> semaphore(int maxConcurrent, {Semaphore? semaphore});

class Semaphore {
  Semaphore(int maxConcurrency);
  Future<void> acquire();
  void release();
}
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `maxConcurrent` | `int` | required | Maximum number of concurrent executions. |
| `semaphore` | `Semaphore?` | `Semaphore(maxConcurrent)` | Optional shared semaphore instance. |

## Examples

### Basic example

```dart
var running = 0;
var maxRunning = 0;

final worker = Func<int>(() async {
  running++;
  if (running > maxRunning) maxRunning = running;
  await Future<void>.delayed(Duration(milliseconds: 50));
  running--;
  return running;
}).semaphore(maxConcurrent: 2);

await Future.wait([for (var i = 0; i < 5; i++) worker()]);
// maxRunning == 2
```

### Real-world example

```dart
final urls = <String>['a.txt', 'b.txt'];
final download = Func1<String, File>((url) async {
  return http.download(url) as File;
}).semaphore(maxConcurrent: 4); // at most 4 downloads at once

await Future.wait<File>(urls.map(download));
```

## Best practices

- Choose `maxConcurrent` based on the bottleneck resource (network, CPU, file handles).
- Use a shared semaphore across multiple functions if they share the same resource pool.
- Do not acquire the same semaphore twice in the same call stack.

## Common pitfalls

- **Semaphore leaks**: If the inner function throws, the semaphore must release. The wrapper handles this internally; do not wrap `acquire()`/`release()` manually.
- **Too small limit**: A limit of `1` is equivalent to a lock; make sure you need concurrency before choosing a higher value.
