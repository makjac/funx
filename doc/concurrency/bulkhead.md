# Bulkhead

## What it is

Bulkhead isolates failures by limiting concurrent executions and optionally rejecting overload. It is similar to a semaphore but is oriented toward resilience: once full, new calls fail fast rather than queue indefinitely.

## When to use it

- Microservice clients where a downstream slowdown should not exhaust all local resources.
- API gateways that must protect backend services.
- Any resource you want to fail fast when overloaded.

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
Func<R> bulkhead({
  required int maxConcurrent,
  int maxWaiting = 0,
});

// On Func1<T, R>
Func1<T, R> bulkhead({
  required int maxConcurrent,
  int maxWaiting = 0,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> bulkhead({
  required int maxConcurrent,
  int maxWaiting = 0,
});
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `maxConcurrent` | `int` | required | Maximum concurrent executions allowed inside the bulkhead. |
| `maxWaiting` | `int` | `0` | Maximum calls allowed to wait for a slot. `0` means fail immediately when full. |

## Examples

### Basic example

```dart
var active = 0;
final work = Func<int>(() async {
  active++;
  await Future<void>.delayed(Duration(milliseconds: 50));
  active--;
  return active;
}).bulkhead(poolSize: 2, queueSize: 1);

await Future.wait([work(), work(), work()]);
// active never exceeded 2 concurrently
```

### Real-world example

```dart
final callApi = Func1<String, Response>((endpoint) async {
  return http.get(endpoint) as Response;
}).bulkhead(poolSize: 5, queueSize: 3);

// Additional concurrent calls throw BulkheadException so the upstream
// service does not sit blocked.

await callApi('/api/data');
```

## Best practices

- Combine with `retry()` or `fallback()` if transient rejection is acceptable.
- Set `maxWaiting` low (often zero) for fail-fast behavior.
- Place bulkhead close to the resource boundary (e.g., HTTP client).

## Common pitfalls

- **Unhandled rejection**: Calls that exceed capacity throw. Wrap in `catchError` or `fallback` if needed.
- **Too much waiting**: A large `maxWaiting` defeats the fail-fast purpose of a bulkhead.
