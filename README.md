![header][header_image_url]

[![pub package][pub_package_badge]][pub_package_url] [![pub likes][pub_likes_badge]][pub_likes_link] [![style: very good analysis][very_good_analysis_badge]][very_good_analysis_url] [![License: MIT][license_badge]][license_badge_link]

# Funx

Function execution control library for Dart and Flutter. Provides decorators for managing timing, concurrency, reliability, and performance of asynchronous and synchronous functions.

## Purpose

Funx addresses the complexity of implementing reliable, performant function execution patterns in Dart/Flutter applications. Instead of manually implementing retry logic, debouncing, rate limiting, or circuit breakers, developers wrap functions with composable decorators.

This package is useful when building applications that require:

- Controlled API request execution with retry and circuit breaker patterns
- User input handling with debouncing and throttling
- Concurrent operation management with locks and semaphores
- Fault-tolerant network operations with fallback strategies
- Performance optimization through caching, batching, and memoization
- Observable function execution with metrics and audit trails

## Features

### Core Functionality

- Function wrapper with composable decorators
- Support for async (`Future<T>`), sync (`T`), and parameterized functions
- Three wrapper types: `Func<R>`, `Func1<T, R>`, `Func2<T1, T2, R>`
- Zero external dependencies

### Mechanism Categories

- **Timing** (6): debounce, throttle, delay, timeout, defer, idle callback
- **Concurrency** (8): lock, read-write lock, semaphore, queue, bulkhead, barrier, countdown latch, monitor
- **Reliability** (5): retry, backoff strategies, circuit breaker, fallback, recovery
- **Performance** (10): rate limiting, batching, memoization, cache-aside, compression, deduplication, sharing, once, warm-up, lazy loading
- **Error Handling** (2): catch, default value
- **Validation** (2): guard, validate
- **Transformation** (3): proxy, transform, merge
- **Control Flow** (3): switch, conditional, repeat
- **Orchestration** (3): race, all, saga
- **Observability** (3): tap, monitor, audit
- **State** (1): snapshot

Total: 46 mechanisms across 11 categories

## Basic Usage

### Debounce - Search Autocomplete

```dart
import 'package:funx/funx.dart';

var callCount = 0;
final search = Func1<String, String>((query) async {
  callCount++;
  return 'Results for: $query';
}).debounce(Duration(milliseconds: 50));

search('a');
search('ab');
search('abc');

await Future.delayed(Duration(milliseconds: 100));
// callCount == 1 (only last call executed)
```

### Throttle - Button Clicks

```dart
var callCount = 0;
final trackScroll = Func1<double, void>((position) async {
  callCount++;
}).throttle(Duration(milliseconds: 50));

await trackScroll(100);
expect(() => trackScroll(200), throwsStateError); // Throttled
expect(() => trackScroll(300), throwsStateError); // Throttled

// callCount == 1 (first call executed, others rejected)
```

### Retry - Network Requests

```dart
var attempts = 0;
final fetchData = Func<String>(() async {
  attempts++;
  if (attempts < 3) throw Exception('Network error');
  return 'Success';
}).retry(maxAttempts: 3);

final result = await fetchData();
// result == 'Success', attempts == 3
```

### Circuit Breaker - Failing Services

```dart
final breaker = CircuitBreaker(
  failureThreshold: 3,
  timeout: Duration(seconds: 1),
);

var callCount = 0;
final riskyOperation = Func<String>(() async {
  callCount++;
  throw Exception('Service unavailable');
}).circuitBreaker(breaker);

// After 3 failures, circuit opens
for (var i = 0; i < 3; i++) {
  try { await riskyOperation(); } catch (_) {}
}

// breaker.state == CircuitBreakerState.open
// Next calls fail immediately without executing function
```

### Memoize - Caching Results

```dart
var callCount = 0;
final square = Func1<int, int>((n) async {
  callCount++;
  return n * n;
}).memoize();

final result1 = await square(10);
final result2 = await square(10);
// callCount == 1 (second call uses cached result)
```

## Core Concepts

### Func Wrapper Types

Funx provides three wrapper types based on the number of parameters:

```dart
// No parameters
final greet = Func<String>(() async => 'Hello, World!');
final result = await greet();

// One parameter  
final processAge = Func1<int, String>((age) async => 'Age: $age');
final output = await processAge(25);

// Two parameters
final calculate = Func2<int, int, int>((x, y) async => x + y);
final sum = await calculate(1, 2);
```

### Chaining Decorators

Decorators can be chained to combine multiple behaviors:

```dart
var callCount = 0;
final processPayment = Func1<double, String>((amount) async {
  callCount++;
  if (amount <= 0) throw ArgumentError('Invalid amount');
  return 'Processed: \$$amount';
})
  .retry(maxAttempts: 3)
  .debounce(Duration(milliseconds: 50))
  .memoize();

processPayment(100);
processPayment(100);

await Future.delayed(Duration(milliseconds: 100));
// callCount == 1 (debounced and memoized)
```

### Execution Order

Decorators execute in reverse order (last applied executes first):

```dart
final fn = Func<String>(() async => await operation())
  .retry()      // 3. Executes third
  .timeout()    // 2. Executes second
  .tap(onValue: (v) => print(v));  // 1. Executes first
```

## Mechanism Categories

### Timing

Control when functions execute:

```dart
// Debounce - delay until calls stop
var executionCount = 0;
final search = Func1<String, String>((query) async {
  executionCount++;
  return 'Results for: $query';
}).debounce(Duration(milliseconds: 50));

search('a');
search('ab');
search('abc');

await Future.delayed(Duration(milliseconds: 100));
// executionCount == 1 (only last call executed)

// Throttle - limit execution frequency (trailing mode)
var execCount = 0;
final trackScroll = Func1<double, void>((position) async {
  execCount++;
}).throttle(
  Duration(milliseconds: 100),
  mode: ThrottleMode.trailing,
);

for (var i = 0; i < 10; i++) {
  trackScroll(i * 100.0);
  await Future.delayed(Duration(milliseconds: 20));
}
// execCount < 5 (throttled to reduce frequency)

// Timeout - cancel after duration
final slowOperation = Func<String>(() async {
  await Future.delayed(Duration(milliseconds: 200));
  return 'Done';
}).timeout(Duration(milliseconds: 50));

// Throws TimeoutException
```

### Concurrency

Manage parallel execution:

```dart
// Lock - mutual exclusion (ensures sequential execution)
var counter = 0;
final incrementCounter = Func<void>(() async {
  await Future.delayed(Duration(milliseconds: 10));
  counter++;
}).lock();

await Future.wait([
  incrementCounter(),
  incrementCounter(),
  incrementCounter(),
]);
// counter == 3 (all executed sequentially)

// Semaphore - limit concurrent executions
var concurrentCount = 0;
var maxConcurrent = 0;

final task = Func<void>(() async {
  concurrentCount++;
  maxConcurrent = max(concurrentCount, maxConcurrent);
  await Future.delayed(Duration(milliseconds: 50));
  concurrentCount--;
}).semaphore(maxConcurrent: 2);

await Future.wait([
  task(), task(), task(), task(),
]);
// maxConcurrent == 2 (never more than 2 concurrent)
```

### Reliability

Build resilient operations:

```dart
// Retry with exponential backoff
var attemptCount = 0;
final unreliableOp = Func<String>(() async {
  attemptCount++;
  if (attemptCount < 3) throw Exception('Fail');
  return 'success';
}).retry(
  maxAttempts: 5,
  backoff: ExponentialBackoff(
    initialDelay: Duration(milliseconds: 10),
    maxDelay: Duration(milliseconds: 100),
  ),
);

final result = await unreliableOp(); // 'success' after 3 attempts

// Circuit Breaker - prevent cascading failures
final apiCall = Func<String>(() async {
  throw Exception('Service down');
}).circuitBreaker(
  failureThreshold: 3,
  successThreshold: 1,
  timeout: Duration(milliseconds: 100),
);

// First 3 calls fail and open the circuit
for (var i = 0; i < 3; i++) {
  try { await apiCall(); } catch (_) {}
}

// Circuit is now OPEN - fails fast
try {
  await apiCall();
} catch (e) {
  // Throws immediately without calling function
}

// Fallback - provide alternative value
final fetchConfig = Func<Map<String, dynamic>>(() async {
  throw Exception('Config service unavailable');
}).fallback(
  fallbackValue: {'mode': 'default'},
);

final config = await fetchConfig(); // {'mode': 'default'}
```

### Performance

Optimize execution:

```dart
// Memoize - cache results
var callCount = 0;
final expensiveOp = Func1<int, int>((n) async {
  callCount++;
  await Future.delayed(Duration(milliseconds: 10));
  return n * 2;
}).memoize();

await expensiveOp(5); // callCount: 1
await expensiveOp(5); // callCount: 1 (cached)
await expensiveOp(10); // callCount: 2 (different arg)

// Batch - group operations
final results = <int>[];
final batchOp = Func1<int, void>((value) async {
  await Future.delayed(Duration(milliseconds: 5));
  results.add(value);
}).batch(
  executor: (values) async {
    await Future.delayed(Duration(milliseconds: 10));
    results.addAll(values);
  },
);

batchOp(1);
batchOp(2);
await Future.delayed(Duration(milliseconds: 50));
// results contains [1, 2] from batched execution

// Rate limit - control throughput
var executionCount = 0;
final rateLimitedOp = Func<void>(() async {
  executionCount++;
}).rateLimit(
  maxCalls: 2,
  window: Duration(milliseconds: 100),
);

rateLimitedOp();
rateLimitedOp();
rateLimitedOp(); // This one waits or throws depending on strategy

// Deduplicate - prevent duplicate sequential calls
var duplicateCallCount = 0;
final deduplicatedOp = Func1<String, String>((input) async {
  duplicateCallCount++;
  return input.toUpperCase();
}).deduplicate(window: Duration(milliseconds: 100));

deduplicatedOp('test');
await Future.delayed(Duration(milliseconds: 10));
deduplicatedOp('test'); // Ignored (duplicate within window)
await Future.delayed(Duration(milliseconds: 50));
// duplicateCallCount == 1

// Share - share single execution among concurrent callers
var sharedCallCount = 0;
final sharedOp = Func<String>(() async {
  sharedCallCount++;
  await Future.delayed(Duration(milliseconds: 50));
  return 'result';
}).share();

await Future.wait([
  sharedOp(),
  sharedOp(),
  sharedOp(),
]);
// sharedCallCount == 1 (all three calls shared one execution)
```

### Error Handling

Transform and handle errors:

```dart
// Catch specific exceptions
final riskyOp = Func<String>(() async {
  throw ArgumentError('Invalid input');
}).catchError(
  handlers: {
    ArgumentError: (e, stack) => 'handled: ${e.message}',
  },
);

final result = await riskyOp(); // 'handled: Invalid input'

// Catch any exception with default handler
final anyErrorOp = Func<int>(() async {
  throw Exception('Something went wrong');
}).catchError(
  handlers: {},
  defaultHandler: (e, stack) => 42,
);

final value = await anyErrorOp(); // 42
```

### Validation

Validate conditions before execution:

```dart
// Guard - validate preconditions
var guardCallCount = 0;
final guardedOp = Func1<int, String>((value) async {
  guardCallCount++;
  return 'Processed: $value';
}).guard(
  preCondition: (value) => value > 0,
);

try {
  await guardedOp(-5); // Throws GuardException
} catch (e) {
  // guardCallCount == 0 (function not called due to failed guard)
}

final result = await guardedOp(10); // 'Processed: 10'
// guardCallCount == 1
```

### Observability

Monitor and inspect execution:

```dart
// Tap - observe values without changing them
var tapValue = '';
var tapError = '';

final tappedOp = Func<String>(() async {
  return 'success';
}).tap(
  onValue: (result) => tapValue = result,
  onError: (error, stack) => tapError = error.toString(),
);

final result = await tappedOp(); 
// result == 'success'
// tapValue == 'success'

// Tap with errors
final errorOp = Func<String>(() async {
  throw Exception('fail');
}).tap(
  onValue: (result) => tapValue = result,
  onError: (error, stack) => tapError = error.toString(),
);

try {
  await errorOp();
} catch (e) {
  // tapError == 'Exception: fail'
}
```

## Common Patterns

### API Client with Resilience

```dart
final breaker = CircuitBreaker(
  failureThreshold: 3,
  timeout: Duration(seconds: 1),
);

var callCount = 0;
final apiCall = Func1<String, String>((endpoint) async {
  callCount++;
  if (callCount < 2) throw Exception('Network error');
  return 'Response from $endpoint';
})
  .retry(maxAttempts: 3)
  .circuitBreaker(breaker)
  .timeout(Duration(seconds: 5))
  .memoize();

final result = await apiCall('/users');
// result: 'Response from /users'
// callCount: 2 (first failed, retry succeeded)

final result2 = await apiCall('/users');
// result2: 'Response from /users' (from cache)
// callCount: still 2
```

### Search with Debounce and Cache

```dart
var searchCount = 0;
final search = Func1<String, String>((query) async {
  searchCount++;
  return 'Results for: $query';
})
  .debounce(Duration(milliseconds: 50))
  .memoize();

search('test');
search('test');
search('test');

await Future.delayed(Duration(milliseconds: 100));
// searchCount: 1 (debounced to single call)

final result = await search('test');
// result: 'Results for: test'
// searchCount: still 1 (cached)
```

### Rate-Limited Concurrent Operations

```dart
var concurrentCount = 0;
var maxConcurrent = 0;

final processTask = Func1<int, String>((id) async {
  concurrentCount++;
  maxConcurrent = max(concurrentCount, maxConcurrent);
  await Future.delayed(Duration(milliseconds: 50));
  concurrentCount--;
  return 'Task $id completed';
})
  .semaphore(maxConcurrent: 2)
  .rateLimit(maxCalls: 5, window: Duration(seconds: 1));

final futures = List.generate(4, processTask.call);
await Future.wait(futures);

// maxConcurrent: 2 (semaphore limited concurrency)
```

### Resilient Data Fetcher

```dart
final breaker = CircuitBreaker(
  failureThreshold: 2,
  timeout: Duration(milliseconds: 100),
);

var attempts = 0;
final fetchData = Func1<String, String>((id) async {
  attempts++;
  if (attempts == 1) throw Exception('Network error');
  return 'Data for $id';
})
  .retry(maxAttempts: 2)
  .circuitBreaker(breaker)
  .fallback(fallbackValue: 'Cached data')
  .timeout(Duration(seconds: 5));

final result = await fetchData('123');
// result: 'Data for 123'
// attempts: 2 (retry worked)
```

## Custom Extensions

Create custom decorators by extending `Func`:

```dart
extension RequestIdDecorator<R> on Func<R> {
  Func<R> withRequestId() {
    return Func<R>(() async {
      final requestId = _generateId();
      print('[Request $requestId] Starting');
      
      try {
        final result = await call();
        print('[Request $requestId] Success');
        return result;
      } catch (e) {
        print('[Request $requestId] Error: $e');
        rethrow;
      }
    });
  }
  
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

// Usage
final apiCall = Func<String>(() async => await api.fetch())
  .withRequestId()
  .retry(maxAttempts: 3);
```

### Pattern for Custom Decorators

```dart
extension CustomDecorator<R> on Func<R> {
  Func<R> customBehavior() {
    return Func<R>(() async {
      // 1. Pre-processing
      print('Pre-processing...');
      
      // 2. Execute original function
      try {
        final result = await call();
        
        // 3. Post-processing
        print('Post-processing: $result');
        return result;
        
      } catch (e) {
        // 4. Error handling
        print('Error handling: $e');
        rethrow;
      } finally {
        // 5. Cleanup
        print('Cleanup');
      }
    });
  }
}

// Usage
final operation = Func<String>(() async => 'done')
  .customBehavior();
```

### Synchronous Decorators

```dart
extension CustomSyncDecorator<R> on FuncSync<R> {
  FuncSync<R> withLogging() {
    return FuncSync<R>(() {
      print('Executing function');
      final result = call();
      print('Result: $result');
      return result;
    });
  }
}
```

## Testing

### Basic Testing

```dart
import 'package:test/test.dart';
import 'package:funx/funx.dart';

test('debounce delays execution', () async {
  var count = 0;
  final fn = Func<int>(
    () async => ++count,
  ).debounce(Duration(milliseconds: 100));
  
  unawaited(fn());
  unawaited(fn());
  final future = fn();
  
  await Future.delayed(Duration(milliseconds: 150));
  final result = await future;
  
  expect(result, 1); // only last call executed
  expect(count, 1);
});
```

### Testing Retry Logic

```dart
test('retry with backoff', () async {
  var attempts = 0;
  
  final fn = Func<String>(() async {
    attempts++;
    if (attempts < 3) throw Exception('Fail');
    return 'Success';
  }).retry(
    maxAttempts: 3,
    backoff: ConstantBackoff(Duration(milliseconds: 50)),
  );
  
  final result = await fn();
  
  expect(result, 'Success');
  expect(attempts, 3);
});
```

### Testing Composition

```dart
test('composed mechanisms', () async {
  var executions = 0;
  
  final fn = Func<String>(() async {
    executions++;
    return 'result';
  })
    .memoize()
    .retry(maxAttempts: 2);
  
  await fn();
  await fn();
  
  expect(executions, 1); // memoized, executed once
});
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

<!-- end:excluded_rules_table -->

<!-- badges -->

[pub_package_badge]: https://img.shields.io/pub/v/funx.svg
[pub_package_url]: https://pub.dev/packages/funx

[pub_likes_badge]: https://img.shields.io/pub/likes/funx
[pub_likes_link]: https://pub.dev/packages/funx

[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_url]: https://pub.dev/packages/very_good_analysis

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_badge_link]: https://opensource.org/licenses/MIT

<!-- images -->

[header_image_url]: https://raw.githubusercontent.com/makjac/images/refs/heads/main/funx/banner.png

<!--
Version: 1.0.0
Last Updated: 2024-11-26
-->
