# Defer

## What it is

Defer schedules the wrapped function to run in the next microtask. The returned future begins execution as soon as possible without blocking the current synchronous block.

## When to use it

- Moving work out of a build or layout phase in Flutter.
- Batching multiple synchronous operations so they all run after the current event loop iteration.
- Creating a "lazy promise" that starts work immediately but allows awaiting later.

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
Func<R> asDeferred();

// On Func1<T, R>
Func1<T, R> asDeferred();

// On Func2<T1, T2, R>
Func2<T1, T2, R> asDeferred();
```

No parameters.

## Examples

### Basic example

```dart
final deferred = Func<String>(() async {
  print('executed');
  return 'hello';
}).asDeferred();

print('before');
final result = await deferred();
print(result);

// Output:
// before
// executed
// hello
```

### Real-world example

```dart
final loadConfig = Func<Config>(() async => configRepository.load() as Config)
  .asDeferred();

// During app startup, create the promise without awaiting.
// Later, when needed:
final config = await loadConfig();
print(config);
```

## Best practices

- Use `defer` when you want to start work as soon as the current microtask completes.
- Combine with `await` when you need the result before continuing.
- Do not rely on defer for precise timing; it only guarantees the next microtask, not a specific delay.

## Common pitfalls

- **Unawaited fire-and-forget**: If you never await the returned future, exceptions become unhandled asynchronous errors.
- **Confusing with `delay`**: `delay` waits a specific duration; `defer` only yields to the event loop.
