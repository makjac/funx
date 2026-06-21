# Guard

## What it is

`guard` checks pre-conditions before and/or post-conditions after executing the wrapped function. If a condition returns `false`, the wrapper throws a `GuardException`.

## When to use it

- Enforcing invariants at the function boundary.
- Failing fast when arguments are invalid.
- Authorization checks before running a command.

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
Func<R> guard({
  bool Function()? preCondition,
  bool Function(R result)? postCondition,
  String preConditionMessage = 'Pre-condition failed',
  String postConditionMessage = 'Post-condition failed',
});

// On Func1<T, R>
Func1<T, R> guard({
  bool Function(T arg)? preCondition,
  bool Function(R result)? postCondition,
  String preConditionMessage = 'Pre-condition failed',
  String postConditionMessage = 'Post-condition failed',
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> guard({
  bool Function(T1 arg1, T2 arg2)? preCondition,
  bool Function(R result)? postCondition,
  String preConditionMessage = 'Pre-condition failed',
  String postConditionMessage = 'Post-condition failed',
});
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `preCondition` | `bool Function(...)?` | Checked before execution; must return `true` to proceed. |
| `postCondition` | `bool Function(R)?` | Checked after execution with the result. |
| `preConditionMessage` | `String` | Message used when the pre-condition fails. |
| `postConditionMessage` | `String` | Message used when the post-condition fails. |

## Examples

### Basic example

```dart
final onlyPositive = Func1<int, int>((n) async => n * 2).guard(
  preCondition: (n) => n > 0,
);

print(await onlyPositive(5)); // 10
try {
  await onlyPositive(-1);
} on GuardException {
  print('guarded');
}
```

### Real-world example

```dart
final deleteAccount = Func1<String, void>((userId) async {
  await accounts.delete(userId);
}).guard(preCondition: (_) => currentUser.isAdmin as bool);

await deleteAccount('user-123');
```

## Best practices

- Keep predicates pure and side-effect free.
- Use specific predicates rather than broad checks.
- Combine with `catchError` or `fallback` if guard failures should be handled gracefully.

## Common pitfalls

- **Predicate side effects**: Mutating state inside a guard predicate makes behavior unpredictable.
- **Expensive predicates**: Guards run synchronously before every execution; keep them cheap.
