# Share

## What it is

Share ensures that a single underlying execution is shared among all concurrent callers, even with different arguments. It is similar to deduplicate but typically shares the result of a no-argument or global operation.

## When to use it

- One-time initialization that multiple callers await.
- Singleton setup that must not run twice.
- Shared resource warm-up.

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
Func<R> share();

// On Func1<T, R>
Func1<T, R> share();

// On Func2<T1, T2, R>
Func2<T1, T2, R> share();
```

No parameters.

## Examples

### Basic example

```dart
var calls = 0;
final init = Func<int>(() async {
  calls++;
  await Future<void>.delayed(Duration(milliseconds: 50));
  return 42;
}).share();

final a = init();
final b = init();
print(await a); // 42
print(await b); // 42
// calls == 1
print(calls);
```

### Real-world example

```dart
final initDatabase = Func<Database>(() async {
  return Database();
}).share();

void main() async {
  await initDatabase();
  // Both repositories can call initDatabase(); only one connection is opened.
}
```

## Best practices

- Use `share` for idempotent, expensive setup.
- Do not use `share` for operations that should run per caller.
- Combine with `once` if the operation should run at most once for the lifetime of the wrapper.

## Common pitfalls

- **Retried failures are not shared**: If the shared future fails, subsequent callers may trigger a new attempt depending on implementation.
- **Arguments ignored**: For `Func1`/`Func2`, shared execution means later callers' arguments may be ignored.
