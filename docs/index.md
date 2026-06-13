# Funx Documentation

**Version:** `1.3.0`  
**Package:** [`funx`](https://pub.dev/packages/funx) — composable async/sync function decorators for Dart.

Funx wraps ordinary functions in small, chainable, reusable building blocks. Each block adds a single concern — timing, concurrency, reliability, caching, observability, and more — without rewriting the function itself.

```dart
const query = 'flutter packages';

final search = Func<List<Result>>(
  () async => (await api.search(query)) as List<Result>,
).debounce(Duration(milliseconds: 300))
  .retry(maxAttempts: 3)
  .timeout(Duration(seconds: 5));

void main() async {
  final results = await search();
  print('Found ${results.length} results');
}
```

## What is a decorator?

A decorator is an extension method on `Func`, `Func1`, or `Func2` (or a standalone class) that wraps the original function and changes *how* it executes. Decorators are composable: you can chain them to combine behaviors.

## Wrapper types

| Wrapper | Signature | Decorators? |
|---------|-----------|-------------|
| `Func<R>` | `Future<R> call()` | Full async decorator set |
| `Func1<T, R>` | `Future<R> call(T arg)` | Full async decorator set |
| `Func2<T1, T2, R>` | `Future<R> call(T1 arg1, T2 arg2)` | Full async decorator set |
| `FuncSync<R>` | `R call()` | Scheduling decorators only |
| `FuncSync1<T, R>` | `R call(T arg)` | None |
| `FuncSync2<T1, T2, R>` | `R call(T1 arg1, T2 arg2)` | None |

`FuncSync*` wrappers exist for API symmetry; most decorators are async-only because they rely on `Future`, `Timer`, or concurrent execution.

## Category map

| Category | Mechanisms | File |
|----------|------------|------|
| [Core](./core.md) | `Func`, `Func1`, `Func2`, `FuncSync*`, `AsyncFunction*`, `SyncFunction*` | [core.md](./core.md) |
| [Timing](./timing.md) | `debounce`, `throttle`, `delay`, `timeout`, `defer`, `idleCallback` | [timing.md](./timing.md) |
| [Concurrency](./concurrency.md) | `lock`, `readLock`/`writeLock`, `semaphore`, `bulkhead`, `barrier`, `countdownLatch`, `monitor`, `queue` | [concurrency.md](./concurrency.md) |
| [Scheduling](./scheduling.md) | `schedule`, `scheduleRecurring`, `scheduleCustom`, `backpressure` | [scheduling.md](./scheduling.md) |
| [Reliability](./reliability.md) | `retry`, `backoff`, `circuitBreaker`, `fallback`, `recover` | [reliability.md](./reliability.md) |
| [Error Handling](./error_handling.md) | `catchError`, `defaultValue` | [error_handling.md](./error_handling.md) |
| [Performance](./performance.md) | `lazy`, `warmUp`, `batch`, `cacheAside`, `priorityQueue`, `rateLimit`, `memoize`, `deduplicate`, `share`, `compress`, `once` | [performance.md](./performance.md) |
| [Observability](./observability.md) | `tap`, `monitorObservability`, `audit` | [observability.md](./observability.md) |
| [State](./state.md) | `snapshot` | [state.md](./state.md) |
| [Validation](./validation.md) | `validate`, `guard` | [validation.md](./validation.md) |
| [Control Flow](./control_flow.md) | `when`, `repeat`, `switch` | [control_flow.md](./control_flow.md) |
| [Transformation](./transformation.md) | `transform`, `merge`, `proxy` | [transformation.md](./transformation.md) |
| [Orchestration](./orchestration.md) | `race`, `all`, `saga` | [orchestration.md](./orchestration.md) |

## Quick start

1. Add to `pubspec.yaml`:

   ```yaml
   dependencies:
     funx: ^1.3.0
   ```

2. Import and wrap a function:

   ```dart
   final fetchUser = Func1<String, User>(
     (id) async => (await api.getUser(id)) as User,
   ).timeout(Duration(seconds: 5))
     .retry(maxAttempts: 3)
     .memoize();

   void main() async {
     final user = await fetchUser('123');
     print(user);
   }
   ```

3. Call it like any async function:

   ```dart
   final fetchUser = Func1<String, User>(
     (id) async => (await api.getUser(id)) as User,
   );

   void main() async {
     final user = await fetchUser('123');
     print(user);
   }
   ```

## How to read the category docs

Each mechanism is documented with the same structure:

- **What it is** — short conceptual overview.
- **When to use it** — typical use cases.
- **Async / sync support** — which wrappers support the decorator.
- **API reference** — public classes, enums, and key members with defaults.
- **Examples** — minimal and real-world snippets.
- **Best practices** — recommended usage.
- **Common pitfalls** — exceptions, edge cases, and gotchas.

## Version note

This documentation targets **funx v1.3.0**. v1.3.0 refactored shared logic into internal engine files (`_timing_engine.dart`, `_reliability_engines.dart`, `_observability_engines.dart`, `_concurrency_engines.dart`) without changing the public API.

## Contributing

Found an inaccuracy? The source of truth is `lib/funx.dart` and the files under `lib/src/`. Open an issue or PR with a reference to the relevant source file.