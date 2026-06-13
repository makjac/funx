# Recovery

## What it is

Recovery intercepts failures and runs a recovery action. It is intended for side effects such as logging, cleanup, or compensating work; by default the original error is rethrown.

## When to use it

- Cleaning up resources after a partial failure.
- Running an alternative workflow when the primary one fails.
- Transforming an error into a meaningful result with side effects.

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
Func<R> recover(RecoveryStrategy strategy);

// On Func1<T, R>
Func1<T, R> recover(RecoveryStrategy strategy);

// On Func2<T1, T2, R>
Func2<T1, T2, R> recover(RecoveryStrategy strategy);

class RecoveryStrategy {
  const RecoveryStrategy({
    required Future<void> Function(Object error) onError,
    bool Function(Object error)? shouldRecover,
    bool rethrowAfterRecovery = true,
  });
}
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `onError` | `Future<void> Function(Object error)` | Side effect to run when an error occurs. |
| `shouldRecover` | `bool Function(Object error)?` | Predicate deciding whether to run the recovery action. |
| `rethrowAfterRecovery` | `bool` | Whether to rethrow the original error after the action (default `true`). |

## Examples

### Basic example

```dart
final risky = Func<int>(() async => throw Exception('boom')).recover(
  RecoveryStrategy(
    onError: (error) async => print('recovered from $error'),
  ),
);

try {
  await risky();
} catch (_) {
  print('-1'); // recovery action ran before the original error was rethrown
}
```

### Real-world example

```dart
final processPayment = Func1<Payment, Receipt>((payment) async {
  return await primaryGateway.charge(payment) as Receipt;
}).recover(
  RecoveryStrategy(
    onError: (error) async => logger.warning(
      'Primary gateway failed',
      error,
    ),
    shouldRecover: (error) => error is NetworkException,
  ),
);

// Usage
await processPayment(Payment()).catchError((_) => Receipt());
```

## Best practices

- Log the failure before recovering.
- Keep recovery paths simpler than the main path.
- Use `fallback` when you only need a default value; use `recover` when you need logic.

## Common pitfalls

- **Recovery masking errors**: Make sure recovery failures are also handled or logged.
- **Type mismatch**: The recovery handler must return the same result type `R`.
