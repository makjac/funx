# Lazy Loading

## What it is

Lazy loading defers execution until the result is first requested. This is the default behavior for most wrapped functions, but the explicit decorator can be combined with others for clarity.

## When to use it

- Expensive resources that may never be needed.
- Avoiding startup cost for optional features.
- Composing with warm up or memoize to control when work happens.

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
Func<R> lazy();

// On Func1<T, R>
Func1<T, R> lazy();

// On Func2<T1, T2, R>
Func2<T1, T2, R> lazy();
```

No parameters.

## Examples

### Basic example

```dart
var calls = 0;
final heavy = Func<int>(() async {
  calls++;
  return 42;
}).lazy();

print('not yet');
await heavy();
print('calls == $calls'); // 1
```

### Real-world example

```dart
final loadHeavyReport = Func<Report>(() async {
  return await reportGenerator.build() as Report;
}).lazy();

void main() async {
  await loadHeavyReport();
}
```

## Best practices

- Combine `lazy` with `memoize` to compute once on demand and cache forever.
- Use `lazy` instead of `warmUp` when the resource may not be needed.
- Be aware that the first call pays the full cost.

## Common pitfalls

- **First-call latency**: Lazy loading shifts cost to the first request, which can surprise callers.
- **Not a separate future per call**: Like `once`, lazy caches the first result.
