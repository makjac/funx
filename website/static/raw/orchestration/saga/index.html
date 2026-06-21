# Saga

## What it is

`Saga` models a long-running business transaction as a sequence of steps, each with a compensation action. If a step fails, previously completed steps are rolled back in reverse order.

## When to use it

- Distributed transactions across multiple services.
- Booking workflows (reserve, charge, confirm) that must undo earlier steps on failure.
- Any multi-step process that requires compensating actions.

## Async / sync support

| Wrapper | Support |
|---|---|
| `Func1<T, R>` | ✅ Async |
| `Func2<T1, T2, R>` | ✅ Async |

## API reference

```dart
// api-reference
class Saga<T, R> {
  Saga();

  Saga<T, R> step(
    Func1<T, R> action, {
    required Func2<R, T, void> compensate,
  });

  Future<R> execute(T input);
}
```

### Methods

| Method | Description |
|---|---|
| `step(action, {required compensate})` | Adds a step with its compensation action. |
| `execute(T input)` | Runs all steps sequentially. On failure, compensations run in reverse order. |

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `action` | `Func1<T, R>` | Step to execute. |
| `compensate` | `Func2<R, T, void>` | Undo action receiving the step result and original input. |

## Examples

### Basic example

```dart
final saga = Func1<int, int>((n) async => n).saga(
  steps: [
    SagaStep<int, int>(
      action: Func1<int, int>((n) async => n + 10),
      compensation: Func1<int, void>((result) async {
        print('compensate +10');
      }),
    ),
    SagaStep<int, int>(
      action: Func1<int, int>((n) async => throw Exception('fail')),
      compensation: Func1<int, void>((result) async {
        print('compensate fail');
      }),
    ),
  ],
);

try {
  await saga(0);
} catch (e) {
  print('rolled back');
}
```

### Real-world example

```dart
final bookingSaga = Func1<BookingRequest, Reservation>(
  (req) async => await bookingApi.reserve(req) as Reservation,
).saga(
  steps: [
    SagaStep<Reservation, Payment>(
      action: Func1<Reservation, Payment>(
        (reservation) async =>
            await paymentService.charge(reservation) as Payment,
      ),
      compensation: Func1<Payment, void>(
        (payment) async => await paymentService.refund(payment),
      ),
    ),
    SagaStep<Payment, Booking>(
      action: Func1<Payment, Booking>(
        (payment) async => await bookingApi.confirm(payment) as Booking,
      ),
      compensation: Func1<Booking, void>(
        (booking) async => await bookingApi.cancel(booking),
      ),
    ),
  ],
);

final booking = await bookingSaga(BookingRequest());
print(booking);
```

## Best practices

- Make compensation actions idempotent.
- Keep compensation logic simple and reliable; it must not fail often.
- Log every compensation for auditability.
- Test both the happy path and each failure point.

## Common pitfalls

- **Compensation failures**: If a compensation throws, the saga is left in a partially compensated state. Add monitoring and manual intervention procedures.
- **Non-idempotent compensations**: Running the same compensation twice should be safe.
- **Shared mutable state**: Steps should communicate through their inputs/outputs, not shared mutable state.
