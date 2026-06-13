# Audit

## What it is

`audit` records every invocation, including arguments and outcome, to an optional callback and an in-memory rolling log. It is available for `Func1` and `Func2`.

## When to use it

- Audit trails for security-sensitive operations.
- Debugging intermittent issues by capturing full call history.
- Compliance logging.

## Async / sync support

| Wrapper | Support |
|---|---|
| `Func<R>` | ❌ No |
| `Func1<T, R>` | ✅ Async |
| `Func2<T1, T2, R>` | ✅ Async |
| `FuncSync<R>` | ❌ No |

## API reference

```dart
// api-reference
// On Func1<T, R>
Func1<T, R> audit({
  void Function(AuditLog<T, R> log)? onAudit,
  int maxLogs = 100,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> audit({
  void Function(AuditLog<(T1, T2), R> log)? onAudit,
  int maxLogs = 100,
});

class AuditLog<T, R> {
  final T arguments;
  final R? result;
  final Object? error;
  final DateTime timestamp;
  final Duration duration;
  bool get isSuccess;
  bool get isFailure;
}
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `onAudit` | `void Function(AuditLog)` | Receives a log for every invocation. |
| `maxLogs` | `int` | Maximum number of logs to retain in memory. |

## Examples

### Basic example

```dart
final logs = <AuditLog<int, int>>[];
final audited = Func1<int, int>((n) async => n * 2).audit(
  onAudit: logs.add,
);

print(await audited(5)); // 10
print(logs.first.arguments); // 5
print(logs.first.result); // 10
```

### Real-world example

```dart
final auditedTransfer = Func2<String, double, void>(
  (account, amount) async {
    await bank.transfer(account, amount);
  },
).audit(
  onAudit: (log) => auditLog.write(
    'transfer',
    input: '${log.arguments.$1}, ${log.arguments.$2}',
    result: log.result,
    error: log.error,
  ),
);

await auditedTransfer('checking', 100.0);
```

## Best practices

- Use an append-only, tamper-evident sink for security audits.
- Avoid logging sensitive data; redact PII inside the sink.
- Keep the sink fast or send records asynchronously.

## Common pitfalls

- **Sensitive data leaks**: Audit records contain raw arguments; sanitize them before storage.
- **Sink failures**: If the sink throws, the wrapper may fail; make it robust.
