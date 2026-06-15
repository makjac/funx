/// Systematic decorator combination tests across all mechanism categories.
library;

import 'dart:async';

import 'package:funx/funx.dart' hide Func1, Func2;
import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/observability/monitor.dart' as obs;

import 'package:test/test.dart';

void main() {
  group('Timing + Reliability', () {
    test('debounce + retry + fallback', () async {
      var attempts = 0;
      final func = funx.Func1<int, int>((n) async {
        attempts++;
        if (attempts < 3) throw Exception('fail');
        return n * 2;
      })
          .debounce(const Duration(milliseconds: 30))
          .retry(maxAttempts: 3)
          .fallback(fallbackValue: -1);

      expect(await func(5), 10);
      expect(attempts, 3);
    });

    test('throttle + circuit breaker + retry', () async {
      final cb = CircuitBreaker(
        failureThreshold: 3,
        timeout: const Duration(milliseconds: 50),
      );
      var count = 0;
      final func = funx.Func1<int, int>((n) async {
        count++;
        if (count <= 2) throw Exception('fail');
        return n;
      }).throttle(const Duration(milliseconds: 10)).retry(maxAttempts: 3)
          .circuitBreaker(cb);

      expect(await func(1), 1);
    });

    test('delay + timeout + retry', () async {
      var count = 0;
      final func = funx.Func<String>(() async {
        count++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        if (count == 1) throw Exception('fail');
        return 'ok';
      })
          .delay(const Duration(milliseconds: 5))
          .timeout(const Duration(milliseconds: 100))
          .retry(maxAttempts: 3);

      expect(await func(), 'ok');
    });

    test('asDeferred + retry + fallback', () async {
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        if (count == 1) throw Exception('fail');
        return 42;
      }).retry(maxAttempts: 2).asDeferred().fallback(fallbackValue: 0);

      expect(await func(), 42);
    });

    test('idleCallback + retry', () async {
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        if (count == 1) throw Exception('fail');
        return 99;
      }).idleCallback().retry(maxAttempts: 2);

      expect(await func(), 99);
    });
  });

  group('Concurrency + Reliability', () {
    test('lock + retry', () async {
      var count = 0;
      final func = funx.Func1<int, int>((n) async {
        count++;
        if (count == 1) throw Exception('fail');
        return n + 1;
      }).retry(maxAttempts: 2).lock();

      final results = await Future.wait<int>([func(1), func(2), func(3)]);
      expect(results, [2, 3, 4]);
    });

    test('semaphore + fallback', () async {
      final func = funx.Func1<int, int>((n) async {
        if (n == 0) throw Exception('fail');
        return n * 10;
      }).semaphore(maxConcurrent: 2).fallback(fallbackValue: -1);

      final results = await Future.wait<int>([func(0), func(1), func(2)]);
      expect(results, [-1, 10, 20]);
    });

    test('bulkhead + retry + circuit breaker', () async {
      final cb = CircuitBreaker(
        failureThreshold: 3,
        timeout: const Duration(milliseconds: 100),
      );
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        if (count <= 2) throw Exception('fail');
        return count;
      }).retry(maxAttempts: 3).bulkhead(poolSize: 1, queueSize: 2)
          .circuitBreaker(cb);

      expect(await func(), 3);
    });

    test('readLock + writeLock + retry', () async {
      final rwLock = RWLock();
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        if (count == 1) throw Exception('fail');
        return count;
      }).retry(maxAttempts: 2).readLock(rwLock);

      expect(await func(), 2);

      final writer = funx.Func<int>(() async => 100)
          .retry(maxAttempts: 2)
          .writeLock(rwLock);
      expect(await writer(), 100);
    });

    test('barrier + fallback', () async {
      final barrier = Barrier(parties: 2);
      final func = funx.Func<int>(() async => throw Exception('fail'))
          .barrier(barrier)
          .fallback(fallbackValue: 0);

      final results = await Future.wait<int>([func(), func()]);
      expect(results, everyElement(0));
    });

    test('countdownLatch + fallback counts down on success', () async {
      final latch = CountdownLatch(count: 1);
      final func = funx.Func<int>(() async => 42)
          .countdownLatch(latch)
          .fallback(fallbackValue: -1);

      expect(await func(), 42);
      expect(latch.isComplete, isTrue);
    });

    test('monitor (concurrency) + retry', () async {
      final monitor = Monitor();
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        if (count == 1) throw Exception('fail');
        return count;
      }).retry(maxAttempts: 2).monitor(monitor);

      expect(await func(), 2);
    });
  });

  group('Validation + Error Handling + Reliability', () {
    test('guard + validate + retry + defaultValue', () async {
      var count = 0;
      final func = funx.Func1<int, int>((n) async {
        count++;
        if (count < 3) throw Exception('fail');
        return n * 2;
      })
          .validate(validators: [(n) => n > 0 ? null : 'positive'])
          .guard(preCondition: (n) => n < 100)
          .retry(maxAttempts: 3)
          .defaultValue(defaultValue: 0);

      expect(await func(5), 10);
      expect(await func(-1), 0);
      expect(await func(200), 0);
    });

    test('validate + catchError + fallback', () async {
      final func = funx.Func1<int, int>((n) async => n * 2)
          .validate(validators: [(n) => n >= 0 ? null : 'non-negative'])
          .catchError(handlers: {
            ValidationException: (e) async => -100,
          })
          .fallback(fallbackValue: -1);

      expect(await func(3), 6);
      expect(await func(-1), -100);
    });

    test('guard + catchError', () async {
      final func = funx.Func1<int, int>((n) async {
        if (n == 0) throw Exception('zero');
        return n;
      }).guard(preCondition: (n) => n != 0).catchError(handlers: {
        GuardException: (e) async => -1,
      });

      expect(await func(5), 5);
      expect(await func(0), -1);
    });
  });

  group('Performance + Reliability', () {
    test('once + fallback caches failure', () async {
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        throw Exception('fail');
      }).once().fallback(fallbackValue: 0);

      expect(await func(), 0);
      expect(await func(), 0);
      expect(count, 1);
    });

    test('lazy + retry', () async {
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        if (count == 1) throw Exception('fail');
        return 7;
      }).lazy().retry(maxAttempts: 2);

      expect(await func(), 7);
    });

    test('deduplicate + retry', () async {
      var count = 0;
      final func = funx.Func1<int, int>((n) async {
        count++;
        if (count == 1) throw Exception('fail');
        return n;
      }).retry(maxAttempts: 2).deduplicate(window: const Duration(seconds: 1));

      expect(await func(1), 1);
    });

    test('share + retry', () async {
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        if (count == 1) throw Exception('fail');
        return 99;
      }).retry(maxAttempts: 2).share();

      final results = await Future.wait<int>([func(), func(), func()]);
      expect(results, everyElement(99));
    });

    test('rateLimit + fallback allows initial calls', () async {
      final func = funx.Func1<int, int>((n) async => n)
          .rateLimit(maxCalls: 2, window: const Duration(seconds: 1))
          .fallback(fallbackValue: -1);

      expect(await func(1), 1);
      expect(await func(2), 2);
    });

    test('memoize + share + retry', () async {
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        if (count == 1) throw Exception('fail');
        return 123;
      }).retry(maxAttempts: 2).share().memoize();

      expect(await func(), 123);
      expect(await func(), 123);
      expect(count, 2);
    });
  });

  group('Observability + Reliability', () {
    test('tap + retry + memoize', () async {
      var calls = 0;
      var taps = 0;
      final func = funx.Func1<int, int>((n) async {
        calls++;
        if (calls == 1) throw Exception('fail');
        return n * 2;
      })
          .tap(onValue: (result) => taps += result)
          .retry(maxAttempts: 2)
          .memoize();

      expect(await func(3), 6);
      expect(taps, 6);
      expect(await func(3), 6);
      expect(calls, 2);
    });

    test('audit + fallback', () async {
      final logs = <AuditLog<int, int>>[];
      final func = funx.Func1<int, int>((n) async {
        if (n == 0) throw Exception('fail');
        return n;
      }).audit(onAudit: logs.add).fallback(fallbackValue: -1);

      expect(await func(5), 5);
      expect(await func(0), -1);
      expect(logs.length, 2);
    });

    test('monitorObservability + retry', () async {
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        if (count == 1) throw Exception('fail');
        return count;
      }).retry(maxAttempts: 2).monitorObservability();

      expect(await func(), 2);
      final monitor = func as obs.MonitorExtension;
      expect(monitor.getMetrics().executionCount, 1);
      expect(monitor.getMetrics().errorCount, 0);
    });
  });

  group('Cancellation + others', () {
    test('cancellable + timeout propagates cancel', () async {
      final token = CancelToken();
      final func = funx.Func<int>(() async {
        await Future<void>.delayed(const Duration(seconds: 5));
        return 1;
      }).cancellable(token: token).timeout(const Duration(milliseconds: 200));

      Future.delayed(const Duration(milliseconds: 10), token.cancel);
      await expectLater(func(), throwsA(isA<CancelException>()));
    });

    test('cancellable + retry + fallback', () async {
      final token = CancelToken();
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        if (count < 2) throw Exception('fail');
        return 42;
      })
          .cancellable(token: token)
          .retry(maxAttempts: 2)
          .fallback(fallbackValue: -1);

      expect(await func(), 42);
      token.cancel();
      expect(await func(), -1);
    });
  });

  group('State + Reliability', () {
    test('snapshot + retry + fallback', () async {
      var state = 0;
      var count = 0;
      final func = funx.Func1<int, int>((n) async {
        count++;
        state += n;
        if (count == 1) throw Exception('fail');
        return state;
      })
          .snapshot(getState: () => state, setState: (s) => state = s)
          .retry(maxAttempts: 2)
          .fallback(fallbackValue: 0);

      expect(await func(5), 10);
      expect(state, 10);
    });
  });

  group('Orchestration + Reliability', () {
    test('race with retry-wrapped functions', () async {
      var slowCount = 0;
      final slow = funx.Func1<int, int>((n) async {
        slowCount++;
        if (slowCount == 1) throw Exception('fail');
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return 1;
      }).retry(maxAttempts: 2);

      final fast = funx.Func1<int, int>((n) async => 2).retry(maxAttempts: 2);

      final raced = slow.race(competitors: [fast]);
      final result = await raced(0);
      expect(result, 2);
    });

    test('all with retry-wrapped functions', () async {
      var aCount = 0;
      var bCount = 0;
      final a = funx.Func1<int, int>((n) async {
        aCount++;
        if (aCount == 1) throw Exception('fail');
        return 1;
      }).retry(maxAttempts: 2);

      final b = funx.Func1<int, int>((n) async {
        bCount++;
        if (bCount == 1) throw Exception('fail');
        return 2;
      }).retry(maxAttempts: 2);

      final allFn = a.all(functions: [b]);
      final results = await allFn(0);
      expect(results, [1, 2]);
    });
  });

  group('Scheduling + Reliability', () {
    test('schedule + retry executes immediately on missed', () async {
      var count = 0;
      final values = <int>[];
      final func = funx.Func<int>(() async {
        count++;
        if (count == 1) throw Exception('fail');
        values.add(count);
        return count;
      }).retry(maxAttempts: 2);

      final scheduled = func.schedule(
        at: DateTime.now().subtract(const Duration(seconds: 1)),
        onMissed: MissedExecutionPolicy.executeImmediately,
      );
      final subscription = scheduled.start();

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(values, contains(2));
      subscription.cancel();
    });

    test('backpressure sample + fallback', () async {
      final func = funx.Func1<int, int>((n) async {
        if (n == 0) throw Exception('fail');
        return n;
      }).backpressure(
        strategy: BackpressureStrategy.sample,
        sampleRate: 1,
      ).fallback(fallbackValue: -1);

      final results = await Future.wait<int>([
        func(1),
        func(2),
        func(3),
      ]);
      expect(results.any((r) => r > 0), isTrue);
    });
  });

  group('Transformation + Reliability', () {
    test('proxy + retry', () async {
      var count = 0;
      final func = funx.Func1<int, int>((n) async {
        count++;
        if (count == 1) throw Exception('fail');
        return n;
      }).retry(maxAttempts: 2).proxy();

      expect(await func(7), 7);
    });

    test('transform + fallback', () async {
      final func = funx.Func1<int, int>((n) async => n)
          .transform<int>((n) => n * 2)
          .fallback(fallbackValue: 0);

      expect(await func(3), 6);
    });

    test('when + retry', () async {
      var count = 0;
      final func = funx.Func1<int, int>((n) async {
        count++;
        if (count == 1) throw Exception('fail');
        return n;
      }).retry(maxAttempts: 2).when(condition: (n) => n > 0);

      expect(await func(5), 5);
    });

    test('repeat + retry', () async {
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        if (count == 1) throw Exception('fail');
        return 1;
      }).retry(maxAttempts: 2).repeat(times: 3);

      final result = await func();
      expect(result, 1);
    });

    test('merge + fallback', () async {
      final func1 = funx.Func1<int, int>((n) async => n * 2);
      final func2 = funx.Func1<int, int>((n) async => n + 1);
      final merged = MergeExtension1<int, List<int>>(
        [func1, func2],
        combiner: (results) => results.cast<int>(),
      ).fallback(fallbackValue: []);

      final results = await merged(3);
      expect(results, containsAll([6, 4]));
    });
  });

  group('Deep multi-layer stacks', () {
    test('validate + guard + retry + memoize + timeout', () async {
      var count = 0;
      final func = funx.Func1<int, int>((n) async {
        count++;
        if (count == 1) throw Exception('fail');
        return n * n;
      })
          .validate(validators: [(n) => n > 0 ? null : 'positive'])
          .guard(preCondition: (n) => n < 100)
          .retry(maxAttempts: 2)
          .memoize()
          .timeout(const Duration(seconds: 1));

      expect(await func(4), 16);
      expect(await func(4), 16);
      expect(count, 2);
    });

    test('debounce + throttle + retry + fallback + audit', () async {
      var count = 0;
      final logs = <AuditLog<int, int>>[];
      final func = funx.Func1<int, int>((n) async {
        count++;
        if (count < 3) throw Exception('fail');
        return n;
      })
          .debounce(const Duration(milliseconds: 10))
          .throttle(const Duration(milliseconds: 10))
          .retry(maxAttempts: 3)
          .fallback(fallbackValue: -1)
          .audit(onAudit: logs.add);

      expect(await func(5), 5);
      expect(logs.length, 1);
    });

    test('lock + rateLimit + circuit breaker + fallback', () async {
      final cb = CircuitBreaker(
        failureThreshold: 3,
        timeout: const Duration(milliseconds: 100),
      );
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        if (count == 1) throw Exception('fail');
        return count;
      })
          .retry(maxAttempts: 2)
          .lock()
          .rateLimit(maxCalls: 5, window: const Duration(seconds: 1))
          .circuitBreaker(cb)
          .fallback(fallbackValue: 0);

      expect(await func(), 2);
    });

    test('cancellable + lazy + share + retry + defaultValue', () async {
      final token = CancelToken();
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        if (count == 1) throw Exception('fail');
        return 42;
      })
          .cancellable(token: token)
          .lazy()
          .share()
          .retry(maxAttempts: 2)
          .defaultValue(defaultValue: 0);

      final results = await Future.wait<int>([func(), func()]);
      expect(results, everyElement(42));
    });
  });
}
