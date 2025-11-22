import 'dart:async';

import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/performance/rate_limit.dart';
import 'package:funx/src/performance/warm_up.dart';
import 'package:funx/src/reliability/circuit_breaker.dart';
import 'package:funx/src/reliability/recover.dart';
import 'package:test/test.dart';

void main() {
  group('Func', () {
    test('wraps and executes async function', () async {
      final func = funx.Func<int>(() async => 42);
      expect(await func(), equals(42));
    });

    test('can be called multiple times', () async {
      var counter = 0;
      final func = funx.Func<int>(() async => ++counter);

      expect(await func(), equals(1));
      expect(await func(), equals(2));
      expect(await func(), equals(3));
    });

    test('propagates errors', () async {
      final func = funx.Func<int>(() async => throw Exception('error'));
      await expectLater(func(), throwsException);
    });

    test('can debounce', () async {
      var counter = 0;
      final func = funx.Func<int>(
        () async => ++counter,
      ).debounce(const Duration(milliseconds: 50));

      // Call multiple times rapidly
      unawaited(func());
      unawaited(func());
      final future = func();

      // Wait for debounce
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = await future;
      expect(result, equals(1)); // Should only execute once
    });

    test('can throttle', () async {
      var counter = 0;
      final func = funx.Func<int>(
        () async => ++counter,
      ).throttle(const Duration(milliseconds: 100));

      final result1 = await func();
      expect(result1, equals(1));

      // This should be throttled
      await expectLater(func(), throwsStateError);
    });

    test('can delay', () async {
      final stopwatch = Stopwatch()..start();
      final func = funx.Func<int>(
        () async => 42,
      ).delay(const Duration(milliseconds: 100));

      final result = await func();
      stopwatch.stop();

      expect(result, equals(42));
      expect(
        stopwatch.elapsedMilliseconds,
        greaterThanOrEqualTo(100),
      );
    });

    test('can timeout', () async {
      final func = funx.Func<int>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return 42;
      }).timeout(const Duration(milliseconds: 50));

      expect(func(), throwsA(isA<Exception>()));
    });

    test('chains multiple decorators', () async {
      var counter = 0;
      final func = funx.Func<int>(() async => ++counter)
          .delay(const Duration(milliseconds: 50))
          .timeout(const Duration(seconds: 1));

      expect(await func(), equals(1));
    });
  });

  group('Func1', () {
    test('wraps and executes async function with one argument', () async {
      final func = funx.Func1<int, String>((n) async => 'Value: $n');
      expect(await func(42), equals('Value: 42'));
    });

    test('passes argument correctly', () async {
      final func = funx.Func1<String, int>((str) async => str.length);
      expect(await func('hello'), equals(5));
    });

    test('can be called multiple times with different arguments', () async {
      final func = funx.Func1<int, int>((n) async => n * 2);

      expect(await func(5), equals(10));
      expect(await func(10), equals(20));
      expect(await func(15), equals(30));
    });

    test('propagates errors', () async {
      final func = funx.Func<int>(() async => throw Exception('error'));
      expect(func(), throwsException);
    });

    test('can debounce', () async {
      var lastValue = 0;
      final func = funx.Func1<int, int>((n) async {
        lastValue = n;
        return n;
      }).debounce(const Duration(milliseconds: 50));

      await func(1);
      await func(2);
      final future = func(3);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = await future;
      expect(result, equals(3));
      expect(lastValue, equals(3));
    });

    test('can throttle', () async {
      final func = funx.Func1<int, int>(
        (n) async => n,
      ).throttle(const Duration(milliseconds: 100));

      final result = await func(42);
      expect(result, equals(42));

      expect(() => func(43), throwsStateError);
    });

    test('can delay', () async {
      final stopwatch = Stopwatch()..start();
      final func = funx.Func1<int, int>(
        (n) async => n,
      ).delay(const Duration(milliseconds: 100));

      final result = await func(42);
      stopwatch.stop();

      expect(result, equals(42));
      expect(
        stopwatch.elapsedMilliseconds,
        greaterThanOrEqualTo(100),
      );
    });

    test('can timeout', () async {
      final func = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return n;
      }).timeout(const Duration(milliseconds: 50));

      expect(() => func(42), throwsA(isA<Exception>()));
    });
  });

  group('Func2', () {
    test('wraps and executes async function with two arguments', () async {
      final func = funx.Func2<int, int, int>((a, b) async => a + b);
      expect(await func(10, 20), equals(30));
    });

    test('passes both arguments correctly', () async {
      final func = funx.Func2<String, int, String>(
        (str, times) async => str * times,
      );
      expect(await func('x', 3), equals('xxx'));
    });

    test('can be called multiple times', () async {
      final func = funx.Func2<int, int, int>((a, b) async => a * b);

      expect(await func(2, 3), equals(6));
      expect(await func(4, 5), equals(20));
      expect(await func(10, 10), equals(100));
    });

    test('propagates errors', () async {
      final func = funx.Func2<int, int, int>(
        (a, b) async => throw Exception('error'),
      );
      expect(() => func(1, 2), throwsException);
    });

    test('can debounce', () async {
      var lastSum = 0;
      final func = funx.Func2<int, int, int>((a, b) async {
        return lastSum = a + b;
      }).debounce(const Duration(milliseconds: 50));

      await func(1, 1);
      await func(2, 2);
      final future = func(3, 3);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = await future;
      expect(result, equals(6));
      expect(lastSum, equals(6));
    });

    test('can throttle', () async {
      final func = funx.Func2<int, int, int>(
        (a, b) async => a + b,
      ).throttle(const Duration(milliseconds: 100));

      final result = await func(10, 20);
      expect(result, equals(30));

      expect(() => func(5, 5), throwsStateError);
    });

    test('can delay', () async {
      final stopwatch = Stopwatch()..start();
      final func = funx.Func2<int, int, int>(
        (a, b) async => a + b,
      ).delay(const Duration(milliseconds: 100));

      final result = await func(10, 20);
      stopwatch.stop();

      expect(result, equals(30));
      expect(
        stopwatch.elapsedMilliseconds,
        greaterThanOrEqualTo(100),
      );
    });

    test('can timeout', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return a + b;
      }).timeout(const Duration(milliseconds: 50));

      expect(() => func(10, 20), throwsA(isA<Exception>()));
    });
  });

  group('Func.retry', () {
    test('can retry on failure', () async {
      var attempts = 0;
      final func = funx.Func<String>(() async {
        attempts++;
        if (attempts < 3) throw Exception('Failed');
        return 'success';
      }).retry(maxAttempts: 3);

      final result = await func();
      expect(result, equals('success'));
      expect(attempts, equals(3));
    });
  });

  group('Func.circuitBreaker', () {
    test('can use circuit breaker', () async {
      final breaker = CircuitBreaker(failureThreshold: 2);
      final func = funx.Func<String>(
        () async => 'success',
      ).circuitBreaker(breaker);

      final result = await func();
      expect(result, equals('success'));
      expect(breaker.state, equals(CircuitBreakerState.closed));
    });
  });

  group('Func.fallback', () {
    test('can use fallback value', () async {
      final func = funx.Func<String>(
        () async => throw Exception('error'),
      ).fallback(fallbackValue: 'fallback');

      final result = await func();
      expect(result, equals('fallback'));
    });
  });

  group('Func.recover', () {
    test('can recover from errors', () async {
      var recoveryCalled = false;
      final strategy = RecoveryStrategy(
        onError: (error) async {
          recoveryCalled = true;
        },
      );

      final func = funx.Func<String>(
        () async => throw Exception('error'),
      ).recover(strategy);

      await expectLater(func(), throwsA(isA<Exception>()));
      expect(recoveryCalled, isTrue);
    });
  });

  group('Func1.retry', () {
    test('can retry on failure', () async {
      var attempts = 0;
      final func = funx.Func1<int, String>((value) async {
        attempts++;
        if (attempts < 2) throw Exception('Failed');
        return 'value: $value';
      }).retry(maxAttempts: 3);

      final result = await func(42);
      expect(result, equals('value: 42'));
      expect(attempts, equals(2));
    });
  });

  group('Func2.retry', () {
    test('can retry on failure', () async {
      var attempts = 0;
      final func = funx.Func2<int, String, String>((n, str) async {
        attempts++;
        if (attempts < 2) throw Exception('Failed');
        return '$str: $n';
      }).retry(maxAttempts: 3);

      final result = await func(42, 'answer');
      expect(result, equals('answer: 42'));
      expect(attempts, equals(2));
    });
  });

  // Performance method tests

  group('Func.once', () {
    test('executes only once and caches result', () async {
      var callCount = 0;
      final func = funx.Func(() async {
        callCount++;
        return 'result';
      }).once();

      expect(await func(), equals('result'));
      expect(await func(), equals('result'));
      expect(await func(), equals('result'));
      expect(callCount, equals(1));
    });
  });

  group('Func1.memoize', () {
    test('caches results per argument', () async {
      var callCount = 0;
      final func = funx.Func1((int x) async {
        callCount++;
        return x * 2;
      }).memoize();

      expect(await func(5), equals(10));
      expect(await func(5), equals(10)); // Cached
      expect(await func(10), equals(20)); // New arg
      expect(callCount, equals(2)); // Only called twice
    });
  });

  group('Func2.deduplicate', () {
    test('prevents duplicate calls within window', () async {
      var callCount = 0;
      final func = funx.Func2((int a, int b) async {
        callCount++;
        return a + b;
      }).deduplicate(window: const Duration(milliseconds: 100));

      expect(await func(3, 4), equals(7));
      expect(await func(3, 4), equals(7)); // Deduplicated
      expect(callCount, equals(1));

      // Wait for window to expire
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(await func(3, 4), equals(7)); // New execution
      expect(callCount, equals(2));
    });
  });

  group('Func.share', () {
    test('shares execution among concurrent calls', () async {
      var callCount = 0;
      final func = funx.Func(() async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return callCount;
      }).share();

      final results = await Future.wait([
        func(),
        func(),
        func(),
      ]);

      expect(results, equals([1, 1, 1])); // All share same execution
      expect(callCount, equals(1));
    });
  });

  group('Func1.batch', () {
    test('batches multiple calls together', () async {
      final batches = <List<int>>[];
      final func = funx.Func1((int x) async => x).batch(
        executor: funx.Func1((List<int> items) async {
          batches.add(List.from(items));
        }),
        maxSize: 3,
        maxWait: const Duration(milliseconds: 100),
      );

      unawaited(func(1));
      unawaited(func(2));
      await func(3); // Triggers batch

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(batches.length, equals(1));
      expect(batches[0], equals([1, 2, 3]));
    });
  });

  group('Func.rateLimit', () {
    test('limits execution rate', () async {
      var callCount = 0;
      final func =
          funx.Func(() async {
            return ++callCount;
          }).rateLimit(
            maxCalls: 2,
            window: const Duration(milliseconds: 100),
            strategy: RateLimitStrategy.fixedWindow,
          );

      // First two calls execute immediately
      await func();
      await func();
      expect(callCount, equals(2));

      // Third call waits for window to reset
      final start = DateTime.now();
      await func();
      final elapsed = DateTime.now().difference(start);

      expect(callCount, equals(3));
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(90));
    });
  });

  group('Func.warmUp', () {
    test('eagerly loads result', () async {
      var callCount = 0;
      final func = funx.Func(() async {
        callCount++;
        return 'loaded';
      }).warmUp(trigger: WarmUpTrigger.onInit);

      // Give time for warm-up
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = await func();
      expect(result, equals('loaded'));
      expect(callCount, equals(1)); // Already warmed up
    });
  });

  group('Func1.cacheAside', () {
    test('implements cache-aside pattern', () async {
      var callCount = 0;
      final func = funx.Func1((String key) async {
        callCount++;
        return 'value-$key';
      }).cacheAside(ttl: const Duration(minutes: 5));

      expect(await func('key1'), equals('value-key1'));
      expect(await func('key1'), equals('value-key1')); // Cached
      expect(await func('key2'), equals('value-key2')); // New key
      expect(callCount, equals(2)); // Only 2 actual calls
    });
  });
}
