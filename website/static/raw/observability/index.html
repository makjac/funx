# Observability

Observability decorators let you inspect function execution without changing its result. Use them for logging, metrics, audit trails, and debugging.

---

## tap

### What it is

Executes side-effect callbacks on success or failure without modifying the result or error.

### When to use it

- Logging
- Metrics emission
- Debugging
- Analytics tracking

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> tap({
  void Function(R value)? onValue,
  void Function(Object error, StackTrace stackTrace)? onError,
})
```

### Examples

**Minimal**

```dart
final f = Func<int>(() async => 42).tap(
  onValue: (v) => print('got $v'),
  onError: (e, s) => print('error $e'),
);

void main() async {
  print(await f()); // got 42, 42
}
```

**Real world**

```dart
final fetchUser = Func1<String, User>((id) async {
  return await api.getUser(id) as User;
}).tap(
  onValue: (user) => analytics.track('user_fetched', {'id': (user as dynamic).id}),
  onError: (e, s) => errorReporter.report(e, s),
);

await fetchUser('user-123');
```

### Best practices

- Keep tap callbacks fast; they run on the critical path.
- Do not throw inside `onValue` or `onError`; use `audit` or `catchError` for that.

### Common pitfalls

- `tap` does not catch errors; if `onError` throws, that exception propagates.
- Slow callbacks increase latency.

---

## monitorObservability

### What it is

Collects execution metrics: count, errors, durations, success rate.

### When to use it

- Health checks
- Performance monitoring
- SLO dashboards

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> monitorObservability()
```

Methods:

- `Metrics getMetrics()` — returns a snapshot.
- `void resetMetrics()` — resets counters.

`Metrics` fields:

- `executionCount`
- `errorCount`
- `totalDuration`
- `lastDuration`
- `lastError`
- `lastExecutionTime`
- `averageDuration`
- `successRate`

### Examples

**Minimal**

```dart
final f = Func<int>(() async => 42).monitorObservability();

void main() async {
  await f();
  print(f.getMetrics().executionCount); // 1
}
```

**Real world**

```dart
final fetchProfile = Func1<String, Profile>((id) async {
  return await api.profile(id) as Profile;
}).monitorObservability();

// Later
final metrics = fetchProfile.getMetrics();
logger.info('Success rate: ${metrics.successRate}');
```

### Best practices

- Export metrics to your monitoring system periodically.
- Reset metrics when deploying a new version to get per-version stats.

### Common pitfalls

- Public API name is `monitorObservability()` to avoid clashing with the concurrency `monitor` decorator.
- Metrics are kept in memory; they are lost when the process restarts.

---

## audit

### What it is

Records detailed per-execution logs including arguments, result, error, stack trace, and duration.

### When to use it

- Compliance logging
- Security audit trails
- Debugging complex failures

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ❌ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func1<T, R> audit({
  void Function(AuditLog<T, R> log)? onAudit,
  int maxLogs = 100,
})
```

For `Func2`:

```dart
// api-reference
Func2<T1, T2, R> audit({
  void Function(AuditLog<(T1, T2), R> log)? onAudit,
  int maxLogs = 100,
})
```

Methods:

- `List<AuditLog<T, R>> getLogs()`
- `List<AuditLog<T, R>> getSuccessLogs()`
- `List<AuditLog<T, R>> getFailureLogs()`
- `void clearLogs()`

### Examples

**Minimal**

```dart
final f = Func1<int, int>((n) async => n * 2).audit(
  onAudit: (log) => print('${log.arguments} -> ${log.result}'),
);

void main() async {
  await f(21); // 21 -> 42
}
```

**Real world**

```dart
final transferMoney = Func2<String, String, TransferResult>((from, to) async {
  return await ledger.transfer(from, to) as TransferResult;
}).audit(
  onAudit: (log) {
    if (log.isFailure) {
      complianceLogger.record('Transfer failed', log);
    }
  },
  maxLogs: 1000,
);

await transferMoney('alice', 'bob');
```

### Best practices

- Set `maxLogs` based on expected call volume and memory budget.
- Use `onAudit` to ship logs to a durable store.

### Common pitfalls

- `audit` is only available on `Func1` and `Func2` (the extension classes are hidden from public API but exposed via the decorator method).
- Errors in `onAudit` are caught and ignored so they do not affect the wrapped function.