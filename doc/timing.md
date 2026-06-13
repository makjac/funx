# Timing

Timing decorators control *when* a function executes. Use them to debounce search inputs, throttle button clicks, add deliberate delays, or enforce deadlines.

---

## debounce

### What it is

Delays execution until a specified duration has passed without a new call. Each new call cancels the pending execution and restarts the timer.

### When to use it

- Search-as-you-type
- Resize handlers
- Any event that fires rapidly and only the final state matters

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> debounce(Duration duration, {DebounceMode mode = DebounceMode.trailing})
```

- `duration` — quiet period required before execution.
- `mode` — `trailing` (default), `leading`, or `both`.
- `cancel()` — cancels the pending execution and resets state.

`DebounceMode`:

- `trailing` — execute after the quiet period.
- `leading` — execute immediately on the first call, ignore subsequent calls until the window resets.
- `both` — execute on the first call and again after the quiet period.

### Examples

**Minimal**

```dart
final search = Func<String>(() async => 'results')
  .debounce(Duration(milliseconds: 300));

void main() async {
  search();
  search();
  print(await search()); // Only the last call runs after 300ms
}
```

**Real world**

```dart
final searchUsers = Func1<String, List<User>>((query) async {
  return (await api.searchUsers(query)) as List<User>;
}).debounce(
  Duration(milliseconds: 300),
  mode: DebounceMode.trailing,
);

// Later:
await searchUsers('kim');
```

### Best practices

- Use `trailing` for search inputs; use `leading` for actions where the first click matters.
- Always handle the `StateError` thrown by `leading` mode when called inside the debounce window.

### Common pitfalls

- `leading` mode throws `StateError('Function is debounced')` if called again inside the window.
- For `Func`, `DebounceMode.both` schedules a trailing execution only after a leading execution has occurred; the implementation differs subtly from `Func1`/`Func2`.

---

## throttle

### What it is

Limits execution to at most once per duration. Unlike debounce, throttle enforces a minimum interval between executions.

### When to use it

- Button clicks
- Scroll events
- API calls that must stay under a rate limit

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> throttle(Duration duration, {ThrottleMode mode = ThrottleMode.leading})
```

- `duration` — minimum time between executions.
- `mode` — `leading` (default), `trailing`, or `both`.
- `reset()` — clears the last execution time and pending trailing execution.

`ThrottleMode`:

- `leading` — execute immediately, block calls inside the window.
- `trailing` — schedule execution at the end of the window.
- `both` — execute immediately and again at window end.

### Examples

**Minimal**

```dart
final submit = Func<String>(() async => 'ok')
  .throttle(Duration(seconds: 1));

void main() async {
  print(await submit()); // ok
  try {
    await submit(); // throws inside window
  } on StateError catch (e) {
    print(e);
  }
}
```

**Real world**

```dart
final updateLocation = Func1<Location, void>((location) async {
  await api.updateLocation(location);
}).throttle(
  Duration(seconds: 5),
  mode: ThrottleMode.leading,
);

// Usage:
await updateLocation(Location());
```

### Best practices

- Use `leading` for actions that should respond immediately.
- Use `trailing` when you want the latest call inside a window to win.

### Common pitfalls

- `leading` mode throws `StateError('Function is throttled')` when called inside the throttle window.
- `both` mode returns the leading result and schedules a trailing execution as a side effect; callers awaiting the trailing call need a separate handle.

---

## delay

### What it is

Inserts a pause before and/or after function execution.

### When to use it

- Pacing API calls
- UI animations
- Adding breathing room between retries

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> delay(Duration duration, {DelayMode mode = DelayMode.before})
```

`DelayMode`:

- `before` — wait before calling the function.
- `after` — wait after the function completes.
- `both` — wait before and after.

### Examples

**Minimal**

```dart
final slow = Func<String>(() async => 'done')
  .delay(Duration(milliseconds: 500));

void main() async {
  print(await slow()); // waits 500ms, prints done
}
```

**Real world**

```dart
final poll = Func<Status>(() async => (await api.status()) as Status)
  .delay(Duration(seconds: 2), mode: DelayMode.after)
  .repeat(times: 10);

await poll();
```

### Best practices

- Combine `delay` with `repeat` for simple polling loops.
- Prefer `debounce` or `throttle` over `delay` when you need to coalesce rapid calls.

### Common pitfalls

- `delay` is per-call; it does not serialize calls or enforce a global rate.

---

## timeout

### What it is

Enforces a maximum execution time. If the wrapped function does not complete within the duration, a `TimeoutException` is thrown (unless an `onTimeout` callback is provided).

### When to use it

- Network requests
- Long-running computations
- Any operation that could hang

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> timeout(
  Duration duration, {
  FutureOr<R> Function()? onTimeout,
})
```

- `duration` — maximum time allowed.
- `onTimeout` — optional callback returning a fallback value instead of throwing.

### Examples

**Minimal**

```dart
final fetch = Func<String>(() async {
  await Future<void>.delayed(Duration(seconds: 2));
  return 'data';
}).timeout(Duration(milliseconds: 100));

void main() async {
  try {
    await fetch();
  } on TimeoutException {
    print('timed out');
  }
}
```

**Real world**

```dart
final fetchProfile = Func1<String, Profile>((id) async {
  return (await api.getProfile(id)) as Profile;
}).timeout(
  Duration(seconds: 5),
  onTimeout: () async => Profile(),
);

await fetchProfile('user-123');
```

### Best practices

- Place `timeout` carefully in decorator chains; wrapping `retry` with `timeout` gives a global deadline.
- Provide `onTimeout` for non-critical paths to avoid exceptions.

### Common pitfalls

- `timeout` does not cancel the underlying future; the wrapped work continues in the background.
- Without `onTimeout`, `TimeoutException` is thrown.

---

## defer

### What it is

Lazily evaluates the function the first time the returned `Future` is awaited. Multiple awaits on the same future execute only once.

### When to use it

- Expensive initialization that may never be needed
- Lazy singleton construction
- Deferring work until a value is actually consumed

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> asDeferred()
```

### Examples

**Minimal**

```dart
final lazy = Func<String>(() async {
  print('computing');
  return 'value';
}).asDeferred();

void main() async {
  final f1 = lazy();
  final f2 = lazy();
  print(await f1); // computing, value
  print(await f2); // value (no recomputation)
}
```

**Real world**

```dart
final heavyConfig = Func<Config>(() async => configRepository.load() as Config)
  .asDeferred();

final config = await heavyConfig();
print(config);
```

### Best practices

- Use `defer` when the caller may or may not need the result.
- Combine with `memoize` if the result should be cached beyond the first future.

### Common pitfalls

- Errors are cached too: if the deferred computation fails, the same error is returned on subsequent awaits.

---

## idleCallback

### What it is

Executes the function only when an `IdleDetector` returns `true`. By default the detector always returns `true`, so the decorator is mainly useful with a custom detector.

### When to use it

- Background tasks that should run only when the app/device is idle
- Non-urgent cleanup or prefetching

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
Func<R> idleCallback({
  Duration checkInterval = Duration(milliseconds: 100),
  IdleDetector idleDetector = defaultIdleDetector,
})
```

- `checkInterval` — how often to poll the detector.
- `idleDetector` — `bool Function()` returning `true` when idle.

### Examples

**Minimal**

```dart
bool idle = false;

final task = Func<String>(() async => 'done').idleCallback(
  idleDetector: () => idle,
);

void main() async {
  idle = true;
  print(await task());
}
```

**Real world**

```dart
var cpuLoad = 0.1;
var networkMetered = false;

final prefetch = Func<Recommendations>(() async {
  return (await api.fetchRecommendations()) as Recommendations;
}).idleCallback(
  checkInterval: Duration(seconds: 1),
  idleDetector: () => cpuLoad < 0.2 && !networkMetered,
);

await prefetch();
```

### Best practices

- Keep the detector cheap; it is polled repeatedly.
- Use a reasonable `checkInterval` to avoid busy-waiting.

### Common pitfalls

- If the detector never returns `true`, the call hangs indefinitely.