# When

## What it is

`when` is a decorator that conditionally executes the wrapped function or an alternative branch depending on a predicate.

## When to use it

- Feature flags that choose between implementations.
- Conditional execution without `if/else` at every call site.
- Branching logic that you want to compose and reuse.

## API reference

```dart
// api-reference
// On Func<R>
Func<R> when({
  required bool Function() condition,
  Future<R> Function()? otherwise,
});

// On Func1<T, R>
Func1<T, R> when({
  required bool Function(T arg) condition,
  Future<R> Function(T arg)? otherwise,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> when({
  required bool Function(T1 arg1, T2 arg2) condition,
  Future<R> Function(T1 arg1, T2 arg2)? otherwise,
});
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `condition` | `bool Function(...)` | Decides whether to execute the wrapped function. |
| `otherwise` | `Future<R> Function(...)?` | Optional branch executed when the condition is `false`. |

## Examples

### Basic example

```dart
final route = Func1<int, String>((n) async => 'positive').when(
  condition: (n) => n > 0,
  otherwise: (n) async => 'non-positive',
);

print(await route(5)); // positive
print(await route(-1)); // non-positive
```

### Real-world example

```dart
final useCache = false;

final fetchUser = Func1<String, User>((id) async {
  return await cache.get(id) as User;
}).when(
  condition: (_) => useCache,
  otherwise: (id) async {
    return await api.getUser(id) as User;
  },
);

await fetchUser('123');
```

## Best practices

- Keep predicates fast and free of side effects.
- Ensure both branches return the same type `R`.

## Common pitfalls

- **Async predicate timing**: If the predicate depends on mutable state, branches may flip between calls.
- **Branch exceptions**: Exceptions in either branch propagate to the caller.
