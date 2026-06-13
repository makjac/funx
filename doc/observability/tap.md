# Tap

## What it is

`tap` runs a side-effect callback on the result or error of the wrapped function without changing the returned value.

## When to use it

- Logging results for debugging.
- Emitting metrics after a function completes.
- Triggering notifications on success or failure.

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
Func<R> tap({
  FutureOr<void> Function(R result)? onValue,
  FutureOr<void> Function(Object error, StackTrace stackTrace)? onError,
});

// On Func1<T, R>
Func1<T, R> tap({
  FutureOr<void> Function(R result)? onValue,
  FutureOr<void> Function(Object error, StackTrace stackTrace)? onError,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> tap({
  FutureOr<void> Function(R result)? onValue,
  FutureOr<void> Function(Object error, StackTrace stackTrace)? onError,
});
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `onValue` | `FutureOr<void> Function(R result)` | Called with the result on success. |
| `onError` | `FutureOr<void> Function(Object error, StackTrace stackTrace)` | Called with the error and stack trace on failure. |

## Examples

### Basic example

```dart
final logResult = Func1<int, int>((n) async => n * 2).tap(
  onValue: (result) => print('doubled -> $result'),
);

print(await logResult(5)); // 10
// logs: doubled -> 10
```

### Real-world example

```dart
final trackPayment = Func1<Payment, Receipt>((payment) async {
  return await gateway.charge(payment) as Receipt;
}).tap(
  onValue: (receipt) {
    analytics.track('payment_success', {'id': receipt.hashCode});
  },
  onError: (error, stack) {
    analytics.track('payment_failed', {'error': error.toString()});
  },
);

await trackPayment(Payment());
```

## Best practices

- Keep tap callbacks fast; slow callbacks delay the result.
- Do not throw inside `onValue` or `onError` unless you want to change the wrapper's outcome.
- Use `tap` for observation only, not for business logic.

## Common pitfalls

- **Callback exceptions**: If a tap callback throws, the wrapper may fail even though the original function succeeded.
- **Mutating results**: Modifying the result object inside `onValue` affects downstream callers.
