# Control Flow

Control-flow decorators change whether, how many times, and which implementation runs.

---

## when

### What it is

Conditionally executes the wrapped function or an alternative based on a predicate.

### When to use it

- Feature flags
- Permission checks
- Input filtering

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> when({
  required bool Function() condition,
  Future<R> Function()? otherwise,
})
```

For `Func1`:

```dart
// api-reference
Func1<T, R> when({
  required bool Function(T arg) condition,
  Future<R> Function(T arg)? otherwise,
})
```

For `Func2`:

```dart
// api-reference
Func2<T1, T2, R> when({
  required bool Function(T1 arg1, T2 arg2) condition,
  Future<R> Function(T1 arg1, T2 arg2)? otherwise,
})
```

Throws `StateError('Condition not met and no alternative provided')` if the condition is false and no `otherwise` is given.

### Examples

**Minimal**

```dart
final feature = Func<String>(() async => 'premium')
  .when(
    condition: () => true,
    otherwise: () async => 'basic',
  );

void main() async {
  print(await feature()); // premium
}
```

**Real world**

```dart
final processPayment = Func1<Payment, Result>((payment) async {
  return await primaryGateway.charge(payment) as Result;
}).when(
  condition: (payment) => featureFlags.isPremium as bool,
  otherwise: (payment) async => await secondaryGateway.charge(payment) as Result,
);

await processPayment(Payment());
```

### Best practices

- Keep conditions cheap; they run on every call.
- Provide an `otherwise` branch unless failure is intentional.

### Common pitfalls

- Mutable state inside the condition can make behavior unpredictable.
- The wrapped function is not called when the condition is false.

---

## repeat

### What it is

Repeats execution a fixed number of times or until a predicate is satisfied.

### When to use it

- Polling
- Retry loops
- Batch processing

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> repeat({
  int? times,
  Duration? interval,
  bool Function(R result)? until,
  void Function(int iteration, R result)? onIteration,
})
```

- `times` — max iterations; `null` means infinite.
- `interval` — delay between iterations.
- `until` — stops when predicate returns `true`.
- `onIteration` — called after each iteration.

### Examples

**Minimal**

```dart
final poll = Func<String>(() async => 'ready')
  .repeat(
    times: 5,
    interval: Duration(milliseconds: 100),
    until: (result) => result == 'ready',
  );

void main() async {
  print(await poll()); // ready
}
```

**Real world**

```dart
final waitForBuild = Func1<String, Status>((buildId) async {
  return await ciApi.status(buildId) as Status;
}).repeat(
  times: 60,
  interval: Duration(seconds: 5),
  until: (status) => status.ready,
  onIteration: (i, status) => logger.info('Poll $i: $status'),
);

await waitForBuild('build-123');
```

### Best practices

- Always bound loops with `times` or `until`.
- Use `retry` instead of `repeat` for transient-error retries with backoff.

### Common pitfalls

- Infinite loops are possible if `times` and `until` are both null.
- Errors are not caught; use with `retry` or `defaultValue` if needed.

---

## switch (SwitchExtension)

### What it is

Routes execution to one of several function implementations based on a selector.

### When to use it

- Strategy pattern
- Polymorphic dispatch
- Request routing

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ❌ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
SwitchExtension1<T, R>({
  required Object? Function(T arg) selector,
  required Map<Object?, Func1<T, R>> cases,
  Func1<T, R>? defaultCase,
})
```

For `Func2`:

```dart
// api-reference
SwitchExtension2<T1, T2, R>({
  required Object? Function(T1 arg1, T2 arg2) selector,
  required Map<Object?, Func2<T1, T2, R>> cases,
  Func2<T1, T2, R>? defaultCase,
})
```

Throws `SwitchException` if no case matches and no `defaultCase` is provided.

### Examples

**Minimal**

```dart
final handle = SwitchExtension1<String, String>(
  selector: (type) => type,
  cases: {
    'a': Func1((_) async => 'A'),
    'b': Func1((_) async => 'B'),
  },
  defaultCase: Func1((_) async => '?'),
);

void main() async {
  print(await handle('a')); // A
}
```

**Real world**

```dart
final processPayment = SwitchExtension1<String, Result>(
  selector: (method) => method,
  cases: {
    'card': Func1<String, Result>((method) async => cardProcessor.charge(method) as Result),
    'bank': Func1<String, Result>((method) async => bankProcessor.transfer(method) as Result),
  },
  defaultCase: Func1<String, Result>((method) async => Result()),
);

await processPayment('card');
```

### Best practices

- Provide a `defaultCase` to avoid exceptions for unknown selectors.
- Keep case handlers small and focused.

### Common pitfalls

- `SwitchExtension` is a standalone class used directly, not chained via a decorator method.
- Matching uses equality on selector result; ensure keys have stable equality.