// ignore_for_file: avoid_print example purpose

import 'dart:async';

import 'package:funx/funx.dart';

// Output:
//
// 🚀 Funx Library Examples

// 📝 Debouncing Example (search autocomplete)
//   Result: Results for: hello
//   API calls made: 1/4 (75% reduction)

// 🎮 Throttling Example (button clicks)
//   Click handled: 1
//   Subsequent click throttled
//   Click handled: 2

// 💾 Memoization Example (expensive calculation)
//   fibonacci(10) = 20 (computed)
//   fibonacci(10) = 20 (cached)
//   Computations: 1/2 (50% cache hit)

// 🔄 Retry Example (flaky API)
//   Result: Success!
//   Attempts: 3/3

// ⚡ Circuit Breaker Example (failing service)
//   Call 1: Failed
//   Call 2: Failed
//   Call 3: Failed
//   Call 4: Circuit open - fast fail
//   Call 5: Circuit open - fast fail
//   Service calls: 3/5 (circuit prevented 2 calls)

// 🔒 Lock Example (concurrent access)
//   Final balance: $10 (expected: $10)

// 🎯 Composition Example (production API call)
//   Result: Data: users
//   Features: memoize + retry + timeout + circuit breaker

void main() async {
  print('🚀 Funx Library Examples\n');

  // 1. Debounce - Rate limiting rapid calls
  await debouncingExample();

  // 2. Throttle - Limit execution frequency
  await throttlingExample();

  // 3. Memoize - Cache expensive computations
  await memoizeExample();

  // 4. Retry - Automatic retry with backoff
  await retryExample();

  // 5. Circuit Breaker - Fail fast pattern
  await circuitBreakerExample();

  // 6. Lock - Mutual exclusion
  await lockExample();

  // 7. Composition - Combine multiple decorators
  await compositionExample();
}

/// Debounce delays execution until calls stop coming
Future<void> debouncingExample() async {
  print('📝 Debouncing Example (search autocomplete)');

  var callCount = 0;
  final search = Func1<String, String>((query) async {
    callCount++;
    return 'Results for: $query';
  }).debounce(const Duration(milliseconds: 300));

  // Simulate rapid typing
  unawaited(search('h')); // ignored
  unawaited(search('he')); // ignored
  unawaited(search('hel')); // ignored
  final result = search('hello'); // this one executes

  await Future<void>.delayed(const Duration(milliseconds: 400));
  print('  Result: ${await result}');
  print('  API calls made: $callCount/4 (75% reduction)\n');
}

/// Throttle ensures minimum time between executions
Future<void> throttlingExample() async {
  print('🎮 Throttling Example (button clicks)');

  var clickCount = 0;
  final handleClick = Func<void>(() async {
    clickCount++;
    print('  Click handled: $clickCount');
  }).throttle(const Duration(milliseconds: 500));

  // Rapid clicks - only first one executes
  await handleClick();
  try {
    await handleClick(); // throws StateError
  } catch (e) {
    print('  Subsequent click throttled');
  }

  await Future<void>.delayed(const Duration(milliseconds: 600));
  await handleClick(); // window expired, executes
  print('');
}

/// Memoize caches function results
Future<void> memoizeExample() async {
  print('💾 Memoization Example (expensive calculation)');

  var computeCount = 0;
  final fibonacci = Func1<int, int>((n) async {
    computeCount++;
    if (n <= 1) return n;
    // Simplified - not recursive for demo
    return n * 2; // Simulated expensive operation
  }).memoize(maxSize: 100);

  // First call - computes
  final result1 = await fibonacci(10);
  print('  fibonacci(10) = $result1 (computed)');

  // Second call - cached
  final result2 = await fibonacci(10);
  print('  fibonacci(10) = $result2 (cached)');
  print('  Computations: $computeCount/2 (50% cache hit)\n');
}

/// Retry automatically retries failed operations
Future<void> retryExample() async {
  print('🔄 Retry Example (flaky API)');

  var attempt = 0;
  final flakyApi =
      Func<String>(() async {
        attempt++;
        if (attempt < 3) {
          throw Exception('Network error');
        }
        return 'Success!';
      }).retry(
        maxAttempts: 3,
        backoff: const ExponentialBackoff(
          initialDelay: Duration(milliseconds: 100),
        ),
      );

  try {
    final result = await flakyApi();
    print('  Result: $result');
    print('  Attempts: $attempt/3\n');
  } catch (e) {
    print('  Failed after 3 attempts\n');
  }
}

/// Circuit Breaker prevents cascading failures
Future<void> circuitBreakerExample() async {
  print('⚡ Circuit Breaker Example (failing service)');

  var callCount = 0;
  final breaker = CircuitBreaker(
    failureThreshold: 3,
    timeout: const Duration(seconds: 5),
  );
  final unstableService = Func<String>(() async {
    callCount++;
    throw Exception('Service unavailable');
  }).circuitBreaker(breaker);

  // First 3 calls fail and open circuit
  for (var i = 0; i < 5; i++) {
    try {
      await unstableService();
    } catch (e) {
      if (i < 3) {
        print('  Call ${i + 1}: Failed');
      } else {
        print('  Call ${i + 1}: Circuit open - fast fail');
      }
    }
  }
  print('  Service calls: $callCount/5 (circuit prevented 2 calls)\n');
}

/// Lock ensures mutual exclusion
Future<void> lockExample() async {
  print('🔒 Lock Example (concurrent access)');

  var balance = 100;
  final withdraw = Func1<int, void>((amount) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    balance -= amount;
  }).lock();

  // Concurrent withdrawals - lock ensures safety
  await Future.wait([
    withdraw(30),
    withdraw(40),
    withdraw(20),
  ]);

  print('  Final balance: \$$balance (expected: \$10)\n');
}

/// Composition combines multiple decorators
Future<void> compositionExample() async {
  print('🎯 Composition Example (production API call)');

  var attempts = 0;
  final breaker = CircuitBreaker();
  final productionApi =
      Func1<String, String>((query) async {
            attempts++;
            if (attempts == 1) throw Exception('Temporary glitch');
            return 'Data: $query';
          })
          .memoize(maxSize: 50) // Cache results
          .retry(maxAttempts: 2) // Retry on failure
          .timeout(const Duration(seconds: 5)) // Prevent hanging
          .circuitBreaker(breaker); // Fail fast if broken

  final result = await productionApi('users');
  print('  Result: $result');
  print('  Features: memoize + retry + timeout + circuit breaker\n');
}
