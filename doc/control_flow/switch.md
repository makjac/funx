# Switch

## What it is

`SwitchExtension` is a standalone multi-branch control-flow wrapper. It evaluates the selector and executes the matching branch, or a default branch if none match.

## When to use it

- Replacing long `if/else if` chains.
- Routing events to handlers based on type or value.
- Configurable strategy selection.

## API reference

```dart
// api-reference
class SwitchExtension1<T, R> {
  SwitchExtension1({
    required Object? Function(T arg) selector,
    required Map<Object?, Func1<T, R>> cases,
    Func1<T, R>? defaultCase,
  });

  Future<R> call(T arg);
}

class SwitchExtension2<T1, T2, R> {
  SwitchExtension2({
    required Object? Function(T1 arg1, T2 arg2) selector,
    required Map<Object?, Func2<T1, T2, R>> cases,
    Func2<T1, T2, R>? defaultCase,
  });

  Future<R> call(T1 arg1, T2 arg2);
}
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `selector` | `Object? Function(T)` | Returns a value matched against `cases` keys. |
| `cases` | `Map<Object?, Func1<T, R>>` | Map of selector values to function branches. |
| `defaultCase` | `Func1<T, R>?` | Optional branch used when no case matches. |

## Examples

### Basic example

```dart
final classify = SwitchExtension1<int, String>(
  selector: (n) => n < 0 ? 'negative' : n == 0 ? 'zero' : 'other',
  cases: {
    'negative': Func1<int, String>((n) async => 'negative'),
    'zero': Func1<int, String>((n) async => 'zero'),
  },
  defaultCase: Func1<int, String>((n) async => 'positive'),
);

print(await classify(-3)); // negative
print(await classify(0)); // zero
print(await classify(7)); // positive
```

### Real-world example

```dart
final handleEvent = SwitchExtension1<String, void>(
  selector: (event) => event,
  cases: {
    'login': Func1<String, void>((e) async => auth.login(e)),
    'logout': Func1<String, void>((e) async => auth.logout()),
  },
  defaultCase: Func1<String, void>((e) async => analytics.track(e)),
);

await handleEvent('login');
```

## Best practices

- Order cases from most specific to least specific.
- Provide a `defaultCase` unless you want unmatched inputs to throw.
- Keep predicates side-effect free.

## Common pitfalls

- **Case order matters**: The first matching case wins; overlapping predicates can hide later branches.
- **No default case**: If no predicate matches and there is no default, the switch throws.
