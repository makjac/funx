# Concurrency

Concurrency decorators coordinate simultaneous executions. Use them to protect shared state, limit parallelism, synchronize multi-step workflows, and isolate failures.

---

## lock

### What it is

A mutual-exclusion (mutex) decorator. Ensures only one execution passes through at a time; other callers wait until the lock is released.

### When to use it

- Updating shared mutable state
- Critical sections that must not overlap
- Serialized access to a resource

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> lock({
  Duration? timeout,
  void Function()? onBlocked,
  bool throwOnTimeout = true,
})
```

- `timeout` — maximum wait for the lock.
- `onBlocked` — called when the caller must wait.
- `throwOnTimeout` — if `true`, throws `TimeoutException`; if `false`, proceeds anyway.

Standalone `Lock` class:

```dart
// api-reference
final lock = Lock();
await lock.synchronized(() async { ... });
lock.release();
```

### Examples

**Minimal**

```dart
var counter = 0;

final increment = Func<int>(() async {
  final next = counter + 1;
  await Future<void>.delayed(Duration(milliseconds: 10));
  counter = next;
  return counter;
}).lock();

void main() async {
  await Future.wait([increment(), increment(), increment()]);
  print(counter); // 3
}
```

**Real world**

```dart
final saveOrder = Func1<Order, void>((order) async {
  await database.save(order);
}).lock(
  timeout: Duration(seconds: 5),
  onBlocked: () => logger.warn('Waiting for order lock'),
);

await saveOrder(Order());
```

### Best practices

- Always use the decorator form; it releases the lock in a `finally` block.
- Set a `timeout` to avoid silent deadlocks.

### Common pitfalls

- Forgetting to release a standalone `Lock` causes a deadlock.
- `throwOnTimeout: false` lets multiple executions run concurrently, defeating the purpose.

---

## readLock / writeLock

### What it is

A read-write lock decorator. Multiple readers can execute concurrently, but writers get exclusive access.

### When to use it

- Read-heavy shared state with occasional writes
- Caches, configuration stores, or in-memory indexes

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> readLock(RWLock rwLock, {Duration? timeout})
Func<R> writeLock(RWLock rwLock, {Duration? timeout})
```

Standalone `RWLock` class:

```dart
// api-reference
final rwLock = RWLock(writerPriority: false);
await rwLock.readLock(() async { ... });
await rwLock.writeLock(() async { ... });
```

- `writerPriority` — when `true`, waiting writers block new readers.

### Examples

**Minimal**

```dart
final rwLock = RWLock();
var cacheMap = <String, int>{};

final read = Func<int?>(() async => cacheMap['x']).readLock(rwLock);
final write = Func1<String, void>((key) async {
  cacheMap[key] = 42;
}).writeLock(rwLock);

void main() async {
  await write('x');
  print(await read()); // 42
}
```

**Real world**

```dart
final rwLock = RWLock(writerPriority: true);

final getConfig = Func<Config>(() async => configCache as Config).readLock(rwLock);
final setConfig = Func1<Config, void>((config) async {
  configCache = config;
}).writeLock(rwLock, timeout: Duration(seconds: 5));

await setConfig(Config());
print(await getConfig());
```

### Best practices

- Use `writerPriority: true` when writes must not starve.
- Hold read locks for as short a time as possible.

### Common pitfalls

- A writer waiting inside a read lock can deadlock if the read holder tries to upgrade to a write lock.
- `TimeoutException` is thrown if the lock cannot be acquired in time.

---

## semaphore

### What it is

A counting semaphore that limits the number of concurrent executions.

### When to use it

- Connection pools
- Bounded parallelism
- Rate limiting by concurrency count

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> semaphore({
  required int maxConcurrent,
  QueueMode queueMode = QueueMode.fifo,
  void Function(int position)? onWaiting,
  Duration? timeout,
})
```

Standalone `Semaphore` class:

```dart
// api-reference
final semaphore = Semaphore(maxConcurrent: 3);
await semaphore.acquire();
try { ... } finally { semaphore.release(); }
```

### Examples

**Minimal**

```dart
final download = Func<String>(() async {
  await Future<void>.delayed(Duration(milliseconds: 100));
  return 'file';
}).semaphore(maxConcurrent: 2);

void main() async {
  final results = await Future.wait([
    download(), download(), download(), download(),
  ]);
  print(results.length); // 4
}
```

**Real world**

```dart
final processImage = Func1<String, Uint8List>((url) async {
  return await imageService.download(url) as Uint8List;
}).semaphore(
  maxConcurrent: 4,
  queueMode: QueueMode.fifo,
  onWaiting: (pos) => logger.info('Queued at position $pos'),
);

await processImage('image.png');
```

### Best practices

- Size `maxConcurrent` to the capacity of the downstream resource.
- Use `timeout` to fail fast when the pool is saturated.

### Common pitfalls

- `Semaphore` does not cancel the underlying work; it only delays starting it.
- If `maxQueueSize` is set on the standalone class, `acquire` throws `StateError` when full.

---

## bulkhead

### What it is

Isolates executions into independent resource pools so that saturation or failure in one pool does not affect others.

### When to use it

- Preventing cascading failures across tenants or features
- Isolating slow or risky operations

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> bulkhead({
  required int poolSize,
  required int queueSize,
  Duration? timeout,
  ErrorCallback? onIsolationFailure,
})
```

Standalone `Bulkhead` class:

```dart
// api-reference
final bulkhead = Bulkhead(poolSize: 4, queueSize: 100);
final result = await bulkhead.execute(() async { ... });
```

### Examples

**Minimal**

```dart
final call = Func<String>(() async {
  await Future<void>.delayed(Duration(milliseconds: 50));
  return 'ok';
}).bulkhead(poolSize: 2, queueSize: 10);

void main() async {
  print(await call());
}
```

**Real world**

```dart
final fetchTenantData = Func1<String, TenantData>((tenantId) async {
  return await tenantApi.fetch(tenantId) as TenantData;
}).bulkhead(
  poolSize: 4,
  queueSize: 100,
  timeout: Duration(seconds: 30),
  onIsolationFailure: (e, s) => logger.error('Tenant fetch failed', e, s),
);

await fetchTenantData('tenant-1');
```

### Best practices

- Use separate `Bulkhead` instances for unrelated workloads.
- Tune `queueSize` so that transient spikes are absorbed without unbounded growth.

### Common pitfalls

- `poolSize` determines the number of independent pools, each with one concurrent slot.
- `TimeoutException` is thrown when a pool cannot be acquired in time.

---

## barrier

### What it is

A synchronization barrier that blocks execution until a configured number of parties have arrived. Optional action runs before releasing all waiters.

### When to use it

- Multi-stage parallel algorithms
- Coordinated startup
- Fan-in synchronization points

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> barrier(Barrier barrier)
```

Standalone `Barrier` class:

```dart
// api-reference
final barrier = Barrier(
  parties: 3,
  cyclic: true,
  barrierAction: () => print('All arrived'),
  timeout: Duration(seconds: 10),
  onTimeout: () => print('Timeout'),
);
await barrier.await_();
```

### Examples

**Minimal**

```dart
final b = Barrier(parties: 3, cyclic: true);

final worker = Func<int>(() async => 1).barrier(b);

void main() async {
  await Future.wait([worker(), worker(), worker()]);
  print('All synchronized');
}
```

**Real world**

```dart
const partitionCount = 3;
final phaseGate = Barrier(
  parties: partitionCount,
  cyclic: true,
  barrierAction: () => logger.info('Phase complete'),
);

final processPartition = Func1<int, void>((partition) async {
  await Future<void>.delayed(Duration(milliseconds: 10));
}).barrier(phaseGate);

await Future.wait([for (var i = 0; i < partitionCount; i++) processPartition(i)]);
```

### Best practices

- Use `cyclic: true` when the barrier is reused across phases.
- Always handle `StateError('Barrier is broken')` after a timeout.

### Common pitfalls

- A broken barrier rejects all further `await_` calls until `reset()` is called.
- If `barrierAction` throws, the barrier becomes broken.

---

## countdownLatch

### What it is

Blocks waiters until a counter decremented by `countDown()` reaches zero. Unlike a barrier, the counter is single-use.

### When to use it

- Waiting for N parallel tasks to finish
- Startup sequences
- Fan-out / fan-in patterns

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> countdownLatch(CountdownLatch latch)
```

Standalone `CountdownLatch` class:

```dart
// api-reference
final latch = CountdownLatch(count: 3, onComplete: () { ... });
latch.countDown();
final completed = await latch.await_(timeout: Duration(seconds: 10));
```

### Examples

**Minimal**

```dart
final latch = CountdownLatch(count: 3);

final task = Func<String>(() async => 'done').countdownLatch(latch);

void main() async {
  Future.wait([task(), task(), task()]);
  await latch.await_();
  print('All done');
}
```

**Real world**

```dart
final services = <Service>[Service(), Service(), Service()];
final readinessLatch = CountdownLatch(count: services.length);

final initService = Func1<Service, void>((service) async {
  await Future<void>.delayed(Duration(milliseconds: 10));
}).countdownLatch(readinessLatch);

await Future.wait(services.map(initService));
await readinessLatch.await_();
```

### Best practices

- Use `await_` with a timeout to avoid hanging forever.
- Call `countDown` exactly once per expected completion.

### Common pitfalls

- Calling `countDown` after the counter reaches zero throws `StateError`.
- The latch cannot be reset; create a new instance for reuse.

---

## monitor

### What it is

A mutex with condition variables. Wraps execution inside exclusive access and supports `waitWhile`, `waitUntil`, `notify`, and `notifyAll`.

### When to use it

- Producer-consumer queues
- Conditional coordination
- Complex state machines that need to wait for conditions

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> monitor(Monitor monitor)
```

Standalone `Monitor` class:

```dart
// api-reference
final monitor = Monitor();
await monitor.synchronized(() async {
  await monitor.waitUntil(() => queue.isNotEmpty);
  return queue.removeFirst();
});
monitor.notifyAll();
```

### Examples

**Minimal**

```dart
final monitor = Monitor();
var ready = false;

final waitForReady = Func<String>(() async {
  return monitor.synchronized(() async {
    await monitor.waitUntil(() => ready);
    return 'go';
  });
});

void main() async {
  final f = waitForReady();
  await monitor.synchronized(() async {
    ready = true;
    monitor.notifyAll();
  });
  print(await f); // go
}
```

**Real world**

```dart
final monitor = Monitor();
final buffer = <Task>[];

final consume = Func<Task?>(() async {
  return monitor.synchronized<Task?>(() async {
    await monitor.waitWhile(() => buffer.isEmpty);
    return buffer.removeAt(0);
  });
});

await consume();
```

### Best practices

- Always call `waitWhile` / `waitUntil` inside `monitor.synchronized`.
- Use `notifyAll` when multiple waiters may need to proceed.

### Common pitfalls

- `waitWhile` / `waitUntil` release the lock while waiting; the predicate must be re-checked on wake-up.
- Timeout returns `false` from `waitWhile` / `waitUntil`; the caller must handle it.

---

## queue

### What it is

Queues incoming calls and executes them sequentially or by priority.

### When to use it

- Serializing requests to a resource
- Task queues with FIFO, LIFO, or priority ordering

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ❌ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func1<T, R> queue({
  QueueMode mode = QueueMode.fifo,
  PriorityFunction<T>? priorityFn,
  void Function(int queueSize)? onQueueChange,
})
```

Standalone `FunctionQueue` class:

```dart
// api-reference
final queue = FunctionQueue<Task, Result>(mode: QueueMode.priority);
final result = await queue.enqueue(task, (t) async => process(t));
```

Properties exposed by the decorator:

- `queueLength`
- `runningTasks`

### Examples

**Minimal**

```dart
final process = Func1<int, int>((n) async {
  await Future<void>.delayed(Duration(milliseconds: 10));
  return n * 2;
}).queue(concurrency: 1, mode: QueueMode.fifo);

void main() async {
  print(await process(1)); // 2
  print(await process(2)); // 4
}
```

**Real world**

```dart
final handleRequest = Func1<Request, Response>((request) async {
  return await http.handle(request) as Response;
}).queue(
  concurrency: 4,
  mode: QueueMode.priority,
  priorityFn: (r) => (r as dynamic).priority as int,
  onQueueChange: (size) => metrics.gauge('request_queue', size),
);

await handleRequest(Request());
```

### Best practices

- Choose `QueueMode.priority` only when you can define a meaningful priority.
- Monitor `queueLength` to detect backlog.

### Common pitfalls

- `queue` is only available on `Func1` and `Func2`.
- LIFO mode can starve old items under high load.