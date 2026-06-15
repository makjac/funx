# Cancellable

## What it is

`cancellable()` wraps a function so that each invocation can be cancelled before it completes. Cancellation is cooperative: the wrapped future completes with a `CancelException`, while any inner work that has already started continues until it finishes on its own.

## When to use it

- Network requests that should be dropped when a user leaves a screen.
- Background computations that become obsolete after a newer request arrives.
- Any async work where the caller needs the ability to say "I no longer care about the result".

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
CancellableFunc<R> cancellable({CancelToken? token});

// On Func1<T, R>
CancellableFunc1<T, R> cancellable({CancelToken? token});

// On Func2<T1, T2, R>
CancellableFunc2<T1, T2, R> cancellable({CancelToken? token});
```

### Returned wrapper methods

```dart
// Func / Func1 / Func2 variants
Future<R> call(...);                         // Normal call, returns result future.
CancelableOperation<R> operation();          // Func variant.
CancelableOperation<R> operation(T arg);     // Func1 variant.
CancelableOperation<R> operation(T1 a, T2 b); // Func2 variant.
void cancel();                               // Cancels the most recent operation.
```

### CancelableOperation

```dart
final cancellableFunc = Func<String>(() async => 'data').cancellable();
final operation = cancellableFunc.operation();
operation.cancel();

await operation.value; // throws CancelException if cancelled
```

### CancelToken

```dart
Future<String> workA() async => 'A';
Future<String> workB() async => 'B';

final token = CancelToken();
final a = Func(workA).cancellable(token: token);
final b = Func(workB).cancellable(token: token);

unawaited(a());
unawaited(b());

token.cancel(); // cancels both active operations
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `token` | `CancelToken?` | `null` | Optional shared token for cancelling multiple operations at once. |

## Examples

### Basic example

```dart
var executed = false;
final slow = Func<String>(() async {
  await Future<void>.delayed(Duration(seconds: 5));
  executed = true;
  return 'done';
}).cancellable();

final operation = slow.operation();
operation.cancel();

try {
  await operation.value;
} on CancelException {
  print('cancelled');
}

print(executed); // may still become true later
```

### Shared token example

```dart
final token = CancelToken();

final fetchUser = Func1<String, String>((id) async {
  await Future<void>.delayed(Duration(seconds: 2));
  return 'user:$id';
}).cancellable(token: token);

final fetchOrders = Func1<String, String>((id) async {
  await Future<void>.delayed(Duration(seconds: 2));
  return 'orders:$id';
}).cancellable(token: token);

unawaited(fetchUser('42'));
unawaited(fetchOrders('42'));

token.cancel();
```

### Chaining example

```dart
final fetch = Func<String>(() async {
  await Future<void>.delayed(Duration(seconds: 2));
  return 'data';
})
    .retry(maxAttempts: 3)
    .timeout(Duration(seconds: 5))
    .cancellable();

final operation = fetch.operation();
operation.cancel();
```

## Best practices

- Place `cancellable()` as the **outermost** decorator when chaining so cancellation wraps the entire pipeline.
- Use `CancelToken` when several related operations should be cancelled together, for example on widget disposal.
- Catch `CancelException` only when you need to react to cancellation; otherwise let it propagate to the caller.
- Do not rely on cancellation to stop CPU-bound synchronous work immediately. It only prevents awaiting the result.

## Common pitfalls

- **Forgetting that inner work continues**: cancellation in Dart cannot literally abort a running `Future`. Timers, network requests, and other async work may keep running until they complete naturally.
- **Using `cancellable()` deep inside a chain**: if placed before `retry()` or `timeout()`, the returned wrapper may not expose `operation()`, and cancellation may not cover the whole pipeline.
- **Awaiting after cancel**: awaiting a cancelled operation always throws `CancelException`.
