# Debounce

## What it is

Debounce delays execution until a specified quiet period has passed since the most recent call. If the function keeps being invoked, the timer resets and the execution is postponed again.

## When to use it

- Search-as-you-type input fields that should only query the server after the user stops typing.
- Form validation that should run after the user pauses editing.
- Resize or scroll event handlers that should fire only after the burst of events ends.

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
Func<R> debounce(
  Duration duration, {
  DebounceMode mode = DebounceMode.trailing,
});

// On Func1<T, R>
Func1<T, R> debounce(
  Duration duration, {
  DebounceMode mode = DebounceMode.trailing,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> debounce(
  Duration duration, {
  DebounceMode mode = DebounceMode.trailing,
});

enum DebounceMode { trailing, leading, both }
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `duration` | `Duration` | required | Quiet period required before execution. |
| `mode` | `DebounceMode` | `trailing` | When to execute: `trailing`, `leading`, or `both`. |

### Returned wrapper methods

```dart
// api-reference
void cancel(); // Cancels the pending timer.
```

### Modes

- `trailing` (default): executes once after the quiet period, using the last arguments.
- `leading`: executes immediately on the first call and ignores subsequent calls until the window expires.
- `both`: executes immediately on the first call and again after the quiet period.

## Examples

### Basic example

```dart
var callCount = 0;
final search = Func1<String, String>((query) async {
  callCount++;
  return 'Results for: $query';
}).debounce(Duration(milliseconds: 50));

search('a');
search('ab');
search('abc');

await Future<void>.delayed(Duration(milliseconds: 100));
print('calls: $callCount'); // 1
```

### Real-world example

```dart
final searchApi = Func1<String, List<SearchResult>>(
  (query) async => api.search(query) as List<SearchResult>,
).debounce(
  Duration(milliseconds: 300),
  mode: DebounceMode.trailing,
);

await searchApi('query');

// In a text-field onChanged listener:
// searchApi(query);
```

## Best practices

- Use `trailing` for server requests so you only send the final value.
- Use `leading` for actions that should respond immediately to the first user gesture.
- Keep `duration` short enough to feel responsive but long enough to avoid excessive calls.
- Call `cancel()` when the widget is disposed to prevent stale executions.

## Common pitfalls

- **Assuming every call returns a value**: In trailing mode only the last call's future resolves with the result; earlier futures may resolve to the same last result depending on implementation. Prefer treating debounced calls as fire-and-forget or awaiting the final one.
- **Forgetting to dispose**: A pending debounce timer can call your function after the screen is gone.
- **Using `leading` for network calls**: This can cause a request on every first keystroke, which is usually not desired.
