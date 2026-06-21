# Circuit Breaker

## What it is

A circuit breaker stops calling a failing function after a threshold of failures is reached. While open, calls fail fast or return a fallback value. After a cooldown, it enters a half-open state and allows a probe to test recovery.

## When to use it

- External API clients that should not keep calling a down service.
- Database connections under load.
- Cascading failure prevention in distributed systems.

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
Func<R> circuitBreaker(CircuitBreaker breaker);

// On Func1<T, R>
Func1<T, R> circuitBreaker(CircuitBreaker breaker);

// On Func2<T1, T2, R>
Func2<T1, T2, R> circuitBreaker(CircuitBreaker breaker);

enum CircuitBreakerState { closed, open, halfOpen }
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `failureThreshold` | `int` | `5` | Failures needed to open the circuit. |
| `successThreshold` | `int` | `2` | Consecutive successes in half-open needed to close. |
| `timeout` | `Duration` | `30s` | Time before switching from open to half-open. |
| `onStateChange` | `void Function(CircuitBreakerState, CircuitBreakerState)?` | `null` | Called on state transitions. |

### Returned wrapper properties

```dart
// api-reference
CircuitBreakerState get state;
```

## Examples

### Basic example

```dart
var fails = 0;
final breaker = CircuitBreaker(
  failureThreshold: 2,
  timeout: Duration(milliseconds: 100),
);
final api = Func<String>(() async {
  fails++;
  throw Exception('down ($fails)');
}).circuitBreaker(breaker);

await api().catchError((_) => 'fallback');
await api().catchError((_) => 'fallback'); // circuit opens
await Future<void>.delayed(Duration(milliseconds: 150));
await api().catchError((_) => 'still fallback'); // half-open probe
```

### Real-world example

```dart
final breaker = CircuitBreaker(
  failureThreshold: 3,
  timeout: Duration(seconds: 10),
);
final paymentGateway = Func1<Payment, Receipt>((payment) async {
  return await gateway.charge(payment) as Receipt;
}).circuitBreaker(breaker).fallback(
  fallbackFunction: Func1<Payment, Receipt>((payment) async => Receipt()),
);

// Usage
print(await paymentGateway(Payment()));

// Open circuit returns Receipt.declined() instantly.
```

## Best practices

- Combine with `fallback()` so callers receive a graceful degradation while the circuit is open.
- Set `failureThreshold` based on observed normal error rates.
- Keep `timeout` long enough for the downstream service to recover.

## Common pitfalls

- **Threshold too low**: A brief spike can open the circuit unnecessarily.
- **No fallback**: An open circuit throws; make sure upstream code handles it.
- **Half-open storms**: Tune `successThreshold` so only a few probes close the circuit.
