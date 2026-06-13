# Once

## What it is

Once guarantees that the wrapped function executes at most one time. All subsequent calls return the cached result.

## When to use it

- Singleton initialization.
- Feature flags or configuration loaded once per app lifetime.
- One-time analytics setup.

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
Func<R> once();

// On Func1<T, R>
Func1<T, R> once();

// On Func2<T1, T2, R>
Func2<T1, T2, R> once();
```

No parameters.

## Examples

### Basic example

```dart
var calls = 0;
final setup = Func<int>(() async {
  calls++;
  return 42;
}).once();

print(await setup()); // 42
print(await setup()); // 42
// calls == 1
print(calls);
```

### Real-world example

```dart
final initializeAnalytics = Func<void>(() async {
  await analytics.init();
}).once();

void main() async {
  await initializeAnalytics();
}
```

## Best practices

- Use `once` for side effects that should happen exactly one time.
- Pair with `fallback` if initialization failures should be recoverable.
- Keep the once-wrapped function deterministic.

## Common pitfalls

- **Failed once is still once**: If the single execution throws, the wrapper remembers the failure and rethrows on subsequent calls. Combine with `retry` or `fallback` to handle this.
- **Arguments ignored after first call**: For `Func1`/`Func2`, only the first invocation's arguments are used.
