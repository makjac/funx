# Cache Aside

## What it is

Cache aside lets you provide your own cache implementation. The wrapper checks the cache first, calls the function on a miss, and stores the result for future calls. You can also keep a set of keys warm in the background.

## When to use it

- Integrating with existing cache libraries or custom caches.
- Implementing TTL, LRU, LFU, FIFO, or persistence.
- Sharing a cache across multiple wrapped functions.
- Proactively refreshing hot keys on a timer.

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
Func1<T, R> cacheAside({
  AdvancedCache<T, R>? cache,
  Duration? ttl,
  RefreshStrategy refreshStrategy = RefreshStrategy.none,
  void Function()? onCacheMiss,
  void Function()? onCacheHit,
  Iterable<T>? warmKeys,
  Duration? warmInterval,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> cacheAside({
  AdvancedCache<ArgPair<T1, T2>, R>? cache,
  Duration? ttl,
  RefreshStrategy refreshStrategy = RefreshStrategy.none,
  void Function()? onCacheMiss,
  void Function()? onCacheHit,
  Iterable<(T1, T2)>? warmKeys,
  Duration? warmInterval,
});
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `cache` | `AdvancedCache?` | Custom cache backend. Defaults to an in-memory LRU cache. |
| `ttl` | `Duration?` | Time-to-live for cached entries. |
| `refreshStrategy` | `RefreshStrategy` | `none`, `backgroundRefresh`, or `refreshOnAccess`. |
| `onCacheMiss` | `void Function()?` | Callback invoked on a cache miss. |
| `onCacheHit` | `void Function()?` | Callback invoked on a cache hit. |
| `warmKeys` | `Iterable?` | Keys to keep warm in the background. |
| `warmInterval` | `Duration?` | Refresh interval for `warmKeys`. |

### Returned wrapper methods

```dart
// api-reference
void invalidate(T key);
void invalidate(T1 arg1, T2 arg2);
void clearCache();
void dispose(); // Stops the background warmer.
```

## Examples

### Basic example

```dart
var calls = 0;
final square = Func1<int, int>((n) async {
  calls++;
  return n * n;
}).cacheAside(ttl: Duration(minutes: 1));

void main() async {
  print(await square(3)); // 9
  print(await square(3)); // 9
  // calls == 1
  print(calls);
}
```

### Custom backend and warming

```dart
final getProduct = Func1<String, Product>((id) async {
  return Product();
}).cacheAside(
  cache: LfuCache<String, Product>(maxSize: 200),
  ttl: Duration(minutes: 5),
  warmKeys: ['featured'],
  warmInterval: Duration(minutes: 1),
);

print(await getProduct('featured'));
getProduct.dispose();
```

### Real-world example

```dart
final getProduct = Func1<String, Product>((id) async {
  return await catalogApi.get(id) as Product;
}).cacheAside(ttl: Duration(minutes: 5));

void main() async {
  await getProduct('123');
}
```

## Best practices

- Implement eviction/TTL inside your `AdvancedCache` class or use the built-in backends.
- Use immutable keys; `ArgPair` is provided for `Func2` keys.
- Handle cache failures gracefully; the wrapper falls back to the function on a miss.
- Call `dispose()` to stop background warmers when the wrapper is no longer needed.

## Common pitfalls

- **Cache key collisions**: Make sure the key type distinguishes all arguments you care about.
- **Mutable cached objects**: If you mutate a cached object, you mutate the cache contents.
- **Timer leaks**: Forgetting `dispose()` leaves `CacheWarmer` timers running.
