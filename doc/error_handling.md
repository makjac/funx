# Error Handling

Error-handling decorators catch exceptions and convert them into fallback values or typed recovery paths. They are similar to reliability decorators but focused on deterministic error translation rather than transient failure recovery.

---

## catchError

### What it is

Catches specific exception types by `runtimeType` and routes each to a typed handler. Unmatched exceptions are either handled by `catchAll` or rethrown.

### When to use it

- Mapping domain exceptions to fallback values
- Converting errors into user-friendly results
- Centralized exception handling for a function

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> catchError({
  required Map<Type, Future<R> Function(Object)> handlers,
  Future<R> Function(Object)? catchAll,
  void Function(Object error)? onCatch,
})
```

- `handlers` — map of `error.runtimeType` to handler function.
- `catchAll` — fallback handler for unmatched exceptions.
- `onCatch` — called for every caught exception before the handler runs.

### Examples

**Minimal**

```dart
final parse = Func<int>(() async => int.parse('not-a-number'))
  .catchError(
    handlers: {
      FormatException: (e) async => 0,
    },
  );

void main() async {
  print(await parse()); // 0
}
```

**Real world**

```dart
final fetchUser = Func1<String, User>((id) async {
  return (await api.getUser(id)) as User;
}).catchError(
  handlers: {
    NotFoundException: (e) async => User(),
    AuthException: (e) async => User(),
  },
  catchAll: (e) async {
    logger.error('Unexpected error fetching user', e);
    return User();
  },
  onCatch: (e) => metrics.increment('user_fetch_error'),
);

void main() async {
  final user = await fetchUser('123');
  print(user);
}
```

### Best practices

- Put the most specific exception types first in the map.
- Use `catchAll` for logging unexpected failures.

### Common pitfalls

- Matching is by exact `runtimeType`; a `SocketException` handler will not catch a `ClientException`.
- Handlers are checked in iteration order; map order matters.

---

## defaultValue

### What it is

Returns a static default value when the wrapped function throws. An optional predicate controls which errors trigger the default.

### When to use it

- Non-critical reads where any value is better than an exception
- Ensuring non-null results
- Simple fail-safe defaults

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> defaultValue({
  required R defaultValue,
  bool Function(Object error)? defaultIf,
  void Function()? onDefault,
})
```

- `defaultValue` — value returned on failure.
- `defaultIf` — if provided and returns `false`, the error is rethrown.
- `onDefault` — called when the default is used.

### Examples

**Minimal**

```dart
final parse = Func<int>(() async => int.parse('x'))
  .defaultValue(defaultValue: 0);

void main() async {
  print(await parse()); // 0
}
```

**Real world**

```dart
final fetchConfig = Func<Config>(() async {
  return (await remoteConfig.fetch()) as Config;
}).defaultValue(
  defaultValue: Config(),
  defaultIf: (e) => e is NetworkException,
  onDefault: () => logger.warn('Using default config'),
);

void main() async {
  final config = await fetchConfig();
  print(config);
}
```

### Best practices

- Use `defaultIf` to avoid masking critical errors.
- Keep the default value immutable if possible.

### Common pitfalls

- `defaultValue` is evaluated once when the decorator is created; if it is mutable, all failures share the same instance.