// ignore_for_file: unused_local_variable test

import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('RateLimitExtension - TokenBucket', () {
    test('allows bursts up to maxCalls', () async {
      var callCount = 0;
      final func =
          Func(() async {
            return ++callCount;
          }).rateLimit(
            maxCalls: 3,
            window: const Duration(seconds: 1),
            strategy: RateLimitStrategy.tokenBucket,
          );

      // First 3 calls should execute immediately
      final start = DateTime.now();
      await Future.wait([func(), func(), func()]);
      final elapsed = DateTime.now().difference(start);

      expect(callCount, equals(3));
      expect(elapsed.inMilliseconds, lessThan(100)); // Burst allowed
    });

    test('delays calls beyond rate limit', () async {
      var callCount = 0;
      final func =
          Func(() async {
            return ++callCount;
          }).rateLimit(
            maxCalls: 2,
            window: const Duration(milliseconds: 200),
            strategy: RateLimitStrategy.tokenBucket,
          );

      await Future.wait([func(), func()]); // Use 2 tokens

      final start = DateTime.now();
      await func(); // Should wait for token refill
      final elapsed = DateTime.now().difference(start);

      expect(callCount, equals(3));
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(150));
    });

    test('reset() clears rate limit state', () async {
      var callCount = 0;
      final func =
          Func(() async {
                return ++callCount;
              }).rateLimit(
                maxCalls: 1,
                window: const Duration(seconds: 10),
              )
              as RateLimitExtension<int>;

      await func(); // Use token
      func.reset(); // Reset tokens
      await func(); // Should execute immediately

      expect(callCount, equals(2));
    });
  });

  group('RateLimitExtension - FixedWindow', () {
    test('allows maxCalls within window', () async {
      var callCount = 0;
      final func =
          Func(() async {
            return ++callCount;
          }).rateLimit(
            maxCalls: 3,
            window: const Duration(seconds: 1),
            strategy: RateLimitStrategy.fixedWindow,
          );

      await Future.wait([func(), func(), func()]);

      expect(callCount, equals(3));
    });

    test('blocks calls after limit reached', () async {
      var callCount = 0;
      final func =
          Func(() async {
            return ++callCount;
          }).rateLimit(
            maxCalls: 2,
            window: const Duration(milliseconds: 200),
            strategy: RateLimitStrategy.fixedWindow,
          );

      await Future.wait([func(), func()]);

      final start = DateTime.now();
      await func();
      final elapsed = DateTime.now().difference(start);

      expect(callCount, equals(3));
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(150));
    });
  });

  group('RateLimitExtension - SlidingWindow', () {
    test('maintains sliding window of calls', () async {
      var callCount = 0;
      final func =
          Func(() async {
            return ++callCount;
          }).rateLimit(
            maxCalls: 2,
            window: const Duration(milliseconds: 200),
            strategy: RateLimitStrategy.slidingWindow,
          );

      await func(); // Call 1
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await func(); // Call 2

      // Call 3 should wait ~100ms for call 1 to exit window
      final start = DateTime.now();
      await func();
      final elapsed = DateTime.now().difference(start);

      expect(callCount, equals(3));
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(90));
    });
  });

  group('RateLimitExtension1', () {
    test('rate limits across all arguments', () async {
      var callCount = 0;
      final func =
          Func1((String arg) async {
            callCount++;
            return arg;
          }).rateLimit(
            maxCalls: 2,
            window: const Duration(milliseconds: 200),
          );

      await Future.wait([func('a'), func('b')]); // Use 2 tokens

      final start = DateTime.now();
      await func('c'); // Should wait
      final elapsed = DateTime.now().difference(start);

      expect(callCount, equals(3));
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(150));
    });

    test('different arguments share same rate limit', () async {
      var callCount = 0;
      final func =
          Func1((int x) async {
            callCount++;
            return x;
          }).rateLimit(
            maxCalls: 3,
            window: const Duration(seconds: 1),
            strategy: RateLimitStrategy.fixedWindow,
          );

      await Future.wait([func(1), func(2), func(3)]);

      expect(callCount, equals(3));
    });
  });

  group('RateLimitExtension2', () {
    test('rate limits across all argument pairs', () async {
      var callCount = 0;
      final func =
          Func2((int a, int b) async {
            callCount++;
            return a + b;
          }).rateLimit(
            maxCalls: 2,
            window: const Duration(milliseconds: 200),
          );

      await Future.wait([func(1, 2), func(3, 4)]);

      final start = DateTime.now();
      await func(5, 6);
      final elapsed = DateTime.now().difference(start);

      expect(callCount, equals(3));
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(150));
    });
  });

  group('RateLimitExtension - Leaky Bucket', () {
    test('enforces steady rate without bursts', () async {
      var callCount = 0;
      final func =
          Func(() async {
                return ++callCount;
              }).rateLimit(
                maxCalls: 5,
                window: const Duration(milliseconds: 500),
                strategy: RateLimitStrategy.leakyBucket,
              )
              as RateLimitExtension<int>;

      final start = DateTime.now();

      // Queue 3 calls
      final futures = [func(), func(), func()];
      await Future.wait(futures);

      final elapsed = DateTime.now().difference(start);

      expect(callCount, equals(3));
      // Leaky bucket drips at steady rate (500ms / 5 calls = 100ms per call)
      // 3 calls should take ~200ms minimum
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(150));

      func.dispose();
    });

    test('queue fills up and processes calls', () async {
      var callCount = 0;
      final func =
          Func(() async {
                return ++callCount;
              }).rateLimit(
                maxCalls: 2,
                window: const Duration(milliseconds: 100),
                strategy: RateLimitStrategy.leakyBucket,
              )
              as RateLimitExtension<int>;

      // Start multiple calls
      final futures = [func(), func(), func(), func()];

      await Future.wait(futures);

      expect(callCount, equals(4));

      func.dispose();
    });
  });

  group('RateLimitExtension1 - Different Strategies', () {
    test('token bucket with Func1', () async {
      var callCount = 0;
      final func =
          Func1((int x) async {
            callCount++;
            return x;
          }).rateLimit(
            maxCalls: 2,
            window: const Duration(milliseconds: 200),
            strategy: RateLimitStrategy.tokenBucket,
          );

      await Future.wait([func(1), func(2)]);
      expect(callCount, equals(2));
    });

    test('leaky bucket with Func1', () async {
      var callCount = 0;
      final func =
          Func1((String s) async {
                callCount++;
                return s;
              }).rateLimit(
                maxCalls: 3,
                window: const Duration(milliseconds: 300),
                strategy: RateLimitStrategy.leakyBucket,
              )
              as RateLimitExtension1<String, String>;

      final futures = [func('a'), func('b'), func('c')];
      await Future.wait(futures);

      expect(callCount, equals(3));
      func.dispose();
    });

    test('sliding window with Func1', () async {
      var callCount = 0;
      final func =
          Func1((int x) async {
            callCount++;
            return x;
          }).rateLimit(
            maxCalls: 2,
            window: const Duration(milliseconds: 200),
            strategy: RateLimitStrategy.slidingWindow,
          );

      await func(1);
      await func(2);

      expect(callCount, equals(2));
    });

    test('fixed window with Func1', () async {
      var callCount = 0;
      final func =
          Func1((int x) async {
            callCount++;
            return x;
          }).rateLimit(
            maxCalls: 2,
            window: const Duration(milliseconds: 200),
            strategy: RateLimitStrategy.fixedWindow,
          );

      await func(1);
      await func(2);

      expect(callCount, equals(2));
    });

    test('reset works for Func1', () async {
      final func =
          Func1((int x) async => x).rateLimit(
                maxCalls: 1,
                window: const Duration(seconds: 10),
              )
              as RateLimitExtension1<int, int>;

      await func(1);
      func.reset();
      await func(2);

      // Should work without delay due to reset
    });
  });

  group('RateLimitExtension2 - Different Strategies', () {
    test('token bucket with Func2', () async {
      var callCount = 0;
      final func =
          Func2((int a, int b) async {
            callCount++;
            return a + b;
          }).rateLimit(
            maxCalls: 2,
            window: const Duration(milliseconds: 200),
            strategy: RateLimitStrategy.tokenBucket,
          );

      await Future.wait([func(1, 2), func(3, 4)]);
      expect(callCount, equals(2));
    });

    test('leaky bucket with Func2', () async {
      var callCount = 0;
      final func =
          Func2((int a, int b) async {
                callCount++;
                return a + b;
              }).rateLimit(
                maxCalls: 3,
                window: const Duration(milliseconds: 300),
                strategy: RateLimitStrategy.leakyBucket,
              )
              as RateLimitExtension2<int, int, int>;

      final futures = [func(1, 1), func(2, 2), func(3, 3)];
      await Future.wait(futures);

      expect(callCount, equals(3));
      func.dispose();
    });

    test('sliding window with Func2', () async {
      var callCount = 0;
      final func =
          Func2((int a, int b) async {
            callCount++;
            return a + b;
          }).rateLimit(
            maxCalls: 2,
            window: const Duration(milliseconds: 200),
            strategy: RateLimitStrategy.slidingWindow,
          );

      await func(1, 2);
      await func(3, 4);

      expect(callCount, equals(2));
    });

    test('fixed window with Func2', () async {
      var callCount = 0;
      final func =
          Func2((int a, int b) async {
            callCount++;
            return a + b;
          }).rateLimit(
            maxCalls: 2,
            window: const Duration(milliseconds: 200),
            strategy: RateLimitStrategy.fixedWindow,
          );

      await func(1, 2);
      await func(3, 4);

      expect(callCount, equals(2));
    });

    test('reset works for Func2', () async {
      final func =
          Func2((int a, int b) async => a + b).rateLimit(
                maxCalls: 1,
                window: const Duration(seconds: 10),
              )
              as RateLimitExtension2<int, int, int>;

      await func(1, 2);
      func.reset();
      await func(3, 4);

      // Should work without delay due to reset
    });

    test('dispose works for Func2', () async {
      final func =
          Func2((int a, int b) async => a + b).rateLimit(
                  maxCalls: 3,
                  window: const Duration(milliseconds: 300),
                  strategy: RateLimitStrategy.leakyBucket,
                )
                as RateLimitExtension2<int, int, int>
            ..dispose();

      // No exceptions should occur on dispose
    });
  });
}
