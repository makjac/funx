# Deduplicate

## What it is

Deduplicate ensures that only one execution is in flight for a given key at a time. If the same key is requested while a previous call is still pending, the new caller receives the same future.

## When to use it

- Preventing thundering herd on cache misses.
- Coalescing identical network requests.
- Avoiding duplicate expensive computations started in parallel.

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
Func<R> deduplicate();

// On Func1<T, R>
Func1<T, R> deduplicate();

// On Func2<T1, T2, R>
Func2<T1, T2, R> deduplicate();
```

No parameters.

## Examples

### Basic example

```dart
var calls = 0;
final fetch = Func<int>(() async {
  calls++;
  await Future<void>.delayed(Duration(milliseconds: 50));
  return 42;
}).deduplicate(window: Duration(seconds: 1));

final a = fetch();
final b = fetch();
print(await a); // 42
print(await b); // 42
// calls == 1
print(calls);
```

### Real-world example

```dart
final getUser = Func1<String, User>((id) async {
  return await api.user(id) as User;
}).deduplicate(window: Duration(seconds: 2));

void main() async {
  await getUser('123');
}
```

## Best practices

- Use `deduplicate` for idempotent reads.
- Combine with `memoize` if you want to remember the result after completion, not just coalesce in-flight calls.
- Be careful with functions whose result depends on time or side effects.

## Common pitfalls

- **Side effects run once**: If the function has side effects, deduplication means they happen only once even if called many times.
- **No result caching after completion**: After the future completes, a new call starts a new execution.
