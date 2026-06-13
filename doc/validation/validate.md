# Validate

## What it is

`validate` applies a validator to the arguments before execution. If validation fails, the wrapper throws a `ValidationException`.

## When to use it

- Input sanitization and validation at function entry.
- Enforcing domain constraints (e.g., email format, positive amounts).
- Converting validation logic into reusable decorators.

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
Func1<T, R> validate({
  required List<String? Function(T arg)> validators,
  ValidationMode mode = ValidationMode.failFast,
  void Function(List<String> errors)? onValidationError,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> validate({
  required List<String? Function(T1 arg1, T2 arg2)> validators,
  ValidationMode mode = ValidationMode.failFast,
  void Function(List<String> errors)? onValidationError,
});
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `validators` | `List<String? Function(...)>` | Returns `null` if valid, or an error message string if invalid. |
| `mode` | `ValidationMode` | `failFast` or `aggregate`. |
| `onValidationError` | `void Function(List<String>)?` | Called with the errors before throwing. |

## Examples

### Basic example

```dart
final doublePositive = Func1<int, int>((n) async => n * 2).validate(
  validators: [
    (n) => n > 0 ? null : 'must be positive',
  ],
);

print(await doublePositive(5)); // 10
try {
  await doublePositive(-1);
} on ValidationException catch (e) {
  print(e.message); // must be positive
}
```

### Real-world example

```dart
final createUser = Func2<String, String, User>((email, name) async {
  return await userRepo.create(email: email, name: name) as User;
}).validate(
  validators: [
    (email, name) => email.contains('@') ? null : 'invalid email',
    (email, name) => name.isNotEmpty ? null : 'name required',
  ],
);

await createUser('user@example.com', 'Name');
```

## Best practices

- Return clear, actionable error messages.
- Keep validators synchronous and free of side effects.
- Layer multiple validators when order matters.

## Common pitfalls

- **Null return semantics**: Returning `null` means valid; any non-null string is treated as an error.
- **Validators throwing**: If the validator throws, the wrapper propagates that exception, not a `ValidationException`.
