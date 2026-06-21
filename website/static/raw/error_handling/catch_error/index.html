# catchError

## What it is

`catchError` catches specific exception types thrown by the wrapped function and routes each to a typed handler. Unmatched exceptions are either handled by `catchAll` or rethrown.

## When to use it

- Centralised error logging.
- Converting low-level exceptions into domain exceptions.
- Graceful suppression of non-critical failures.

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
Func<R> catchError({
  required Map<Type, Future<R> Function(Object)> handlers,
  Future<R> Function(Object)? catchAll,
  void Function(Object error)? onCatch,
});

// On Func1<T, R>
Func1<T, R> catchError({
  required Map<Type, Future<R> Function(Object)> handlers,
  Future<R> Function(Object)? catchAll,
  void Function(Object error)? onCatch,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> catchError({
  required Map<Type, Future<R> Function(Object)> handlers,
  Future<R> Function(Object)? catchAll,
  void Function(Object error)? onCatch,
});
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `handlers` | `Map<Type, Future<R> Function(Object)>` | Maps `error.runtimeType` to a recovery function. |
| `catchAll` | `Future<R> Function(Object)?` | Fallback handler for unmatched exceptions. |
| `onCatch` | `void Function(Object)?` | Called for every caught exception before its handler runs. |

## Examples

### Basic example

```dart
final safe = Func<int>(() async => throw FormatException('boom')).catchError(
  handlers: {
    FormatException: (e) async => -1,
  },
);

print(await safe()); // -1
```

### Real-world example

```dart
final fetchSettings = Func1<String, Settings>((userId) async {
  return (await api.settings(userId)) as Settings;
}).catchError(
  handlers: {
    NetworkException: (e) async => Settings(),
    AuthException: (e) async => Settings(),
  },
  catchAll: (e) async {
    logger.error('Settings fetch failed', e);
    return Settings();
  },
);

void main() async {
  final settings = await fetchSettings('user-123');
  print(settings);
}
```

## Best practices

- Put the most specific exception types first in the map.
- Use `catchAll` for logging unexpected failures.
- Only suppress errors you understand and can handle safely.

## Common pitfalls

- **Matching by exact type**: A `SocketException` handler will not catch a `ClientException`.
- **Map order matters**: Handlers are checked in iteration order.
- **Handler exceptions**: If the handler throws, the wrapper throws that new exception.
