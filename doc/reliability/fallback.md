# Fallback

## What it is

Fallback provides a value or action to use when the wrapped function throws. It is a simpler alternative to full retry logic when a degraded result is acceptable.

## When to use it

- Returning cached data when a network call fails.
- Returning a default UI state when analytics tracking fails.
- Converting hard failures into soft failures.

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
Func<R> fallback({
  R? fallbackValue,
  Func<R>? fallbackFunction,
  bool Function(Object error)? fallbackIf,
  void Function(Object error)? onFallback,
});

// On Func1<T, R>
Func1<T, R> fallback({
  R? fallbackValue,
  Func1<T, R>? fallbackFunction,
  bool Function(Object error)? fallbackIf,
  void Function(Object error)? onFallback,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> fallback({
  R? fallbackValue,
  Func2<T1, T2, R>? fallbackFunction,
  bool Function(Object error)? fallbackIf,
  void Function(Object error)? onFallback,
});
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `fallbackValue` | `R?` | Constant value returned on failure. |
| `fallbackFunction` | `Func<R>?` / `Func1<T, R>?` / `Func2<T1, T2, R>?` | Computed fallback receiving the original arguments. |
| `fallbackIf` | `bool Function(Object error)?` | Predicate deciding whether to use the fallback. |
| `onFallback` | `void Function(Object error)?` | Called when fallback is used. |

## Examples

### Basic example

```dart
final flaky = Func<int>(() async => throw Exception('fail')).fallback(
  fallbackValue: 42,
);

print(await flaky()); // 42
```

### Real-world example

```dart
final fetchProfile = Func1<String, Profile>((id) async {
  return await api.profile(id) as Profile;
}).fallback(
  fallbackFunction: Func1<String, Profile>((id) async {
    final cached = cache.getProfile(id) as Profile?;
    return cached ?? Profile();
  }),
);

print(await fetchProfile('123'));
```

## Best practices

- Log the original error inside the fallback handler for observability.
- Return a value of the same type `R` as the wrapped function.
- Use `fallback` for failures where degraded behavior is better than crashing.

## Common pitfalls

- **Throwing inside fallback**: If the handler throws, the wrapper itself throws; keep handlers simple.
- **Type mismatch**: The fallback must return the same `R` type as the original function.
