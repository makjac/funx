# Cache Aside

## What it is

Cache aside lets you provide your own cache implementation. The wrapper checks the cache first, calls the function on a miss, and stores the result for future calls.

## When to use it

- Integrating with existing cache libraries (e.g., `stash`, custom caches).
- Implementing TTL, LRU, or persistence.
- Sharing a cache across multiple wrapped functions.

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
  required Cache<T, R> cache,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> cacheAside({
  required Cache<(T1, T2), R> cache,
});

abstract class Cache<K, V> {
  FutureOr<V?> get(K key);
  FutureOr<void> set(K key, V value);
}
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `cache` | `Cache<K, R>` | Custom cache implementation. |

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

- Implement eviction/TTL inside your `Cache` class.
- Use immutable keys; tuples for `Func2` must be equality-comparable.
- Handle cache failures gracefully; the wrapper falls back to the function on a miss.

## Common pitfalls

- **Cache key collisions**: Make sure the key type distinguishes all arguments you care about.
- **Mutable cached objects**: If you mutate a cached object, you mutate the cache contents.
