# All

## What it is

`all` runs multiple functions concurrently and waits for all of them to complete. It returns a list of results in the same order as the input functions.

## When to use it

- Fan-out to multiple independent services.
- Collecting results from parallel tasks.
- Aggregating data from several sources.

## Async / sync support

| Wrapper | Support |
|---|---|
| `Func1<T, R>` | ✅ Async |
| `Func2<T1, T2, R>` | ✅ Async |

## API reference

```dart
// api-reference
// On Func1<T, R>
Func1<T, List<R>> all(List<Func1<T, R>> functions);

// On Func2<T1, T2, R>
Func2<T1, T2, List<R>> all(List<Func2<T1, T2, R>> functions);
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `functions` | `List<Func1<T, R>>` or `List<Func2<T1, T2, R>>` | Functions to execute in parallel. |

## Examples

### Basic example

```dart
final a = Func1<int, int>((n) async => n + 1);
final b = Func1<int, int>((n) async => n * 2);

final combined = a.all(functions: [b]);
print(await combined(3)); // [4, 6]
```

### Real-world example

```dart
final getUser = Func1<String, dynamic>(
  (id) async => await api.user(id),
);
final getOrders = Func1<String, dynamic>(
  (id) async => await api.orders(id),
);
final getPreferences = Func1<String, dynamic>(
  (id) async => await api.preferences(id),
);

final dashboard = getUser.all(functions: [getOrders, getPreferences]);
final [user, orders, preferences] = await dashboard('123');
print('$user, $orders, $preferences');
```

## Best practices

- Keep functions independent; they run concurrently.
- Use `all` when every result is required.
- Combine with individual `catchError` wrappers if partial failure is acceptable.

## Common pitfalls

- **One failure fails all**: If any function throws, the combined future throws.
- **Ordering**: Results are returned in the order of the input list, not completion order.
