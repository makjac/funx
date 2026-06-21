# Validation

Validation decorators check inputs before executing the wrapped function.

---

## validate

### What it is

Validates arguments using one or more validator functions before passing them to the wrapped function.

### When to use it

- Input sanitization
- Business-rule enforcement
- Form/API validation

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ❌ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func1<T, R> validate({
  required List<String? Function(T arg)> validators,
  ValidationMode mode = ValidationMode.failFast,
  void Function(List<String> errors)? onValidationError,
})
```

For `Func2`:

```dart
// api-reference
Func2<T1, T2, R> validate({
  required List<String? Function(T1 arg1, T2 arg2)> validators,
  ValidationMode mode = ValidationMode.failFast,
  void Function(List<String> errors)? onValidationError,
})
```

`ValidationMode`:

- `failFast` — stop at the first error.
- `aggregate` — collect all errors before throwing.

Throws `ValidationException` on failure.

### Examples

**Minimal**

```dart
final parse = Func1<String, int>((s) async => int.parse(s)).validate(
  validators: [
    (s) => s.isNotEmpty ? null : 'Empty',
    (s) => int.tryParse(s) != null ? null : 'Not a number',
  ],
  mode: ValidationMode.aggregate,
);

void main() async {
  try {
    await parse('x');
  } on ValidationException catch (e) {
    print(e.errors); // [Not a number]
  }
}
```

**Real world**

```dart
final createUser = Func2<String, String, User>((email, password) async {
  return await authApi.createUser(email, password) as User;
}).validate(
  validators: [
    (email, password) => email.contains('@') ? null : 'Invalid email',
    (email, password) => password.length >= 8 ? null : 'Password too short',
  ],
  mode: ValidationMode.aggregate,
  onValidationError: (errors) => logger.info('Validation failed: $errors'),
);

await createUser('user@example.com', 'password123');
```

### Best practices

- Use `aggregate` for user-facing forms to report all issues at once.
- Keep validators pure and fast.

### Common pitfalls

- At least one validator is required; empty list triggers an assertion.
- `validate` is only available on `Func1` and `Func2`.

---

## guard

### What it is

Enforces pre-conditions and post-conditions around execution.

### When to use it

- Defensive programming
- Invariant checking
- Contract validation

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> guard({
  List<bool Function()> preCondition = const [],
  List<bool Function(R result)> postCondition = const [],
  String preConditionMessage = 'Pre-condition failed',
  String postConditionMessage = 'Post-condition failed',
})
```

For `Func1`:

```dart
// api-reference
Func1<T, R> guard({
  List<bool Function(T arg)> preCondition = const [],
  List<bool Function(R result)> postCondition = const [],
  ...
})
```

For `Func2`:

```dart
// api-reference
Func2<T1, T2, R> guard({
  List<bool Function(T1 arg1, T2 arg2)> preCondition = const [],
  List<bool Function(R result)> postCondition = const [],
  ...
})
```

Throws `GuardException` on failure.

### Examples

**Minimal**

```dart
final divide = Func2<int, int, double>((a, b) async => a / b).guard(
  preCondition: (a, b) => b != 0,
  postCondition: (result) => result.isFinite,
);

void main() async {
  try {
    await divide(1, 0);
  } on GuardException catch (e) {
    print(e.message); // Pre-condition failed
  }
}
```

**Real world**

```dart
final withdraw = Func2<String, double, void>((accountId, amount) async {
  await bankApi.withdraw(accountId, amount);
}).guard(
  preCondition: (accountId, amount) => accountId.isNotEmpty && amount > 0,
  postCondition: (_) => true,
);

await withdraw('account-123', 100.0);
```

### Best practices

- Use guards for invariants that should never be violated in production.
- Provide clear custom messages for debugging.

### Common pitfalls

- At least one condition is required.
- Post-conditions run after the function succeeds; they do not run if the function throws.