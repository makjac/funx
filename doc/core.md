# Core

The core layer provides the wrapper classes that every Funx decorator extends. Understanding these wrappers is essential before chaining decorators.

## Func

### What it is

`Func<R>` is a zero-argument async function wrapper. It turns any `Future<R> Function()` into an object that can carry decorators.

### When to use it

- You have an async operation with no inputs (e.g., load config, refresh token, fetch current user).
- You want to apply timing, concurrency, or reliability decorators.

### Async / sync support

`Func<R>` is async-only. For sync equivalents use `FuncSync<R>`.

### API reference

```dart
// api-reference
class Func<R> {
  Func(Future<R> Function() fn);
  Future<R> call();
}
```

All async decorators are available on `Func<R>` unless noted otherwise.

### Examples

**Minimal**

```dart
final greet = Func<String>(() async => 'Hello');

void main() async {
  print(await greet()); // Hello
}
```

**Real world**

```dart
final loadConfig = Func<Config>(() async => (await configLoader.load()) as Config)
  .memoize(ttl: Duration(minutes: 5))
  .timeout(Duration(seconds: 3));

void main() async {
  final config = await loadConfig();
  print(config);
}
```

### Best practices

- Use `Func` for operations whose inputs can be captured by closure rather than parameters.
- Combine `Func` with `memoize` or `once` for expensive initialization.

### Common pitfalls

- `Func` is not a `Function`; you must call it with `await func()`.
- Chaining order matters: `timeout(retry(...))` retries on timeout; `retry(timeout(...))` times out each retry attempt.

---

## Func1

### What it is

`Func1<T, R>` wraps a single-argument async function: `Future<R> Function(T)`.

### When to use it

- The operation depends on one runtime argument (e.g., fetch user by ID, validate email).
- You need arity-specific decorators such as `validate`, `batch`, or `queue`.

### Async / sync support

Async-only. Sync equivalent: `FuncSync1<T, R>`.

### API reference

```dart
// api-reference
class Func1<T, R> {
  Func1(Future<R> Function(T arg) fn);
  Future<R> call(T arg);
}
```

### Examples

**Minimal**

```dart
final doubleIt = Func1<int, int>((n) async => n * 2);

void main() async {
  print(await doubleIt(21)); // 42
}
```

**Real world**

```dart
final fetchUser = Func1<String, User>(
  (id) async => (await api.getUser(id)) as User,
).validate(validators: [(id) => id.isNotEmpty ? null : 'ID required'])
  .retry(maxAttempts: 3)
  .timeout(Duration(seconds: 5));

void main() async {
  final user = await fetchUser('123');
  print(user);
}
```

### Best practices

- Prefer `Func1` over `Func` when the input must be passed at call time.
- Use `Func1` for queue, batch, and backpressure decorators, which are arity-specific.

### Common pitfalls

- `Func1` decorators that rely on argument identity (e.g., `memoize`, `deduplicate`) require stable `==` and `hashCode` for complex types.

---

## Func2

### What it is

`Func2<T1, T2, R>` wraps a two-argument async function: `Future<R> Function(T1, T2)`.

### When to use it

- The operation naturally takes two arguments (e.g., transfer money from A to B, query by ID and limit).

### Async / sync support

Async-only. Sync equivalent: `FuncSync2<T1, T2, R>`.

### API reference

```dart
// api-reference
class Func2<T1, T2, R> {
  Func2(Future<R> Function(T1 arg1, T2 arg2) fn);
  Future<R> call(T1 arg1, T2 arg2);
}
```

### Examples

**Minimal**

```dart
final add = Func2<int, int, int>((a, b) async => a + b);

void main() async {
  print(await add(10, 32)); // 42
}
```

**Real world**

```dart
final transfer = Func2<String, String, TransferResult>(
  (from, to) async => (await ledger.transfer(from, to)) as TransferResult,
).lock(timeout: Duration(seconds: 10));

void main() async {
  final result = await transfer('account-a', 'account-b');
  print(result);
}
```

### Best practices

- Use `Func2` when both arguments are required and independent.
- For more than two arguments, consider a data class and `Func1`.

---

## FuncSync, FuncSync1, FuncSync2

### What it is

Synchronous wrappers that mirror the async API but return values immediately.

### When to use it

- You have pure synchronous logic that still benefits from the Funx API shape.
- You need scheduling decorators (`schedule`, `scheduleRecurring`, `scheduleCustom`), the only decorators available on sync wrappers.

### Async / sync support

Sync-only. No timing, concurrency, or reliability decorators are supported except `schedule()` on `FuncSync<R>`.

### API reference

```dart
// api-reference
class FuncSync<R> {
  FuncSync(R Function() fn);
  R call();
}

class FuncSync1<T, R> {
  FuncSync1(R Function(T arg) fn);
  R call(T arg);
}

class FuncSync2<T1, T2, R> {
  FuncSync2(R Function(T1 arg1, T2 arg2) fn);
  R call(T1 arg1, T2 arg2);
}
```

### Examples

**Minimal**

```dart
final sum = FuncSync2<int, int, int>((a, b) => a + b);

void main() {
  print(sum(10, 32)); // 42
}
```

**Real world**

```dart
void performCleanup() {
  // e.g., prune logs, rotate files
}

final hourlyCleanup = FuncSync<bool>(() {
  performCleanup();
  return true;
}).scheduleRecurring(interval: Duration(hours: 1));

void main() {
  hourlyCleanup.start();
}
```

### Best practices

- Use sync wrappers for deterministic, non-blocking computations.
- Do not wrap I/O in sync wrappers and then schedule them; prefer async wrappers for I/O.

### Common pitfalls

- Calling a `FuncSync` from an async context works, but you cannot await it meaningfully.
- Most decorators silently do not exist on sync wrappers; trying to chain them is a compile-time error.

---

## Plain function extensions

### What it is

Extension methods that apply stateless Funx decorators directly to plain async
functions (`Future<R> Function()`, `Future<R> Function(T)`, and
`Future<R> Function(T1, T2)`) without wrapping them in `Func`, `Func1`, or
`Func2` first.

### When to use it

- You want the most ergonomic API and do not need stateful decorators.
- You are passing functions to libraries that expect plain function types.

### Stateful decorators

Stateful decorators such as `debounce`, `throttle`, `circuitBreaker`,
`memoize`, `monitorObservability`, and `audit` remain `Func`-only. Use the
wrappers above when you need them.

### Examples

**0-argument function**

```dart
Future<String> fetchData() async => 'data';

final decorated = fetchData
  .retry(maxAttempts: 3)
  .timeout(Duration(seconds: 5))
  .fallback(fallbackValue: 'default');

void main() async {
  print(await decorated()); // data
}
```

**1-argument function**

```dart
Future<User> fetchUser(String id) async =>
    (await api.getUser(id)) as User;

final decorated = fetchUser
  .validate(validators: [
    (id) => id.isNotEmpty ? null : 'ID required',
  ])
  .retry(maxAttempts: 3)
  .timeout(Duration(seconds: 5));

void main() async {
  print(await decorated('123'));
}
```

**2-argument function**

```dart
Future<int> add(int a, int b) async => a + b;

final decorated = add
  .guard(preCondition: (a, b) => b != 0)
  .timeout(Duration(seconds: 1));

void main() async {
  print(await decorated(10, 32)); // 42
}
```

---

## Future extensions

### What it is

Convenience decorators for `Future<T>` values.

### When to use it

- You already have a future and want to add a timeout or fallback without
  wrapping the operation in a `Func`.

### Examples

```dart
Future<String> fetchData() async => 'data';

final result = await fetchData()
  .withTimeout(const Duration(seconds: 5))
  .withFallback(fallbackValue: 'default');

print(result);
```

---

## Type aliases

Funx also exports type aliases for plain functions:

```dart
typedef AsyncFunction<R> = Future<R> Function();
typedef AsyncFunction1<T, R> = Future<R> Function(T arg);
typedef AsyncFunction2<T1, T2, R> = Future<R> Function(T1 arg1, T2 arg2);

typedef SyncFunction<R> = R Function();
typedef SyncFunction1<T, R> = R Function(T arg);
typedef SyncFunction2<T1, T2, R> = R Function(T1 arg1, T2 arg2);
```

Use these when you need to declare a function signature without wrapping it in a class.