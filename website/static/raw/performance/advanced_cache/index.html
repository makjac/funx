# Advanced Cache

## What it is

The `funx` performance package includes a small family of pluggable cache
backends and helpers that back `memoize()` and `cacheAside()`. You can choose
the eviction policy, add a weight limit, protect against cache stampedes, and
keep a set of keys warm in the background.

## When to use it

- You need more control than the default in-memory LRU cache.
- Cache entries have very different memory costs and you want a weight budget.
- Hot keys are requested concurrently and you want only one loader to run.
- A subset of keys should be refreshed proactively on a timer.

## Components

| Component | Purpose |
|---|---|
| `Cache<K, V>` | Minimal cache interface (`get`, `put`, `remove`, `clear`). |
| `AdvancedCache<K, V>` | Extends `Cache` with `putEntry`, `getEntry`, and `keys`. |
| `CacheEntry<V>` | Value plus metadata: `expiresAt`, `weight`, `accessCount`. |
| `LruCache<K, V>` | Evicts least-recently-used entries. |
| `LfuCache<K, V>` | Evicts least-frequently-used entries. |
| `FifoCache<K, V>` | Evicts oldest inserted entries. |
| `WeightedCache<K, V>` | Wraps another cache and evicts by total weight. |
| `StampedeProtection<K, V>` | Coalesces concurrent loads for the same key. |
| `CacheWarmer<K, V>` | Periodically refreshes a set of keys. |

## API reference

```dart
// api-reference
abstract class Cache<K, V> {
  V? get(K key);
  void put(K key, V value);
  void remove(K key);
  void clear();
}

abstract class AdvancedCache<K, V> implements Cache<K, V> {
  void putEntry(K key, CacheEntry<V> entry);
  CacheEntry<V>? getEntry(K key);
  Iterable<K> get keys;
}

class CacheEntry<V> {
  CacheEntry(
    this.value, {
    this.expiresAt,
    this.weight = 1,
    this.accessCount = 1,
  });

  final V value;
  final DateTime? expiresAt;
  final int weight;
  int accessCount;
  bool get isExpired;
}

class LruCache<K, V> implements AdvancedCache<K, V> {
  LruCache({required int maxSize});
}

class LfuCache<K, V> implements AdvancedCache<K, V> {
  LfuCache({required int maxSize});
}

class FifoCache<K, V> implements AdvancedCache<K, V> {
  FifoCache({required int maxSize});
}

class WeightedCache<K, V> implements AdvancedCache<K, V> {
  WeightedCache(
    AdvancedCache<K, V> inner, {
    required int maxWeight,
    required int Function(V value) weigh,
  });

  int get totalWeight;
}

class StampedeProtection<K, V> {
  Future<V> load(K key, Future<V> Function() loader);
}

class CacheWarmer<K, V> {
  CacheWarmer({
    required AdvancedCache<K, V> cache,
    required Future<V> Function(K key) loader,
    required Duration interval,
    required Iterable<K> keys,
  });

  void start();
  void stop();
  bool get isRunning;
}
```

## Examples

### Choose an eviction policy

```dart
final cache = LfuCache<String, int>(maxSize: 100);
cache.put('a', 1);
print(cache.get('a'));
```

### Weighted cache

```dart
final cache = WeightedCache<String, String>(
  LruCache<String, String>(maxSize: 1000),
  maxWeight: 1024 * 1024, // 1 MB
  weigh: (value) => value.length,
);
cache.put('a', 'hello');
print(cache.totalWeight);
```

### Stampede protection

```dart
final protection = StampedeProtection<String, int>();
final value = await protection.load(
  'key',
  () async => 42,
);
print(value);
```

### Warm a set of keys

```dart
final cache = LruCache<String, Product>(maxSize: 10);
final warmer = CacheWarmer<String, Product>(
  cache: cache,
  loader: (id) async => Product(),
  interval: Duration(minutes: 5),
  keys: ['featured', 'new-arrivals'],
)..start();
print(warmer.isRunning);
warmer.stop();
```

## Best practices

- Pick the eviction policy that matches your access pattern.
- Always provide both `maxWeight` and `weigh` when using `WeightedCache`.
- Keep `CacheWarmer` intervals reasonable to avoid hammering the data source.
- Stop warmers and clear caches when disposing long-lived objects.

## Common pitfalls

- **Weight under-counting**: `WeightedCache` only tracks entries inserted
  through itself; writes made directly to the inner cache are not weighed.
- **Heavy entries**: A single entry heavier than `maxWeight` is silently
  rejected.
- **Timer leaks**: `CacheWarmer` holds a periodic timer; call `stop()` to avoid
  leaks.
