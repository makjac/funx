# Monitor Observability

## What it is

`monitorObservability` is a richer observability decorator that tracks execution metrics such as duration, success, and failure counts.

## When to use it

- Collecting latency histograms.
- Health checks that count failures.
- Triggering alerts when error rates exceed thresholds.

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
Func<R> monitorObservability({
  void Function(Metrics metrics)? onMetricsUpdate,
});

// On Func1<T, R>
Func1<T, R> monitorObservability({
  void Function(Metrics metrics)? onMetricsUpdate,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> monitorObservability({
  void Function(Metrics metrics)? onMetricsUpdate,
});

class Metrics {
  int executionCount;
  int errorCount;
  Duration totalDuration;
  Duration? lastDuration;
  Object? lastError;
  DateTime? lastExecutionTime;
  Duration get averageDuration;
  double get successRate;
}
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `onMetricsUpdate` | `void Function(Metrics)?` | Callback invoked after each execution. |

## Examples

### Basic example

```dart
final measured = Func<int>(() async {
  await Future<void>.delayed(Duration(milliseconds: 50));
  return 42;
}).monitorObservability(
  onMetricsUpdate: (m) {
    print('compute: ${m.lastDuration?.inMilliseconds}ms, success=${m.successRate == 1.0}');
  },
);

await measured();
```

### Real-world example

```dart
final measuredApi = Func1<String, User>((id) async {
  return await api.getUser(id) as User;
}).monitorObservability(
  onMetricsUpdate: (m) {
    if (m.lastDuration != null) {
      metrics.histogram('api_latency_ms', m.lastDuration!.inMilliseconds);
    }
    if (m.successRate < 1.0) {
      metrics.increment('api_errors', tags: {'op': 'getUser'});
    }
  },
);

await measuredApi('user-123');
```

## Best practices

- Keep `onMetricsUpdate` synchronous and non-blocking.
- Do not mutate the function's behavior inside the metrics callback.

## Common pitfalls

- **Slow metrics callback**: Blocks the result from being returned; use a fire-and-forget metrics sink if needed.
- **Callback exceptions**: Exceptions in `onMetricsUpdate` can alter the wrapper's result.
