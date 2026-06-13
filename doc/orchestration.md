# Orchestration

Orchestration decorators compose multiple function executions: racing them, running them in parallel, or chaining them with compensation.

---

## race

### What it is

Runs the primary function and several competitors in parallel and returns the result of the first one to complete successfully.

### When to use it

- Primary/backup API selection
- Latency-sensitive reads
- Hedged requests

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ❌ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
RaceExtension1<T, R>(
  Func1<T, R> primary, {
  required List<Func1<T, R>> competitors,
  void Function(int index, R result)? onWin,
  void Function(int index, R result)? onLose,
})
```

For `Func2`:

```dart
// api-reference
RaceExtension2<T1, T2, R>(
  Func2<T1, T2, R> primary, {
  required List<Func2<T1, T2, R>> competitors,
  void Function(int index, R result)? onWin,
  void Function(int index, R result)? onLose,
})
```

### Examples

**Minimal**

```dart
final fastest = RaceExtension1<String, String>(
  Func1((_) async {
    await Future<void>.delayed(Duration(milliseconds: 100));
    return 'primary';
  }),
  competitors: [
    Func1((_) async => 'backup'),
  ],
);

void main() async {
  print(await fastest('x')); // backup
}
```

**Real world**

```dart
final fetchQuote = RaceExtension1<String, Quote>(
  Func1((symbol) async => await primaryExchange.quote(symbol) as Quote),
  competitors: [
    Func1((symbol) async => await backupExchange.quote(symbol) as Quote),
  ],
  onWin: (index, quote) => metrics.increment('backup_quote_wins'),
);

await fetchQuote('AAPL');
```

### Best practices

- Use competitors with similar semantics so any result is valid.
- Combine with `timeout` on each competitor to avoid slow sources.

### Common pitfalls

- Losers continue running; their results are ignored.
- If all sources fail, the first error is thrown.

---

## all

### What it is

Runs the primary function and additional functions in parallel, collecting all results in order.

### When to use it

- Parallel independent reads
- Bulk operations
- Scatter-gather

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ❌ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
AllExtension1<T, R>(
  Func1<T, R> primary, {
  required List<Func1<T, R>> functions,
  bool failFast = true,
  void Function(int index, R result)? onComplete,
})
```

For `Func2`:

```dart
// api-reference
AllExtension2<T1, T2, R>(
  Func2<T1, T2, R> primary, {
  required List<Func2<T1, T2, R>> functions,
  bool failFast = true,
  void Function(int index, R result)? onComplete,
})
```

### Examples

**Minimal**

```dart
final combined = AllExtension1<int, int>(
  Func1((n) async => n),
  functions: [
    Func1((n) async => n * 2),
    Func1((n) async => n + 1),
  ],
);

void main() async {
  print(await combined(3)); // [3, 6, 4]
}
```

**Real world**

```dart
final enrichUser = AllExtension1<String, dynamic>(
  Func1((id) async => await profileApi.get(id)),
  functions: [
    Func1((id) async => await ordersApi.recent(id)),
    Func1((id) async => await preferencesApi.get(id)),
  ],
  failFast: true,
  onComplete: (index, result) => logger.info('Source $index complete'),
);

await enrichUser('user-123');
```

### Best practices

- Use `failFast: false` only when you plan to inspect partial results yourself; `all` still throws the first error.
- Keep functions independent to maximize parallelism.

### Common pitfalls

- `all` returns `List<R>`; the primary result is at index 0.
- When `failFast` is true, the first error aborts the await.

---

## saga

### What it is

Executes a sequence of steps where each step can have a compensating action. If any step fails, completed steps are compensated in reverse order.

### When to use it

- Distributed transactions
- Multi-step workflows that must remain consistent
- Booking, payment, and inventory operations

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ❌ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
SagaExtension1<T, R>(
  Func1<T, R> initialStep, {
  required List<SagaStep<dynamic, dynamic>> steps,
  void Function(int index, dynamic result)? onCompensate,
  void Function(int index, dynamic result)? onStepComplete,
  void Function(int index, dynamic result, Object error)? onCompensationError,
})
```

For `Func2`:

```dart
// api-reference
SagaExtension2<T1, T2, R>(
  Func2<T1, T2, R> initialStep, {
  required List<SagaStep<dynamic, dynamic>> steps,
  ...
})
```

`SagaStep`:

```dart
// api-reference
SagaStep<T, R>({
  required Func1<T, R> action,
  required Func1<R, void> compensation,
})
```

### Examples

**Minimal**

```dart
final saga = SagaExtension1<int, int>(
  Func1((n) async => n),
  steps: [
    SagaStep<int, int>(
      action: Func1<int, int>((int n) async => n + 1),
      compensation: Func1<int, void>((int n) async => print('compensate $n')),
    ),
  ],
);

void main() async {
  print(await saga(1)); // 2
}
```

**Real world**

```dart
final placeOrder = SagaExtension1<Order, Receipt>(
  Func1((order) async => await orderService.create(order) as Receipt),
  steps: [
    SagaStep<Receipt, Charge>(
      action: Func1<Receipt, Charge>(
        (Receipt receipt) async => await paymentService.charge(receipt) as Charge,
      ),
      compensation: Func1<Charge, void>(
        (Charge charge) async => await paymentService.refund(charge),
      ),
    ),
    SagaStep<Charge, Notification>(
      action: Func1<Charge, Notification>(
        (Charge charge) async =>
            await notificationService.send(charge) as Notification,
      ),
      compensation: Func1<Notification, void>(
        (Notification msg) async => await notificationService.cancel(msg),
      ),
    ),
  ],
  onCompensate: (index, result) => logger.info('Compensating step $index'),
  onCompensationError: (index, result, error) =>
      logger.error('Compensation failed', error),
);

await placeOrder(Order());
```

### Best practices

- Design compensations to be idempotent.
- Log all compensation errors; a failed compensation leaves the system partially inconsistent.

### Common pitfalls

- The initial step has no compensation; only `steps` are compensated.
- Compensation errors are caught and reported via `onCompensationError`; the original exception is still thrown.