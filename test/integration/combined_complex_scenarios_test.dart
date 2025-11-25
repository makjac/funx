/// Complex integration tests combining multiple patterns.
library;

import 'dart:async';

import 'package:funx/funx.dart' hide Func1, Func2;
import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('Complex multi-layer combinations', () {
    test('debounce + retry + memoize + timeout - full stack', () async {
      var attempts = 0;
      final func =
          Func<String>(() async {
                attempts++;
                await Future<void>.delayed(const Duration(milliseconds: 50));
                if (attempts < 2) {
                  throw Exception('Failed');
                }
                return 'success-$attempts';
              })
              .debounce(const Duration(milliseconds: 100))
              .retry(maxAttempts: 3)
              .memoize()
              .timeout(const Duration(seconds: 2));

      final result1 = await func();
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(result1, equals('success-2'));

      // Should use memoized value
      final result2 = await func();
      expect(result2, equals('success-2'));
      expect(attempts, equals(2));
    });

    test(
      'validate + guard + retry + fallback validation and error handling stack',
      () async {
        var attempts = 0;
        final func =
            funx.Func1<int, int>((n) async {
                  attempts++;
                  if (attempts < 2) {
                    throw Exception('Failed');
                  }
                  return n * 2;
                })
                .validate(
                  validators: [
                    (n) => n > 0 ? null : 'Must be positive',
                  ],
                )
                .guard(
                  preCondition: (n) => n < 100,
                  preConditionMessage: 'Must be less than 100',
                )
                .retry(maxAttempts: 3)
                .fallback(fallbackValue: -1);

        // Valid input
        final result1 = await func(5);
        expect(result1, equals(10));

        // Invalid validation
        attempts = 0;
        final result2 = await func(-5);
        expect(result2, equals(-1));

        // Invalid guard
        attempts = 0;
        final result3 = await func(150);
        expect(result3, equals(-1));
      },
    );

    test('lock + semaphore + rate limit - concurrency control stack', () async {
      var executions = 0;
      var maxConcurrent = 0;
      var currentConcurrent = 0;

      final func =
          Func<String>(() async {
                executions++;
                currentConcurrent++;
                maxConcurrent = currentConcurrent > maxConcurrent
                    ? currentConcurrent
                    : maxConcurrent;

                await Future<void>.delayed(const Duration(milliseconds: 100));

                currentConcurrent--;
                return 'result-$executions';
              })
              .lock()
              .semaphore(maxConcurrent: 3)
              .rateLimit(
                maxCalls: 5,
                window: const Duration(milliseconds: 500),
                strategy: RateLimitStrategy.leakyBucket,
              );

      final futures = List.generate(10, (i) => func());
      final results = await Future.wait(futures);

      expect(results.length, equals(10));
      expect(maxConcurrent, lessThanOrEqualTo(3));
    });

    test('share + deduplicate + memoize - caching stack', () async {
      var executions = 0;
      final func = Func<String>(() async {
        executions++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 'result-$executions';
      }).memoize().deduplicate(window: const Duration(seconds: 1)).share();

      // Multiple concurrent calls
      final futures = [func(), func(), func()];
      final results = await Future.wait(futures);

      // All should get the same result
      expect(results.every((r) => r == results.first), isTrue);
      expect(executions, equals(1)); // Only one execution
    });

    test(
      'circuit breaker + retry + fallback + timeout - resilience stack',
      () async {
        final breaker = CircuitBreaker(
          failureThreshold: 2,
          timeout: const Duration(seconds: 2),
        );

        var attempts = 0;
        final func =
            Func<String>(() async {
                  attempts++;
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                  throw Exception('Service unavailable');
                })
                .timeout(const Duration(seconds: 1))
                .retry(maxAttempts: 2)
                .circuitBreaker(breaker)
                .fallback(fallbackValue: 'fallback');

        // First call - retries then returns fallback
        final result1 = await func();
        expect(result1, equals('fallback'));

        // Circuit should open after failures
        final result2 = await func();
        expect(result2, equals('fallback'));

        expect(attempts, greaterThan(0));
      },
    );

    test('debounce + throttle + delay - timing control stack', () async {
      var executions = 0;

      final func =
          Func<String>(() async {
                executions++;
                return 'result-$executions';
              })
              .delay(const Duration(milliseconds: 50))
              .throttle(
                const Duration(milliseconds: 200),
                mode: ThrottleMode.trailing,
              )
              .debounce(const Duration(milliseconds: 100));

      // Trigger execution
      unawaited(func());
      unawaited(func());
      unawaited(func());

      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Should execute at least once after all delays and debounce
      expect(executions, greaterThan(0));
    });

    test('memoize + lock + retry - cached retries with locking', () async {
      var attempts = 0;
      final func = Func<String>(() async {
        attempts++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (attempts < 2) {
          throw Exception('Failed');
        }
        return 'success';
      }).retry(maxAttempts: 3).lock().memoize();

      // First call - retries and succeeds
      final result1 = await func();
      expect(result1, equals('success'));
      expect(attempts, equals(2));

      // Second call - uses memoized value
      final result2 = await func();
      expect(result2, equals('success'));
      expect(attempts, equals(2)); // No new attempts
    });

    test(
      'validate + timeout + fallback - validation with time limits',
      () async {
        final func =
            funx.Func1<String, String>((email) async {
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                  return 'Sent to $email';
                })
                .validate(
                  validators: [
                    (email) => email.contains('@') ? null : 'Invalid email',
                  ],
                )
                .timeout(const Duration(seconds: 1))
                .fallback(fallbackValue: 'failed');

        // Valid email
        final result1 = await func('test@example.com');
        expect(result1, contains('Sent'));

        // Invalid email
        final result2 = await func('invalid');
        expect(result2, equals('failed'));
      },
    );

    test('guard + memoize + lock - guarded cached execution', () async {
      var executions = 0;
      final func =
          funx.Func1<int, int>((n) async {
                executions++;
                await Future<void>.delayed(const Duration(milliseconds: 50));
                return n * 2;
              })
              .guard(
                preCondition: (n) => n >= 0,
                preConditionMessage: 'Must be non-negative',
              )
              .memoize()
              .lock();

      // Concurrent valid calls
      final futures = [func(5), func(5), func(10)];
      final results = await Future.wait(futures);

      expect(results, equals([10, 10, 20]));
      expect(executions, equals(2)); // Two unique inputs, memoized
    });

    test('rate limit + deduplicate + retry - controlled retries', () async {
      var attempts = 0;
      final func =
          Func<String>(() async {
                attempts++;
                if (attempts < 2) {
                  throw Exception('Failed');
                }
                return 'success';
              })
              .retry(maxAttempts: 3)
              .deduplicate(window: const Duration(milliseconds: 500))
              .rateLimit(
                maxCalls: 5,
                window: const Duration(milliseconds: 300),
              );

      final result1 = await func();
      expect(result1, equals('success'));

      // Within deduplication window
      final result2 = await func();
      expect(result2, equals('success'));
    });
  });

  group('Real-world scenarios', () {
    test('API call with full resilience stack', () async {
      final breaker = CircuitBreaker(failureThreshold: 3);
      var callCount = 0;

      // Simulate an API call
      final apiCall =
          funx.Func1<String, Map<String, dynamic>>((endpoint) async {
                callCount++;
                await Future<void>.delayed(const Duration(milliseconds: 100));

                // Simulate occasional failures
                if (callCount % 5 == 0) {
                  throw Exception('Server error');
                }

                return {
                  'data': 'result from $endpoint',
                  'timestamp': DateTime.now().toString(),
                };
              })
              .timeout(const Duration(seconds: 5))
              .retry(
                maxAttempts: 3,
                backoff: const ExponentialBackoff(
                  initialDelay: Duration(milliseconds: 100),
                ),
              )
              .circuitBreaker(breaker)
              .memoize(ttl: const Duration(minutes: 5))
              .rateLimit(maxCalls: 10, window: const Duration(seconds: 1))
              .fallback(
                fallbackValue: {'data': 'cached', 'timestamp': 'unknown'},
              );

      // Make multiple calls
      final results = await Future.wait([
        apiCall('/users'),
        apiCall('/posts'),
        apiCall('/users'), // Should be memoized
      ]);

      expect(results.length, equals(3));
      expect(results[0]['data'], contains('users'));
      expect(results[2]['data'], contains('users')); // Memoized
    });

    test('Database write with concurrency control', () async {
      final operations = <String>[];

      final dbWrite =
          funx.Func2<String, String, bool>((table, data) async {
                operations.add('Writing to $table: $data');
                await Future<void>.delayed(const Duration(milliseconds: 50));
                return true;
              })
              .validate(
                validators: [
                  (table, data) => table.isNotEmpty ? null : 'Table required',
                  (table, data) => data.isNotEmpty ? null : 'Data required',
                ],
              )
              .lock() // Ensure serial writes
              .retry(maxAttempts: 3)
              .timeout(const Duration(seconds: 5))
              .fallback(fallbackValue: false);

      final results = await Future.wait([
        dbWrite('users', 'John'),
        dbWrite('posts', 'Hello'),
        dbWrite('users', 'Jane'),
      ]);

      expect(results.every((r) => r), isTrue);
      expect(operations.length, equals(3));
    });

    test('Search with debounce and caching', () async {
      var searchCount = 0;

      final search =
          funx.Func1<String, List<String>>((query) async {
                searchCount++;
                await Future<void>.delayed(const Duration(milliseconds: 100));
                return ['result1-$query', 'result2-$query', 'result3-$query'];
              })
              .debounce(const Duration(milliseconds: 300))
              .memoize(
                ttl: const Duration(minutes: 5),
                maxSize: 100,
              )
              .timeout(const Duration(seconds: 10));

      // Rapid typing simulation
      unawaited(search('a'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      unawaited(search('ap'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      unawaited(search('app'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final results = await search('appl');

      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(results.length, equals(3));
      expect(searchCount, equals(1)); // Only last search executed

      // Same query again - should use cache
      final cachedResults = await search('appl');
      expect(cachedResults, equals(results));
      expect(searchCount, equals(1)); // Still one search
    });

    test('Background task with queue and monitoring', () async {
      final monitor = Monitor();
      final processedTasks = <String>[];

      final processTask =
          funx.Func1<String, void>((task) async {
                processedTasks.add(task);
                await Future<void>.delayed(const Duration(milliseconds: 100));
              })
              .monitor(monitor)
              .retry(maxAttempts: 2)
              .timeout(const Duration(seconds: 5));

      // Process multiple tasks
      final tasks = List.generate(5, (i) => 'task-$i');
      final futures = tasks.map(processTask.call).toList();

      await Future.wait(futures);

      expect(processedTasks.length, equals(5));
    });

    test('Cache warmup with memoization', () async {
      var loadCount = 0;
      final dataLoader = Func<String>(() async {
        loadCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 'data-version-$loadCount';
      }).memoize(ttl: const Duration(milliseconds: 200)).warmUp();

      // Wait for warmup
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result1 = await dataLoader();
      expect(result1, contains('data-version'));
      expect(loadCount, equals(1)); // Warmed up

      // Within TTL - should use cache
      final result2 = await dataLoader();
      expect(result2, equals(result1));
      expect(loadCount, equals(1)); // Still cached
    });
  });
}
