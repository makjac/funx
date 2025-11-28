import 'dart:async';

import 'package:funx/funx.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('README Examples - Basic Usage', () {
    test('debounce example', () async {
      var callCount = 0;
      final search = funx.Func1<String, String>((query) async {
        callCount++;
        return 'Results for: $query';
      }).debounce(const Duration(milliseconds: 50));

      unawaited(search('a'));
      unawaited(search('ab'));
      unawaited(search('abc'));

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(callCount, equals(1));
    });

    test('throttle example', () async {
      var callCount = 0;
      final trackScroll = funx.Func1<double, void>((position) async {
        callCount++;
      }).throttle(const Duration(milliseconds: 50));

      await trackScroll(100);
      expect(() => trackScroll(200), throwsStateError); // Will be throttled
      expect(() => trackScroll(300), throwsStateError); // Will be throttled

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(callCount, equals(1));
    });

    test('retry example', () async {
      var attempts = 0;
      final fetchData = funx.Func<String>(() async {
        attempts++;
        if (attempts < 3) throw Exception('Network error');
        return 'Success';
      }).retry(maxAttempts: 3);

      final result = await fetchData();
      expect(result, equals('Success'));
      expect(attempts, equals(3));
    });

    test('circuit breaker example', () async {
      final breaker = funx.CircuitBreaker(
        failureThreshold: 3,
        timeout: const Duration(seconds: 1),
      );

      var callCount = 0;
      final riskyOperation = funx.Func<String>(() async {
        callCount++;
        throw Exception('Service unavailable');
      }).circuitBreaker(breaker);

      // First 3 calls should fail and open the circuit
      for (var i = 0; i < 3; i++) {
        try {
          await riskyOperation();
        } catch (_) {}
      }

      expect(breaker.state, equals(funx.CircuitBreakerState.open));
      expect(callCount, equals(3));

      // Next call should fail immediately without calling the function
      try {
        await riskyOperation();
      } catch (_) {}
      expect(callCount, equals(3)); // Still 3, not incremented
    });

    test('memoize example', () async {
      var callCount = 0;
      final square = funx.Func1<int, int>((n) async {
        callCount++;
        return n * n;
      }).memoize();

      final result1 = await square(10);
      final firstCallCount = callCount;

      final result2 = await square(10);
      expect(result2, equals(result1));
      expect(callCount, equals(firstCallCount)); // No additional calls
    });
  });

  group('README Examples - Core Concepts', () {
    test('Func basic usage', () async {
      final greet = funx.Func1<String, String>((name) async => 'Hello, $name!');
      final result = await greet('World');
      expect(result, equals('Hello, World!'));
    });

    test('chaining decorators', () async {
      var callCount = 0;
      final processPayment =
          funx.Func1<double, String>((amount) async {
                callCount++;
                if (amount <= 0) throw ArgumentError('Invalid amount');
                return 'Processed: \$$amount';
              })
              .retry(maxAttempts: 3)
              .debounce(const Duration(milliseconds: 50))
              .memoize();

      unawaited(processPayment(100));
      unawaited(processPayment(100));

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(callCount, equals(1));
    });
  });

  group('README Examples - Timing', () {
    test('debounce prevents rapid calls', () async {
      var executionCount = 0;
      final search = funx.Func1<String, String>((query) async {
        executionCount++;
        return 'Results for: $query';
      }).debounce(const Duration(milliseconds: 50));

      unawaited(search('a'));
      unawaited(search('ab'));
      unawaited(search('abc'));

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(executionCount, equals(1));
    });

    test('throttle limits execution rate', () async {
      var executionCount = 0;
      final trackScroll =
          funx.Func1<double, void>((position) async {
            executionCount++;
          }).throttle(
            const Duration(milliseconds: 100),
            mode: funx.ThrottleMode.trailing,
          );

      for (var i = 0; i < 10; i++) {
        unawaited(trackScroll(i * 100.0));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      // Wait for final trailing execution
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Should be much less than 10 calls
      expect(executionCount, lessThan(5));
    });

    test('timeout throws on slow operations', () async {
      final slowOperation = funx.Func<String>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return 'Done';
      }).timeout(const Duration(milliseconds: 50));

      expect(slowOperation.call, throwsA(isA<TimeoutException>()));
    });
  });

  group('README Examples - Concurrency', () {
    test('lock ensures sequential execution', () async {
      var counter = 0;
      final incrementCounter = funx.Func<void>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        counter++;
      }).lock();

      await Future.wait([
        incrementCounter(),
        incrementCounter(),
        incrementCounter(),
      ]);

      expect(counter, equals(3));
    });

    test('semaphore limits concurrent executions', () async {
      var concurrentCount = 0;
      var maxConcurrent = 0;

      final task = funx.Func<void>(() async {
        concurrentCount++;
        maxConcurrent = concurrentCount > maxConcurrent
            ? concurrentCount
            : maxConcurrent;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        concurrentCount--;
      }).semaphore(maxConcurrent: 2);

      await Future.wait([
        task(),
        task(),
        task(),
        task(),
      ]);

      expect(maxConcurrent, equals(2));
    });
  });

  group('README Examples - Reliability', () {
    test('retry with exponential backoff', () async {
      var attempts = 0;
      final fetchData =
          funx.Func<String>(() async {
            attempts++;
            if (attempts < 3) throw Exception('Network error');
            return 'Success';
          }).retry(
            maxAttempts: 5,
            backoff: const funx.ExponentialBackoff(
              initialDelay: Duration(milliseconds: 10),
              maxDelay: Duration(milliseconds: 100),
            ),
          );

      final result = await fetchData();
      expect(result, equals('Success'));
      expect(attempts, equals(3));
    });

    test('circuit breaker opens after failures', () async {
      final breaker = funx.CircuitBreaker(
        failureThreshold: 3,
        timeout: const Duration(milliseconds: 100),
      );

      var callCount = 0;
      final unreliableService = funx.Func<String>(() async {
        callCount++;
        throw Exception('Service down');
      }).circuitBreaker(breaker);

      // Cause failures to open circuit
      for (var i = 0; i < 3; i++) {
        try {
          await unreliableService();
        } catch (_) {}
      }

      expect(breaker.state, equals(funx.CircuitBreakerState.open));

      // This call should fail fast without calling the function
      final beforeCount = callCount;
      try {
        await unreliableService();
      } catch (_) {}
      expect(callCount, equals(beforeCount));
    });

    test('fallback provides alternative on error', () async {
      final getDataWithFallback = funx.Func<String>(() async {
        throw Exception('API error');
      }).fallback(fallbackValue: 'Cached data');

      final result = await getDataWithFallback();
      expect(result, equals('Cached data'));
    });
  });

  group('README Examples - Performance', () {
    test('memoize caches results', () async {
      var callCount = 0;
      final expensiveOperation = funx.Func1<int, int>((n) async {
        callCount++;
        return n * n;
      }).memoize();

      final result1 = await expensiveOperation(5);
      expect(result1, equals(25));
      expect(callCount, equals(1));

      final result2 = await expensiveOperation(5);
      expect(result2, equals(25));
      expect(callCount, equals(1)); // Not incremented
    });

    test('batch processes multiple items together', () async {
      final processItems =
          funx.Func1<int, int>((item) async {
            return item * 2;
          }).batch(
            maxSize: 3,
            maxWait: const Duration(milliseconds: 50),
            executor: funx.Func1<List<int>, void>((List<int> items) async {
              // Process batch - no return value needed
            }),
          );

      final futures = [
        processItems(1),
        processItems(2),
        processItems(3),
      ];

      await Future<void>.delayed(const Duration(milliseconds: 100));
      final results = await Future.wait(futures);

      expect(results, equals([2, 4, 6]));
    });

    test('rate limit controls execution frequency', () async {
      var executionCount = 0;
      final apiCall =
          funx.Func<String>(() async {
            executionCount++;
            return 'API response';
          }).rateLimit(
            maxCalls: 2,
            window: const Duration(milliseconds: 100),
          );

      // Make 5 calls
      final futures = List.generate(5, (_) => apiCall());

      // First 2 should execute immediately
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(executionCount, equals(2));

      // Wait for rate limit to reset
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Remaining calls should execute
      await Future.wait(futures);
      expect(executionCount, equals(5));
    });

    test('deduplicate prevents duplicate sequential calls', () async {
      var callCount = 0;
      const testId = '123';
      final fetchData = funx.Func<String>(() async {
        callCount++;
        return 'Data for $testId';
      }).deduplicate(window: const Duration(milliseconds: 100));

      // Make sequential calls within window
      final result1 = await fetchData();
      final result2 = await fetchData();
      final result3 = await fetchData();

      // All should return same result
      expect(result1, equals('Data for $testId'));
      expect(result2, equals('Data for $testId'));
      expect(result3, equals('Data for $testId'));
      expect(callCount, equals(1)); // Only called once
    });

    test('share shares single execution among multiple callers', () async {
      var callCount = 0;
      final loadConfig = funx.Func<Map<String, String>>(() async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return {'setting': 'value'};
      }).share();

      final futures = [
        loadConfig(),
        loadConfig(),
        loadConfig(),
      ];

      await Future.wait(futures);
      expect(callCount, equals(1)); // Only called once
    });
  });

  group('README Examples - Error Handling', () {
    test('catchError handles specific errors', () async {
      final riskyOperation =
          funx.Func<String>(() async {
            throw const FormatException('Invalid format');
          }).catchError(
            handlers: {
              FormatException: (error) async => 'Handled format error',
            },
          );

      final result = await riskyOperation();
      expect(result, equals('Handled format error'));
    });

    test('catchError propagates unhandled errors', () async {
      final riskyOperation =
          funx.Func<String>(() async {
            throw StateError('Wrong state');
          }).catchError(
            handlers: {
              FormatException: (error) async => 'Handled format error',
            },
          );

      expect(riskyOperation.call, throwsStateError);
    });
  });

  group('README Examples - Validation', () {
    test('guard validates preconditions', () async {
      final processAge = funx.Func1<int, String>((age) async {
        return 'Age: $age';
      }).guard(preCondition: (age) => age >= 0 && age <= 150);

      final result = await processAge(25);
      expect(result, equals('Age: 25'));

      expect(() => processAge(-5), throwsA(isA<funx.GuardException>()));
      expect(() => processAge(200), throwsA(isA<funx.GuardException>()));
    });
  });

  group('README Examples - Observability', () {
    test('tap observes function execution', () async {
      final logs = <String>[];

      final processOrder =
          funx.Func1<String, String>((orderId) async {
            return 'Processed: $orderId';
          }).tap(
            onValue: (result) => logs.add('Result: $result'),
            onError: (error, _) => logs.add('Error: $error'),
          );

      final result = await processOrder('ORD-123');

      expect(result, equals('Processed: ORD-123'));
      expect(logs, contains('Result: Processed: ORD-123'));
    });

    test('tap observes errors', () async {
      final logs = <String>[];

      final failingOperation =
          funx.Func<String>(() async {
            throw Exception('Oops');
          }).tap(
            onError: (error, _) => logs.add('Error caught'),
          );

      try {
        await failingOperation();
      } catch (_) {}

      expect(logs, contains('Error caught'));
    });
  });

  group('README Examples - Common Patterns', () {
    test('API client with multiple decorators', () async {
      final breaker = funx.CircuitBreaker(
        failureThreshold: 3,
        timeout: const Duration(seconds: 1),
      );

      var callCount = 0;
      final apiCall =
          funx.Func1<String, String>((endpoint) async {
                callCount++;
                if (callCount < 2) throw Exception('Network error');
                return 'Response from $endpoint';
              })
              .retry(maxAttempts: 3)
              .circuitBreaker(breaker)
              .timeout(const Duration(seconds: 5))
              .memoize();

      final result = await apiCall('/users');
      expect(result, equals('Response from /users'));
      expect(callCount, equals(2)); // First call failed, second succeeded

      // Second call should use memoized result
      final result2 = await apiCall('/users');
      expect(result2, equals('Response from /users'));
      expect(callCount, equals(2)); // Not incremented
    });

    test('search with debounce and cache', () async {
      var searchCount = 0;
      final search = funx.Func1<String, String>((query) async {
        searchCount++;
        return 'Results for: $query';
      }).debounce(const Duration(milliseconds: 50)).memoize();

      unawaited(search('test'));
      unawaited(search('test'));
      unawaited(search('test'));

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(searchCount, equals(1));

      // Cached result
      final result = await search('test');
      expect(result, equals('Results for: test'));
      expect(searchCount, equals(1)); // Still 1
    });

    test('rate-limited concurrent operations', () async {
      var concurrentCount = 0;
      var maxConcurrent = 0;

      final processTask =
          funx.Func1<int, String>((id) async {
                concurrentCount++;
                maxConcurrent = concurrentCount > maxConcurrent
                    ? concurrentCount
                    : maxConcurrent;
                await Future<void>.delayed(const Duration(milliseconds: 50));
                concurrentCount--;
                return 'Task $id completed';
              })
              .semaphore(maxConcurrent: 2)
              .rateLimit(maxCalls: 5, window: const Duration(seconds: 1));

      final futures = List.generate(4, processTask.call);
      await Future.wait(futures);

      expect(maxConcurrent, equals(2)); // Semaphore limit
    });

    test('resilient data fetcher', () async {
      final breaker = funx.CircuitBreaker(
        failureThreshold: 2,
        timeout: const Duration(milliseconds: 100),
      );

      var attempts = 0;
      final fetchData =
          funx.Func1<String, String>((id) async {
                attempts++;
                if (attempts == 1) throw Exception('Network error');
                return 'Data for $id';
              })
              .retry(maxAttempts: 2)
              .circuitBreaker(breaker)
              .fallback(fallbackValue: 'Cached data')
              .timeout(const Duration(seconds: 5));

      final result = await fetchData('123');
      expect(result, equals('Data for 123'));
      expect(attempts, equals(2)); // Retry worked
    });
  });

  group('README Examples - Edge Cases', () {
    test('retry exhausts attempts', () async {
      var attempts = 0;
      final alwaysFails = funx.Func<String>(() async {
        attempts++;
        throw Exception('Always fails');
      }).retry(maxAttempts: 3);

      try {
        await alwaysFails();
      } catch (_) {}
      expect(attempts, equals(3));
    });

    test('circuit breaker half-open state', () async {
      final breaker = funx.CircuitBreaker(
        failureThreshold: 2,
        successThreshold: 1, // Only 1 success needed to close
        timeout: const Duration(milliseconds: 100),
      );

      var callCount = 0;
      final service = funx.Func<String>(() async {
        callCount++;
        if (callCount <= 2) throw Exception('Fail');
        return 'Success';
      }).circuitBreaker(breaker);

      // Open the circuit
      for (var i = 0; i < 2; i++) {
        try {
          await service();
        } catch (_) {}
      }
      expect(breaker.state, equals(funx.CircuitBreakerState.open));

      // Wait for half-open
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(breaker.state, equals(funx.CircuitBreakerState.halfOpen));

      // Successful call should close circuit
      final result = await service();
      expect(result, equals('Success'));
      expect(breaker.state, equals(funx.CircuitBreakerState.closed));
    });

    test('memoize with different arguments', () async {
      var callCount = 0;
      final calculate = funx.Func2<int, int, int>((x, y) async {
        callCount++;
        return x + y;
      }).memoize();

      await calculate(1, 2);
      await calculate(1, 2); // Cached
      await calculate(2, 3); // Different args, not cached
      await calculate(1, 2); // Cached again

      expect(callCount, equals(2)); // Only 2 unique calls
    });
  });
}
