/// Simple integration tests focusing on 2-utility combinations.
library;

import 'dart:async';

import 'package:funx/funx.dart' hide Func1, Func2;
import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/observability/monitor.dart' as obs;
import 'package:test/test.dart';

void main() {
  group('Memoize + Other', () {
    test('memoize + retry', () async {
      var count = 0;
      final func = funx.Func1<int, int>((n) async {
        count++;
        if (count == 1) throw Exception('fail');
        return n * 2;
      }).retry(maxAttempts: 3).memoize();

      final r1 = await func(5);
      final r2 = await func(5);

      expect(r1, 10);
      expect(r2, 10);
      expect(count, 2); // 1 fail + 1 success = 2 executions total
    });

    test('memoize + timeout', () async {
      final func = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return n * 3;
      }).timeout(const Duration(milliseconds: 100)).memoize();

      final result = await func(7);
      expect(result, 21);
    });

    test('memoize + monitor', () async {
      final func = funx.Func1<int, int>(
        (n) async => n + 5,
      ).memoize().monitorObservability();

      await func(10);
      await func(10);
      await func(20);

      final monitor = func as obs.MonitorExtension1;
      expect(monitor.getMetrics().executionCount, 3);
    });

    test('memoize + circuit breaker', () async {
      var executions = 0;
      final func =
          funx.Func1<int, int>((n) async {
                executions++;
                return n * 2;
              })
              .circuitBreaker(
                CircuitBreaker(
                  failureThreshold: 3,
                  timeout: const Duration(seconds: 5),
                ),
              )
              .memoize();

      await func(5);
      await func(5);

      expect(executions, 1);
    });

    test('memoize + throttle', () async {
      var executions = 0;
      final func = funx.Func1<int, int>((n) async {
        executions++;
        return n + 1;
      }).throttle(const Duration(milliseconds: 100)).memoize();

      await func(1);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await func(1); // Same arg, should be memoized

      expect(executions, 1);
    });
  });

  group('Retry + Other', () {
    test('retry + timeout', () async {
      var attempts = 0;
      final func = funx.Func<int>(() async {
        attempts++;
        if (attempts < 2) throw Exception('fail');
        return attempts;
      }).retry(maxAttempts: 3).timeout(const Duration(seconds: 2));

      final result = await func();
      expect(result, 2);
    });

    test('retry + monitor', () async {
      var attempts = 0;
      final func = funx.Func<String>(() async {
        attempts++;
        if (attempts < 3) throw Exception('fail');
        return 'success';
      }).retry(maxAttempts: 5).monitorObservability();

      final result = await func();
      expect(result, 'success');

      final monitor = func as obs.MonitorExtension;
      expect(monitor.getMetrics().executionCount, 1);
    });

    test('retry + circuit breaker', () async {
      final func = funx.Func<int>(() async => 42)
          .retry(maxAttempts: 3)
          .circuitBreaker(
            CircuitBreaker(
              timeout: const Duration(seconds: 10),
            ),
          );

      final result = await func();
      expect(result, 42);
    });

    test('retry + fallback', () async {
      var attempts = 0;
      final func = funx.Func<int>(() async {
        attempts++;
        throw Exception('always fails');
      }).retry(maxAttempts: 2).fallback(fallbackValue: 100);

      final result = await func();
      expect(result, 100);
      expect(attempts, 2);
    });

    test('retry + debounce', () async {
      var attempts = 0;
      final func = funx.Func1<int, int>((n) async {
        attempts++;
        if (attempts == 1) throw Exception('fail');
        return n * 2;
      }).debounce(const Duration(milliseconds: 50)).retry(maxAttempts: 3);

      final result = await func(5);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(result, 10);
    });
  });

  group('Timeout + Other', () {
    test('timeout + monitor', () async {
      final func = funx.Func<String>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return 'done';
      }).timeout(const Duration(milliseconds: 100)).monitorObservability();

      final result = await func();
      expect(result, 'done');

      final monitor = func as obs.MonitorExtension;
      expect(monitor.getMetrics().executionCount, 1);
    });

    test('timeout + circuit breaker', () async {
      final func =
          funx.Func<int>(() async {
                await Future<void>.delayed(const Duration(milliseconds: 20));
                return 123;
              })
              .timeout(const Duration(milliseconds: 100))
              .circuitBreaker(
                CircuitBreaker(
                  failureThreshold: 3,
                  timeout: const Duration(seconds: 5),
                ),
              );

      final result = await func();
      expect(result, 123);
    });

    test('timeout + fallback', () async {
      final func =
          funx.Func<String>(() async {
                await Future<void>.delayed(const Duration(milliseconds: 200));
                return 'slow';
              })
              .timeout(const Duration(milliseconds: 50))
              .fallback(fallbackValue: 'fallback');

      final result = await func();
      expect(result, 'fallback');
    });

    test('timeout + memoize', () async {
      var executions = 0;
      final func = funx.Func1<int, int>((n) async {
        executions++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return n * 2;
      }).timeout(const Duration(milliseconds: 100)).memoize();

      await func(5);
      await func(5);

      expect(executions, 1);
    });
  });

  group('Circuit Breaker + Other', () {
    test('circuit breaker + monitor', () async {
      final func = funx.Func<String>(() async => 'result')
          .circuitBreaker(
            CircuitBreaker(
              failureThreshold: 3,
              timeout: const Duration(seconds: 5),
            ),
          )
          .monitorObservability();

      final result = await func();
      expect(result, 'result');

      final monitor = func as obs.MonitorExtension;
      expect(monitor.getMetrics().executionCount, 1);
    });

    test('circuit breaker + fallback', () async {
      final breaker = CircuitBreaker(
        failureThreshold: 2,
        timeout: const Duration(milliseconds: 100),
      );

      final func = funx.Func<int>(() async {
        throw Exception('fail');
      }).circuitBreaker(breaker).fallback(fallbackValue: 999);

      // First failures
      await func();
      await func();

      // Should fallback when circuit is open
      final result = await func();
      expect(result, 999);
    });

    test('circuit breaker + debounce', () async {
      final func = funx.Func1<int, int>((n) async => n * 2)
          .circuitBreaker(
            CircuitBreaker(
              failureThreshold: 3,
              timeout: const Duration(seconds: 5),
            ),
          )
          .debounce(const Duration(milliseconds: 50));

      final result = await func(10);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(result, 20);
    });
  });

  group('Lock + Other', () {
    test('lock + retry', () async {
      var attempts = 0;
      final func = funx.Func<int>(() async {
        attempts++;
        if (attempts < 2) throw Exception('fail');
        return attempts;
      }).lock().retry(maxAttempts: 3);

      final result = await func();
      expect(result, 2);
    });

    test('lock + timeout', () async {
      final func = funx.Func<String>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'locked';
      }).lock().timeout(const Duration(milliseconds: 100));

      final result = await func();
      expect(result, 'locked');
    });

    test('lock + monitor', () async {
      final func = funx.Func<int>(
        () async => 999,
      ).lock().monitorObservability();

      await func();
      await func();

      final monitor = func as obs.MonitorExtension;
      expect(monitor.getMetrics().executionCount, 2);
    });

    test('lock + memoize', () async {
      var executions = 0;
      final func = funx.Func1<int, int>((n) async {
        executions++;
        return n * 2;
      }).lock().memoize();

      await func(5);
      await func(5);

      expect(executions, 1);
    });
  });

  group('Semaphore + Other', () {
    test('semaphore + retry', () async {
      var attempts = 0;
      final func = funx.Func<int>(() async {
        attempts++;
        if (attempts < 2) throw Exception('fail');
        return attempts;
      }).semaphore(maxConcurrent: 3).retry(maxAttempts: 3);

      final result = await func();
      expect(result, 2);
    });

    test('semaphore + timeout', () async {
      final func = funx.Func<String>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'concurrent';
      }).semaphore(maxConcurrent: 2).timeout(const Duration(milliseconds: 100));

      final result = await func();
      expect(result, 'concurrent');
    });

    test('semaphore + monitor', () async {
      final func = funx.Func<int>(
        () async => 777,
      ).semaphore(maxConcurrent: 5).monitorObservability();

      await func();

      final monitor = func as obs.MonitorExtension;
      expect(monitor.getMetrics().executionCount, 1);
    });

    test('semaphore + fallback', () async {
      final func = funx.Func<int>(() async {
        throw Exception('fail');
      }).semaphore(maxConcurrent: 2).fallback(fallbackValue: 555);

      final result = await func();
      expect(result, 555);
    });
  });

  group('Queue + Other', () {
    test('queue + monitor', () async {
      final func = funx.Func1<int, int>(
        (n) async => n * 2,
      ).queue(concurrency: 1).monitorObservability();

      final results = await Future.wait([
        func(1),
        func(2),
        func(3),
      ]);

      expect(results, [2, 4, 6]);

      final monitor = func as obs.MonitorExtension1;
      expect(monitor.getMetrics().executionCount, 3);
    });

    test('queue + retry', () async {
      var calls = 0;
      final func = funx.Func1<int, int>((n) async {
        calls++;
        if (calls == 1) throw Exception('fail');
        return n + 10;
      }).queue(concurrency: 1).retry(maxAttempts: 3);

      final result = await func(5);
      expect(result, 15);
    });

    test('queue + timeout', () async {
      final func = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return n * 3;
      }).queue(concurrency: 1).timeout(const Duration(milliseconds: 100));

      final result = await func(7);
      expect(result, 21);
    });

    test('queue + memoize', () async {
      var executions = 0;
      final func = funx.Func1<int, int>((n) async {
        executions++;
        return n * 2;
      }).queue(concurrency: 1).memoize();

      await func(5);
      await func(5);

      expect(executions, 1);
    });
  });

  group('RateLimit + Other', () {
    test('rate limit + monitor', () async {
      final func = funx.Func<int>(() async => 100)
          .rateLimit(maxCalls: 10, window: const Duration(seconds: 1))
          .monitorObservability();

      await func();

      final monitor = func as obs.MonitorExtension;
      expect(monitor.getMetrics().executionCount, 1);
    });

    test('rate limit + retry', () async {
      var attempts = 0;
      final func =
          funx.Func<int>(() async {
                attempts++;
                if (attempts < 2) throw Exception('fail');
                return attempts;
              })
              .rateLimit(maxCalls: 5, window: const Duration(seconds: 1))
              .retry(maxAttempts: 3);

      final result = await func();
      expect(result, 2);
    });

    test('rate limit + timeout', () async {
      final func =
          funx.Func<String>(() async {
                await Future<void>.delayed(const Duration(milliseconds: 20));
                return 'limited';
              })
              .rateLimit(maxCalls: 10, window: const Duration(seconds: 1))
              .timeout(const Duration(milliseconds: 100));

      final result = await func();
      expect(result, 'limited');
    });

    test('rate limit + fallback', () async {
      final func =
          funx.Func<int>(() async {
                throw Exception('fail');
              })
              .rateLimit(maxCalls: 5, window: const Duration(seconds: 1))
              .fallback(fallbackValue: 888);

      final result = await func();
      expect(result, 888);
    });
  });

  group('Debounce + Other', () {
    test('debounce + monitor', () async {
      final func = funx.Func1<int, int>(
        (n) async => n * 2,
      ).debounce(const Duration(milliseconds: 50)).monitorObservability();

      final result = await func(5);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(result, 10);

      final monitor = func as obs.MonitorExtension1;
      expect(monitor.getMetrics().executionCount, greaterThan(0));
    });

    test('debounce + memoize', () async {
      var executions = 0;
      final func = funx.Func1<int, int>((n) async {
        executions++;
        return n + 5;
      }).debounce(const Duration(milliseconds: 50)).memoize();

      final result = await func(10);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(result, 15);
      expect(executions, 1);
    });

    test('debounce + timeout', () async {
      final func =
          funx.Func1<int, int>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 30));
                return n * 4;
              })
              .debounce(const Duration(milliseconds: 50))
              .timeout(const Duration(milliseconds: 200));

      final result = await func(3);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(result, 12);
    });

    test('debounce + fallback', () async {
      final func = funx.Func1<int, int>(
        (n) async {
          throw Exception('fail');
        },
      ).debounce(const Duration(milliseconds: 50)).fallback(fallbackValue: 111);

      final result = await func(5);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(result, 111);
    });
  });

  group('Throttle + Other', () {
    test('throttle + monitor', () async {
      final func = funx.Func1<int, int>(
        (n) async => n + 10,
      ).throttle(const Duration(milliseconds: 100)).monitorObservability();

      await func(5);

      final monitor = func as obs.MonitorExtension1;
      expect(monitor.getMetrics().executionCount, greaterThan(0));
    });

    test('throttle + memoize', () async {
      var executions = 0;
      final func = funx.Func1<int, int>((n) async {
        executions++;
        return n * 3;
      }).throttle(const Duration(milliseconds: 100)).memoize();

      await func(7);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await func(7);

      expect(executions, 1);
    });

    test('throttle + timeout', () async {
      final func =
          funx.Func1<String, String>((s) async {
                await Future<void>.delayed(const Duration(milliseconds: 20));
                return 'throttled-$s';
              })
              .throttle(const Duration(milliseconds: 100))
              .timeout(const Duration(milliseconds: 200));

      final result = await func('test');
      expect(result, 'throttled-test');
    });

    test('throttle + fallback', () async {
      final func =
          funx.Func1<int, int>((n) async {
                throw Exception('fail');
              })
              .throttle(const Duration(milliseconds: 100))
              .fallback(fallbackValue: 222);

      final result = await func(5);
      expect(result, 222);
    });
  });

  group('Fallback + Other', () {
    test('fallback + monitor', () async {
      final func = funx.Func<int>(() async {
        throw Exception('fail');
      }).fallback(fallbackValue: 500).monitorObservability();

      final result = await func();
      expect(result, 500);

      final monitor = func as obs.MonitorExtension;
      expect(monitor.getMetrics().executionCount, 1);
    });

    test('fallback + memoize', () async {
      var executions = 0;
      final func = funx.Func1<int, int>((n) async {
        executions++;
        throw Exception('fail');
      }).fallback(fallbackValue: 999).memoize();

      await func(5);
      await func(5);

      expect(executions, 1);
    });

    test('fallback + timeout', () async {
      final func =
          funx.Func<String>(() async {
                await Future<void>.delayed(const Duration(milliseconds: 200));
                return 'slow';
              })
              .timeout(const Duration(milliseconds: 50))
              .fallback(fallbackValue: 'fallback');

      final result = await func();
      expect(result, 'fallback');
    });

    test('fallback + lock', () async {
      final func = funx.Func<int>(() async {
        throw Exception('fail');
      }).lock().fallback(fallbackValue: 333);

      final result = await func();
      expect(result, 333);
    });
  });

  group('Share + Other', () {
    test('share + monitor', () async {
      var executions = 0;
      final func = funx.Func1<int, int>((n) async {
        executions++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return n * 2;
      }).share().monitorObservability();

      final results = await Future.wait([
        func(5),
        func(5),
        func(5),
      ]);

      expect(results.every((r) => r == 10), isTrue);
      expect(executions, 1);

      final monitor = func as obs.MonitorExtension1;
      expect(monitor.getMetrics().executionCount, 3);
    });

    test('share + timeout', () async {
      final func = funx.Func1<String, String>((input) async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return 'shared-$input';
      }).share().timeout(const Duration(milliseconds: 100));

      final results = await Future.wait([
        func('test'),
        func('test'),
      ]);

      expect(results.every((r) => r == 'shared-test'), isTrue);
    });

    test('share + retry', () async {
      var attempts = 0;
      final func = funx.Func1<int, int>((n) async {
        attempts++;
        if (attempts == 1) throw Exception('fail');
        return n * 2;
      }).share().retry(maxAttempts: 3);

      final result = await func(5);
      expect(result, 10);
    });
  });

  group('Once + Other', () {
    test('once + monitor', () async {
      var executions = 0;
      final func = funx.Func<int>(() async {
        return ++executions;
      }).once().monitorObservability();

      await func();
      await func();

      expect(executions, 1);

      final monitor = func as obs.MonitorExtension;
      expect(monitor.getMetrics().executionCount, 2);
    });

    test('once + timeout', () async {
      final func = funx.Func<String>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'once-only';
      }).once().timeout(const Duration(milliseconds: 100));

      final r1 = await func();
      final r2 = await func();

      expect(r1, 'once-only');
      expect(r2, 'once-only');
    });

    test('once + fallback', () async {
      final func = funx.Func<int>(() async {
        throw Exception('fail');
      }).once().fallback(fallbackValue: 777);

      final r1 = await func();
      final r2 = await func();

      expect(r1, 777);
      expect(r2, 777);
    });
  });

  group('Lazy + Other', () {
    test('lazy + monitor', () async {
      var initCount = 0;
      final func = funx.Func<int>(() async {
        return ++initCount;
      }).lazy().monitorObservability();

      final r1 = await func();
      final r2 = await func();

      expect(r1, 1);
      expect(r2, 2);

      final monitor = func as obs.MonitorExtension;
      expect(monitor.getMetrics().executionCount, 2);
    });

    test('lazy + timeout', () async {
      final func = funx.Func<String>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'lazy-value';
      }).lazy().timeout(const Duration(milliseconds: 100));

      final result = await func();
      expect(result, 'lazy-value');
    });

    test('lazy + retry', () async {
      var attempts = 0;
      final func = funx.Func<int>(() async {
        attempts++;
        if (attempts == 1) throw Exception('fail');
        return attempts;
      }).lazy().retry(maxAttempts: 3);

      final result = await func();
      expect(result, 2);
    });
  });

  group('Transform + Other', () {
    test('transform + monitor', () async {
      final func = funx.Func1<int, int>(
        (n) async => n * 2,
      ).transform((result) => result + 10).monitorObservability();

      final result = await func(5);
      expect(result, 20); // (5 * 2) + 10

      final monitor = func as obs.MonitorExtension1;
      expect(monitor.getMetrics().executionCount, 1);
    });

    test('transform + memoize', () async {
      var executions = 0;
      final func = funx.Func1<int, int>((n) async {
        executions++;
        return n * 3;
      }).transform((result) => result + 1).memoize();

      await func(5);
      await func(5);

      expect(executions, 1);
    });

    test('transform + timeout', () async {
      final func =
          funx.Func1<String, String>((s) async {
                await Future<void>.delayed(const Duration(milliseconds: 20));
                return s.toUpperCase();
              })
              .transform((result) => '$result!')
              .timeout(const Duration(milliseconds: 100));

      final result = await func('test');
      expect(result, 'TEST!');
    });
  });
}
