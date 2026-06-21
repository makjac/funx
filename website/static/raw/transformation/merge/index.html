# Merge

## What it is

`MergeExtension` combines multiple functions into a single function whose result aggregates the results of all sources.

## When to use it

- Running several independent queries and combining their results.
- Parallel fan-out where you need all outputs.
- Composing multiple validators or enrichers.

## API reference

```dart
// api-reference
class MergeExtension1<T, R> {
  MergeExtension1(
    List<Func1<T, dynamic>> sources, {
    required R Function(List<dynamic> results) combiner,
  });

  Future<R> call(T arg);
}

class MergeExtension2<T1, T2, R> {
  MergeExtension2(
    List<Func2<T1, T2, dynamic>> sources, {
    required R Function(List<dynamic> results) combiner,
  });

  Future<R> call(T1 arg1, T2 arg2);
}
```

### Parameters

| Parameter | Type | Description |
|---|---|---|
| `sources` | `List<Func1<T, dynamic>>` | Functions to execute in parallel. |
| `combiner` | `R Function(List<dynamic>)` | Combines all source results into a single result. |

## Examples

### Basic example

```dart
final merge = MergeExtension1<int, int>(
  [
    Func1<int, int>((n) async => n + 1),
    Func1<int, int>((n) async => n * 2),
  ],
  combiner: (results) => results.cast<int>().reduce((a, b) => a + b),
);

print(await merge(3)); // (3 + 1) + (3 * 2) == 10
```

### Real-world example

```dart
final enrichUser = MergeExtension1<String, UserProfile>(
  [
    Func1<String, UserProfile>((id) async => await profileApi.get(id) as UserProfile),
    Func1<String, UserProfile>((id) async => await preferencesApi.get(id) as UserProfile),
  ],
  combiner: (profiles) => UserProfile(),
);

await enrichUser('123');
```

## Best practices

- Keep targets independent; `Merge` runs them concurrently.
- Make the merger handle result ordering deterministically.
- Combine with `catchError` on individual targets if partial failure is acceptable.

## Common pitfalls

- **One failure fails all**: If any target throws, the merge throws. Wrap targets individually if you need resilience.
- **Merger assumptions**: The merger receives results in the same order as `targets`.
