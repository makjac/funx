# Warm Up

## What it is

Warm up eagerly executes the wrapped function once, so that subsequent callers receive a pre-computed result.

## When to use it

- Preloading configuration at app startup.
- Warming caches before traffic arrives.
- Preparing heavy objects during idle time.

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
Func<R> warmUp();

// On Func1<T, R>
Func1<T, R> warmUp();

// On Func2<T1, T2, R>
Func2<T1, T2, R> warmUp();
```

No parameters.

## Examples

### Basic example

```dart
var calls = 0;
final preload = Func<int>(() async {
  calls++;
  return 42;
}).warmUp();

await Future<void>.delayed(Duration(milliseconds: 50));
print(await preload()); // 42
// calls == 1 (eager execution happened before await)
print(calls);
```

### Real-world example

```dart
final loadConfig = Func<Config>(() async {
  return await remoteConfig.fetch() as Config;
}).warmUp();

void main() async {
  await loadConfig();
  // The request starts immediately after construction.
}
```

## Best practices

- Use warm up at a known safe moment, such as app startup.
- Combine with `once` to avoid repeated warm-up.
- Handle failures; an eager failure may still be acceptable if callers can retry.

## Common pitfalls

- **Resource waste**: Warming unused data consumes memory and network.
- **No cancellation**: Once warm up starts, it runs to completion or failure.
