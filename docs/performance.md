# Performance

Performance decorators reduce redundant work, bound resource usage, and optimize execution. Use them to cache results, batch calls, limit rates, and compress payloads.

---

## lazy

### What it is

Defers the first call until it is actually invoked. Subsequent calls execute normally without caching.

### When to use it

- Optional initialization
- Resources that may never be needed

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> lazy()
```

### Examples

**Minimal**

```dart
final init = Func<String>(() async {
  print('initializing');
  return 'ready';
}).lazy();

void main() async {
  // nothing happens yet
  print(await init()); // initializing, ready
  print(await init()); // ready
}
```

**Real world**

```dart
final loadHeavyModel = Func<Model>(() async {
  return await mlLoader.load('heavy-model.bin') as Model;
}).lazy();

void main() async {
  await loadHeavyModel();
}
```

### Best practices

- Combine with `once` if the result should be cached forever.
- Combine with `memoize` if results should be cached per argument.

### Common pitfalls

- `lazy` does not cache the result; it only delays the first execution.

---

## warmUp

### What it is

Pre-executes a function and optionally refreshes the cached result on a timer.

### When to use it

- Keeping a fresh cache ready before the first user request
- Background refresh of expensive data

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> warmUp({
  WarmUpTrigger trigger = WarmUpTrigger.onInit, // arity 0 default
  Duration? keepFresh,
})
```

For `Func1`/`Func2`:

```dart
// api-reference
Func1<T, R> warmUp({
  WarmUpTrigger trigger = WarmUpTrigger.manual, // arity 1/2 default
  Duration? keepFresh,
})
```

`WarmUpTrigger`:

- `onInit` — warm up when the decorator is created.
- `onFirstCall` — warm up on the first call.
- `manual` — warm up only when requested.

Methods:

- `triggerWarmUp()` — arity 0 only.
- `warmUpWith(T arg)` / `warmUpWith(T1 arg1, T2 arg2)` — arity 1/2.
- `dispose()` — cancels the refresh timer.

### Examples

**Minimal**

```dart
final loadConfig = Func<Config>(() async => Config())
  .warmUp(trigger: WarmUpTrigger.onFirstCall);

void main() async {
  print(await loadConfig());
}
```

**Real world**

```dart
final getDashboard = Func1<String, Dashboard>((userId) async {
  return await dashboardService.fetch(userId) as Dashboard;
}).warmUp(
  trigger: WarmUpTrigger.manual,
  keepFresh: Duration(minutes: 5),
) as WarmUpExtension1<String, Dashboard>;

void main() async {
  await getDashboard.warmUpWith('user-123');
}
```

### Best practices

- Always call `dispose()` when the warm-up decorator is no longer needed.
- Use `keepFresh` only for data that is safe to refresh in the background.

### Common pitfalls

- Arity 0 defaults to `onInit`; arity 1/2 default to `manual`.
- Background refresh errors are silently ignored.

---

## batch

### What it is

Accumulates calls and executes them together in a single batch.

### When to use it

- Batching database writes
- Bulk API calls
- Coalescing small operations

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ❌ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func1<T, R> batch({
  required Future<R> Function(List<T> items) executor,
  int maxSize = 100,
  Duration? maxWait,
})
```

- `executor` — processes the accumulated list and returns a single result distributed to all pending calls.
- `maxSize` — flush when the batch reaches this size.
- `maxWait` — flush after this duration even if `maxSize` is not reached.

Methods:

- `flush()` — execute the current batch immediately.
- `cancel()` — complete pending calls with `StateError`.

### Examples

**Minimal**

```dart
final write = Func1<int, String>((n) async => '$n').batch(
  executor: Func1<List<int>, void>((items) async {
    print('batched: ${items.join(', ')}');
  }),
  maxSize: 3,
  maxWait: Duration(milliseconds: 50),
);

void main() async {
  print(await write(1));
  print(await write(2));
  print(await write(3));
}
```

**Real world**

```dart
final saveEvents = Func1<Event, void>((event) async {
  await eventStore.append(event);
}).batch(
  executor: Func1<List<Event>, void>((events) async {
    await eventStore.appendAll(events);
  }),
  maxSize: 50,
  maxWait: Duration(milliseconds: 100),
);

void main() async {
  await saveEvents(Event());
}
```

### Best practices

- Set `maxWait` to bound latency.
- Make the executor idempotent in case of partial failures.

### Common pitfalls

- `batch` is only available on `Func1` and `Func2`.
- All pending calls receive the same result from the executor.

---

## cacheAside

### What it is

Cache-aside pattern with TTL and refresh strategies. Reads from a cache first; on miss, populates the cache and returns the result.

### When to use it

- Read-through caching
- Reducing database or API load

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ❌ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func1<T, R> cacheAside({
  required Cache<T, R> cache,
  required Future<R> Function(T arg) loader,
  Duration? ttl,
  RefreshStrategy refreshStrategy = RefreshStrategy.none,
})
```

`RefreshStrategy`:

- `none`
- `backgroundRefresh`
- `refreshOnAccess`

Built-in `InMemoryCache<K, V>`.

Methods:

- `invalidate(T arg)` / `invalidate(T1 arg1, T2 arg2)`
- `clearCache()`

### Examples

**Minimal**

```dart
final get = Func1<String, String>((key) async => 'loaded:$key')
  .cacheAside(
    ttl: Duration(minutes: 1),
  );

void main() async {
  print(await get('a')); // loaded:a
  print(await get('a')); // loaded:a (from cache)
}
```

**Real world**

```dart
final getProduct = Func1<String, Product>((id) async {
  return await catalogApi.product(id) as Product;
}).cacheAside(
  ttl: Duration(minutes: 5),
  refreshStrategy: RefreshStrategy.backgroundRefresh,
);

void main() async {
  await getProduct('123');
}
```

### Best practices

- Set a TTL to avoid serving stale data forever.
- Use `backgroundRefresh` for frequently accessed, non-critical data.

### Common pitfalls

- `cacheAside` is only available on `Func1` and `Func2`.
- Cache keys must have stable `==` and `hashCode`.

---

## priorityQueue

### What it is

Priority-ordered execution with optional max queue size, max concurrency, and starvation prevention.

### When to use it

- Task queues where some items are more important
- Preventing low-priority tasks from starving

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ❌ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func1<T, R> priorityQueue({
  required num Function(T item) priorityFn,
  int maxQueueSize = 100,
  int maxConcurrent = 1,
  Duration starvationPrevention = const Duration(seconds: 5),
  void Function(T item)? onItemDropped,
  void Function(T item)? onStarvationPrevention,
  QueueFullPolicy onQueueFull = QueueFullPolicy.error,
})
```

`QueueFullPolicy`:

- `dropLowestPriority`
- `dropNew`
- `error`
- `waitForSpace`

Properties:

- `queueLength`
- `activeCount`

### Examples

**Minimal**

```dart
final process = Func1<int, int>((n) async => n)
  .priorityQueue(priorityFn: (n) => n);

void main() async {
  print(await process(1));
}
```

**Real world**

```dart
final runJob = Func1<Job, Result>((job) async {
  return await workerCount.execute(job) as Result;
}).priorityQueue(
  priorityFn: (job) => (job as dynamic).priority as num,
  maxQueueSize: 500,
  maxConcurrent: 4,
  onQueueFull: QueueFullPolicy.dropLowestPriority,
  onItemDropped: (job) => logger.warn('Dropped job ${(job as dynamic).id}'),
);

void main() async {
  await runJob(Job());
}
```

### Best practices

- Set `maxConcurrent` > 1 for I/O-bound work.
- Monitor `activeCount` and `queueLength` for overload.

### Common pitfalls

- `priorityQueue` is only available on `Func1` and `Func2`.
- `dropLowestPriority` evicts the least important queued item, not the running one.

---

## rateLimit

### What it is

Limits how many calls can be made within a time window using token bucket, leaky bucket, fixed window, or sliding window algorithms.

### When to use it

- API client rate limiting
- Protecting downstream services
- Fair resource sharing

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> rateLimit({
  required int maxCalls,
  required Duration window,
  RateLimitStrategy strategy = RateLimitStrategy.tokenBucket,
})
```

`RateLimitStrategy`:

- `tokenBucket`
- `leakyBucket`
- `fixedWindow`
- `slidingWindow`

Methods:

- `reset()`
- `dispose()` — cancels the leaky-bucket timer.

### Examples

**Minimal**

```dart
final call = Func<String>(() async => 'ok')
  .rateLimit(maxCalls: 2, window: Duration(seconds: 1));

void main() async {
  print(await call());
  print(await call());
  try {
    await call();
  } on StateError catch (e) {
    print(e);
  }
}
```

**Real world**

```dart
final apiRequest = Func1<Request, Response>((request) async {
  return await httpClient.send(request) as Response;
}).rateLimit(
  maxCalls: 100,
  window: Duration(minutes: 1),
  strategy: RateLimitStrategy.slidingWindow,
);

void main() async {
  await apiRequest(Request());
}
```

### Best practices

- Choose `slidingWindow` for accuracy, `tokenBucket` for burst tolerance.
- Call `dispose()` when the rate limiter is no longer needed.

### Common pitfalls

- Exceeding the limit throws `StateError`.
- `leakyBucket` uses a periodic timer; remember to `dispose()`.

---

## memoize

### What it is

Caches results by argument with TTL, max size, and eviction policy (LRU, LFU, FIFO).

### When to use it

- Expensive pure functions
- Repeated lookups with the same inputs

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> memoize({
  Duration? ttl,
  int maxSize = 100,
  EvictionPolicy evictionPolicy = EvictionPolicy.lru,
})
```

`EvictionPolicy`:

- `lru` — least recently used
- `lfu` — least frequently used
- `fifo` — first in, first out

Methods:

- `clear()` — clear all cached results.
- `clearArg(arg)` / `clearArgs(arg1, arg2)` — remove a specific entry (arity 1/2).

### Examples

**Minimal**

```dart
final compute = Func1<int, int>((n) async {
  print('computing $n');
  return n * n;
}).memoize();

void main() async {
  print(await compute(3)); // computing 3, 9
  print(await compute(3)); // 9
}
```

**Real world**

```dart
final resolveAddress = Func1<String, GeoLocation>((address) async {
  return await geocoder.lookup(address) as GeoLocation;
}).memoize(
  ttl: Duration(hours: 24),
  maxSize: 1000,
  evictionPolicy: EvictionPolicy.lru,
);

void main() async {
  await resolveAddress('Somewhere');
}
```

### Best practices

- Set `ttl` for data that can become stale.
- Use `lru` for general caching; use `lfu` for hot-key workloads.

### Common pitfalls

- Memoization keys use the argument's `==` and `hashCode`.
- Errors are cached too unless cleared.

---

## deduplicate

### What it is

Suppresses duplicate calls within a time window, returning the previous result for repeated arguments.

### When to use it

- Preventing duplicate network requests
- Coalescing identical user actions

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> deduplicate({Duration? window})
```

Methods:

- `reset()` — clear deduplication state.
- `resetArg(arg)` / `resetArgs(arg1, arg2)` — reset a specific entry (arity 1/2).

### Examples

**Minimal**

```dart
var calls = 0;

final f = Func1<int, int>((n) async {
  calls++;
  return n;
}).deduplicate(window: Duration(seconds: 1));

void main() async {
  print(await f(1)); // calls = 1
  print(await f(1)); // calls = 1
}
```

**Real world**

```dart
final createUser = Func1<String, User>((email) async {
  return await authApi.createUser(email) as User;
}).deduplicate(window: Duration(seconds: 2));

void main() async {
  await createUser('user@example.com');
}
```

### Best practices

- Set a `window` that matches the expected duplicate rate.
- Reset after a known state change.

### Common pitfalls

- Without a `window`, deduplication behavior depends on the implementation's default.
- Concurrent duplicate calls share the in-flight result.

---

## share

### What it is

Shares a single in-flight execution among concurrent callers with the same arguments.

### When to use it

- Thundering-herd protection
- Expensive operations started by many callers at once

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> share()
```

### Examples

**Minimal**

```dart
var calls = 0;

final f = Func<String>(() async {
  calls++;
  await Future<void>.delayed(Duration(milliseconds: 50));
  return 'ok';
}).share();

void main() async {
  final results = await Future.wait([f(), f(), f()]);
  print(calls); // 1
  print(results); // [ok, ok, ok]
}
```

**Real world**

```dart
final fetchConfig = Func<Config>(() async {
  return await configService.fetch() as Config;
}).share();

void main() async {
  await fetchConfig();
}
```

### Best practices

- Use `share` for expensive, idempotent reads.
- Combine with `memoize` if the result should be retained after completion.

### Common pitfalls

- Errors are shared too; all concurrent callers receive the same exception.
- Does not cache results after completion unless paired with `memoize`.

---

## compress

### What it is

Compresses or decompresses string and byte data before passing it to the function.

### When to use it

- Reducing payload size for network or storage
- Working with `Uint8List` or base64 strings

### Async / sync support

| `Func<R>` | `Func1<String, R>` | `Func1<Uint8List, R>` | `FuncSync<R>` |
|-----------|--------------------|------------------------|---------------|
| ✅ decompress | ✅ compress | ✅ compressBytes | ❌ |

### API reference

```dart
// api-reference
// Compress a String input
Func1<String, R> compress({
  CompressionAlgorithm algorithm = CompressionAlgorithm.gzip,
  CompressionLevel level = CompressionLevel.balanced,
  int threshold = 1024,
})

// Compress a Uint8List input
Func1<Uint8List, R> compressBytes({
  CompressionAlgorithm algorithm = CompressionAlgorithm.gzip,
  CompressionLevel level = CompressionLevel.balanced,
  int threshold = 1024,
})

// Decompress to String
Func<String> decompress({CompressionAlgorithm algorithm = CompressionAlgorithm.gzip})

// Decompress to Uint8List
Func<Uint8List> decompressBytes({CompressionAlgorithm algorithm = CompressionAlgorithm.gzip})
```

`CompressionAlgorithm`:

- `gzip`
- `zlib`

`CompressionLevel`:

- `none`
- `fast`
- `balanced`
- `best`

### Examples

**Minimal**

```dart
final upload = Func1<String, void>((compressed) async {
  await storage.upload(compressed);
}).compress(
  algorithm: CompressionAlgorithm.gzip,
  level: CompressionLevel.balanced,
);

void main() async {
  await upload('large payload');
}
```

**Real world**

```dart
final sendTelemetry = Func1<Uint8List, void>((payload) async {
  await telemetryClient.send(payload);
}).compressBytes(
  threshold: 512,
  level: CompressionLevel.fast,
);

void main() async {
  await sendTelemetry(Uint8List(0));
}
```

### Best practices

- Set `threshold` so small payloads are not compressed unnecessarily.
- Match the algorithm between compression and decompression.

### Common pitfalls

- `compress` is only for `Func1<String, R>`; `compressBytes` is for `Func1<Uint8List, R>`.
- Decompressing corrupt data throws a format exception.

---

## once

### What it is

Executes the function once and permanently caches the result (or error). Optional `resetOn` predicate allows retry for matching errors.

### When to use it

- One-time initialization
- Singleton creation
- Expensive setup that must not repeat

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> once({bool Function(Object error)? resetOn})
```

Methods:

- `reset()` — reset arity-0 state.
- `reset([T arg])` / `reset([T1 arg1, T2 arg2])` — reset a specific entry.

### Examples

**Minimal**

```dart
var calls = 0;

final init = Func<String>(() async {
  calls++;
  return 'initialized';
}).once();

void main() async {
  print(await init()); // initialized
  print(await init()); // initialized, calls still 1
}
```

**Real world**

```dart
final connectDatabase = Func<Database>(() async {
  return Database();
}).once();

void main() async {
  await connectDatabase();
}
```

### Best practices

- Use `resetOn` only for recoverable initialization errors.
- Call `reset()` after a known invalidation event.

### Common pitfalls

- If the first call fails, the error is cached forever unless `resetOn` matches.
- `once` is not appropriate for functions whose inputs change frequently.