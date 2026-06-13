# Race

## What it is

`race` runs multiple functions concurrently and returns the result of the first one to complete. The remaining futures are ignored.

## When to use it

- Trying several equivalent data sources and using the fastest response.
- Timeout patterns when combined with a timed fallback.
- Competitive probes.

## Async / sync support

| Wrapper | Support |
|---|---|
| `Func1<T, R>` | ✅ Async |
| `Func2<T1, T2, R>` | ✅ Async |

## API reference

```dart
// api-reference
// On Func1<T, R>
Func1<T, R> race(List<Func1<T, R>> competitors);

// On Func2<T1, T2, R>
Func2<T1, T2, R> race(List<Func2<T1, T2, R>> competitors);
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `competitors` | `List<Func1<T, R>>` or `List<Func2<T1, T2, R>>` | Functions to race against each other. |

## Examples

### Basic example

```dart
final fast = Func1<int, String>((n) async {
  await Future<void>.delayed(Duration(milliseconds: 10));
  return 'fast';
});
final slow = Func1<int, String>((n) async {
  await Future<void>.delayed(Duration(milliseconds: 100));
  return 'slow';
});

final racer = fast.race(competitors: [slow]);
print(await racer(0)); // fast
```

### Real-world example

```dart
final fetchQuote = Func1<String, Quote>(
  (symbol) async => await primaryApi.quote(symbol) as Quote,
).race(competitors: [
  Func1<String, Quote>((symbol) async => await secondaryApi.quote(symbol) as Quote),
  Func1<String, Quote>((symbol) async => await backupExchange.quote(symbol) as Quote),
]);

final quote = await fetchQuote('AAPL');
print(quote);
```

## Best practices

- Ensure all competitors return the same type.
- Be aware that losers continue running in the background; cancel them if they hold resources.
- Combine with `fallback` if all competitors might fail.

## Common pitfalls

- **Resource leaks**: Losing competitors are not automatically cancelled.
- **First error wins**: If the first future to complete is an error, `race` returns that error even if others would succeed.
