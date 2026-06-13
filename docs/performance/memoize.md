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
Func<R> memoize();

// On Func1<T, R>
Func1<T, R> memoize();

// On Func2<T1, T2, R>
Func2<T1, T2, R> memoize();
```

No parameters.

### Returned wrapper methods

```dart
// api-reference
void clear(); // Clears the cached value.
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

## Common pitfalls

- **Stale data**: Memoize does not expire automatically; stale values can persist for the lifetime of the wrapper.
- **Memory leaks**: Long-lived wrappers cache results indefinitely; clear them when no longer needed.
