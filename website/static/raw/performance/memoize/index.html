# Memoize

## What it is

Memoize caches the result of a function call and returns the cached value on subsequent calls.

## When to use it

- Expensive computations with deterministic inputs.
- Repeated service lookups that rarely change.
- Avoiding redundant network or database requests within a session.

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
Func<R> memoize({
  Duration? ttl,
  int maxSize = 100,
  EvictionPolicy evictionPolicy = EvictionPolicy.lru,
});

// On Func1<T, R>
Func1<T, R> memoize({
  Duration? ttl,
  int maxSize = 100,
  EvictionPolicy evictionPolicy = EvictionPolicy.lru,
  AdvancedCache<T, R>? cache,
  int? maxWeight,
  int Function(R result)? weigh,
  bool stampedeProtection = false,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> memoize({
  Duration? ttl,
  int maxSize = 100,
  EvictionPolicy evictionPolicy = EvictionPolicy.lru,
  AdvancedCache<ArgPair<T1, T2>, R>? cache,
  int? maxWeight,
  int Function(R result)? weigh,
  bool stampedeProtection = false,
});
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `ttl` | `Duration?` | Time-to-live for cached results. `null` means no expiration. |
| `maxSize` | `int` | Maximum entries when using the default cache backend. |
| `evictionPolicy` | `EvictionPolicy` | `lru`, `lfu`, or `fifo`. |
| `cache` | `AdvancedCache?` | Optional custom cache backend. |
| `maxWeight` | `int?` | Total weight budget when using weighted eviction. |
| `weigh` | `int Function(R)?` | Returns the weight of a result. |
| `stampedeProtection` | `bool` | Coalesce concurrent loads for the same key. |

### Returned wrapper methods

```dart
// api-reference
void clear(); // Clears all cached values.
// On Func1 / Func2 only:
void clearArg(T arg);
void clearArgs(T1 arg1, T2 arg2);
```

## Examples

### Basic example

```dart
var calls = 0;
final compute = Func<int>(() async {
  calls++;
  return 42;
}).memoize();

print(await compute()); // 42
print(await compute()); // 42
// calls == 1
print(calls);
```

### Custom backend and stampede protection

```dart
final fetchUser = Func1<String, User>((id) async {
  return User();
}).memoize(
  cache: LruCache<String, User>(maxSize: 100),
  ttl: Duration(minutes: 5),
  stampedeProtection: true,
);

print(await fetchUser('123'));
```

### Weighted eviction

```dart
final fetchPage = Func1<String, String>((url) async {
  return '<html>Hello</html>';
}).memoize(
  cache: LruCache<String, String>(maxSize: 1000),
  maxWeight: 1024 * 1024,
  weigh: (html) => html.length,
);

print((await fetchPage('/')).length);
```

### Real-world example

```dart
final fetchConfig = Func<Config>(() async {
  return await remoteConfig.fetch() as Config;
}).memoize();

void main() async {
  await fetchConfig();
}
```

## Best practices

- Use `memoize` for functions whose result does not change during the cache lifetime.
- Call `clear()` when you know the cached value is stale.
- Combine with `timeout()` if the first call should not hang forever.
- Enable `stampedeProtection` for hot keys that are expensive to load.

## Common pitfalls

- **Stale data**: Without a `ttl`, cached values persist for the lifetime of the wrapper.
- **Memory leaks**: Long-lived wrappers cache results indefinitely; clear them when no longer needed.
- **Weight budget**: `maxWeight` without `weigh` (or vice versa) triggers an assertion.
