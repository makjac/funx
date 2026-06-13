# Default Value

## What it is

`defaultValue` provides a static fallback returned whenever the wrapped function throws. An optional predicate controls which errors trigger the default.

## When to use it

- Providing a safe default for optional data.
- Ensuring non-critical operations never crash.
- Simple defensive wrapping.

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
Func<R> defaultValue({
  required R defaultValue,
  bool Function(Object error)? defaultIf,
  void Function()? onDefault,
});

// On Func1<T, R>
Func1<T, R> defaultValue({
  required R defaultValue,
  bool Function(Object error)? defaultIf,
  void Function()? onDefault,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> defaultValue({
  required R defaultValue,
  bool Function(Object error)? defaultIf,
  void Function()? onDefault,
});
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `defaultValue` | `R` | Value to return on failure. |
| `defaultIf` | `bool Function(Object)?` | If provided and returns `false`, the error is rethrown. |
| `onDefault` | `void Function()?` | Called when the default value is used. |

## Examples

### Basic example

```dart
final safe = Func<int>(() async => throw Exception('boom'))
  .defaultValue(defaultValue: 0);
print(await safe()); // 0
```

### Real-world example

```dart
final getTimeout = Func<Duration>(() async {
  return Duration(seconds: config['timeout'] as int);
}).defaultValue(
  defaultValue: Duration(seconds: 30),
  defaultIf: (e) => e is FormatException,
  onDefault: () => logger.warn('Using default timeout'),
);

void main() async {
  final timeout = await getTimeout();
  print(timeout);
}
```

## Best practices

- Use `defaultValue` only when any failure is equivalent and safe to ignore.
- Prefer `catchError` or `fallback` when you need logging or conditional handling.

## Common pitfalls

- **Masking bugs**: A broad default value can hide configuration or parsing errors.
- **Non-nullable defaults**: Make sure the default value is a valid instance of `R`.
