# Proxy

## What it is

`proxy` is a decorator that intercepts function calls with before/after hooks and argument transformation.

## When to use it

- Dependency injection and testing.
- A/B testing where you switch between implementations.
- Feature flags that change behavior dynamically.

## API reference

```dart
// api-reference
// On Func<R>
Func<R> proxy({
  void Function()? beforeCall,
  R Function(R result)? afterCall,
  void Function(Object error, StackTrace stackTrace)? onError,
});

// On Func1<T, R>
Func1<T, R> proxy({
  void Function(T arg)? beforeCall,
  T Function(T arg)? transformArg,
  R Function(R result)? afterCall,
  void Function(Object error, StackTrace stackTrace)? onError,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> proxy({
  void Function(T1 arg1, T2 arg2)? beforeCall,
  (T1, T2) Function(T1 arg1, T2 arg2)? transformArgs,
  R Function(R result)? afterCall,
  void Function(Object error, StackTrace stackTrace)? onError,
});
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `beforeCall` | `void Function(...)?` | Invoked before the wrapped function. |
| `transformArg` / `transformArgs` | `T Function(T)?` / `(T1, T2) Function(T1, T2)?` | Transforms arguments before passing them to the wrapped function. |
| `afterCall` | `R Function(R)?` | Transforms the result after successful execution. |
| `onError` | `void Function(Object, StackTrace)?` | Called when the wrapped function throws; the error is still rethrown. |

## Examples

### Basic example

```dart
final proxy = Func1<int, int>((n) async => n * 2).proxy(
  beforeCall: (n) => print('input: $n'),
  transformArg: (n) => n.abs(),
  afterCall: (r) => r * 10,
);

print(await proxy(-5)); // 100
```

### Real-world example

```dart
final apiProxy = Func1<String, User>((id) async {
  return await api.getUser(id) as User;
}).proxy(
  beforeCall: (id) => logger.info('Fetching user $id'),
  afterCall: (user) {
    logger.info('Got user: $user');
    return user;
  },
);

print(await apiProxy('123'));
```

## Best practices

- Use `proxy` for cross-cutting concerns like logging, normalization, or enrichment.
- Prefer `tap` when you only need to observe results without transforming them.

## Common pitfalls

- **`onError` is called but the original exception is still rethrown**.
- **`afterCall` is not called when the function fails**.
