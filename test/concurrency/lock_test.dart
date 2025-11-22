// ignore_for_file: avoid_catches_without_on_clauses test

import 'dart:async';

import 'package:funx/src/concurrency/lock.dart';
import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('Lock', () {
    test('allows single execution at a time', () async {
      final lock = Lock();
      var concurrentCount = 0;
      var maxConcurrent = 0;

      await lock.synchronized(() async {
        concurrentCount++;
        maxConcurrent = concurrentCount > maxConcurrent
            ? concurrentCount
            : maxConcurrent;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        concurrentCount--;
      });

      expect(maxConcurrent, equals(1));
    });

    test('queues multiple requests', () async {
      final lock = Lock();
      final order = <int>[];

      final futures = <Future<void>>[];
      for (var i = 0; i < 3; i++) {
        final index = i;
        futures.add(
          lock.synchronized(() async {
            order.add(index);
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }),
        );
      }

      await Future.wait(futures);
      expect(order, equals([0, 1, 2]));
    });

    test('respects timeout on acquire', () async {
      final lock = Lock();

      // Acquire lock manually
      await lock.acquire();

      // Try to acquire with timeout - should throw
      try {
        await lock.acquire(timeout: const Duration(milliseconds: 50));
        fail('Should have thrown TimeoutException');
      } catch (e) {
        expect(e, isA<TimeoutException>());
      } finally {
        lock.release();
      }
    });

    test('synchronized executes sequentially', () async {
      final lock = Lock();
      final order = <int>[];

      await Future.wait([
        lock.synchronized(() async {
          order.add(1);
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }),
        lock.synchronized(() async {
          order.add(2);
        }),
        lock.synchronized(() async {
          order.add(3);
        }),
      ]);

      expect(order, equals([1, 2, 3]));
    });

    test('acquire and release manually', () async {
      final lock = Lock();

      await lock.acquire();
      expect(lock.isLocked, isTrue);

      lock.release();
      expect(lock.isLocked, isFalse);
    });
  });

  group('LockExtension', () {
    test('prevents concurrent execution', () async {
      var concurrentCount = 0;
      var maxConcurrent = 0;

      final func = funx.Func(() async {
        concurrentCount++;
        maxConcurrent = concurrentCount > maxConcurrent
            ? concurrentCount
            : maxConcurrent;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        concurrentCount--;
        return maxConcurrent;
      }).lock();

      final results = await Future.wait([
        func(),
        func(),
        func(),
      ]);

      expect(results, everyElement(equals(1)));
      expect(maxConcurrent, equals(1));
    });

    test('handles timeout', () async {
      final func = funx.Func(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return 42;
      }).lock(timeout: const Duration(milliseconds: 50));

      // First call succeeds
      final future1 = func();

      // Wait a bit
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Second call times out
      expect(func(), throwsA(isA<TimeoutException>()));

      await future1;
    });

    test('can disable timeout exception', () async {
      var blockedCount = 0;

      final func =
          funx.Func(() async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return 42;
          }).lock(
            timeout: const Duration(milliseconds: 50),
            throwOnTimeout: false,
            onBlocked: () => blockedCount++,
          );

      // First call
      final future1 = func();

      // Wait a bit
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Second call waits instead of throwing
      final result2 = await func();

      expect(result2, equals(42));
      expect(blockedCount, equals(1));

      await future1;
    });
  });

  group('LockExtension1', () {
    test('locks execution with parameters', () async {
      var concurrentCount = 0;
      var maxConcurrent = 0;

      final func = funx.Func1<int, int>((n) async {
        concurrentCount++;
        maxConcurrent = concurrentCount > maxConcurrent
            ? concurrentCount
            : maxConcurrent;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        concurrentCount--;
        return n * 2;
      }).lock();

      final results = await Future.wait([
        func(1),
        func(2),
        func(3),
      ]);

      expect(results, equals([2, 4, 6]));
      expect(maxConcurrent, equals(1));
    });

    test('calls onBlocked when waiting', () async {
      var blockedCount = 0;

      final func = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return n;
      }).lock(onBlocked: () => blockedCount++);

      final future1 = func(1);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await func(2);
      await future1;

      expect(blockedCount, equals(1));
    });
  });

  group('LockExtension2', () {
    test('locks execution with two parameters', () async {
      var concurrentCount = 0;
      var maxConcurrent = 0;

      final func = funx.Func2<int, int, int>((a, b) async {
        concurrentCount++;
        maxConcurrent = concurrentCount > maxConcurrent
            ? concurrentCount
            : maxConcurrent;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        concurrentCount--;
        return a + b;
      }).lock();

      final results = await Future.wait([
        func(1, 2),
        func(3, 4),
        func(5, 6),
      ]);

      expect(results, equals([3, 7, 11]));
      expect(maxConcurrent, equals(1));
    });

    test('handles timeout with two parameters', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return a + b;
      }).lock(timeout: const Duration(milliseconds: 50));

      final future1 = func(1, 2);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(func(3, 4), throwsA(isA<TimeoutException>()));

      await future1;
    });
  });

  group('Lock edge cases', () {
    test('handles rapid successive calls', () async {
      final lock = Lock();
      final results = <int>[];

      final futures = <Future<void>>[];
      for (var i = 0; i < 10; i++) {
        final index = i;
        futures.add(
          lock.synchronized(() async {
            results.add(index);
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }),
        );
      }

      await Future.wait(futures);
      expect(results, equals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));
    });

    test('handles errors correctly', () async {
      final lock = Lock();

      var errorThrown = false;
      try {
        await lock.synchronized(() async {
          throw Exception('Test error');
        });
      } catch (e) {
        errorThrown = true;
      }

      expect(errorThrown, isTrue);

      // Lock should be released after error
      expect(lock.isLocked, isFalse);

      // Next call should succeed
      final result = await lock.synchronized(() async {
        return 42;
      });
      expect(result, equals(42));
    });

    test('multiple locks work independently', () async {
      final lock1 = Lock();
      final lock2 = Lock();

      var count1 = 0;
      var count2 = 0;

      await Future.wait([
        lock1.synchronized(() async {
          count1++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }),
        lock2.synchronized(() async {
          count2++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }),
      ]);

      expect(count1, equals(1));
      expect(count2, equals(1));
    });
  });
}
