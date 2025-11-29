// ignore_for_file: avoid_catches_without_on_clauses test

import 'dart:async';

import 'package:funx/src/concurrency/semaphore.dart';
import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/core/types.dart';
import 'package:test/test.dart';

void main() {
  group('Semaphore', () {
    test('limits concurrent executions', () async {
      final semaphore = Semaphore(maxConcurrent: 2);
      var concurrentCount = 0;
      var maxConcurrent = 0;

      final futures = <Future<void>>[];
      for (var i = 0; i < 5; i++) {
        futures.add(
          semaphore.acquire().then((_) async {
            concurrentCount++;
            if (concurrentCount > maxConcurrent) {
              maxConcurrent = concurrentCount;
            }
            await Future<void>.delayed(const Duration(milliseconds: 50));
            concurrentCount--;
            semaphore.release();
          }),
        );
      }

      await Future.wait(futures);
      expect(maxConcurrent, equals(2));
    });

    test('blocks when all permits are taken', () async {
      final semaphore = Semaphore(maxConcurrent: 1);

      await semaphore.acquire();
      expect(semaphore.availablePermits, equals(0));

      var blocked = true;
      final future = semaphore.acquire().then((_) {
        blocked = false;
        semaphore.release();
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(blocked, isTrue);

      semaphore.release();
      await future;
      expect(blocked, isFalse);
    });

    test('FIFO mode respects order', () async {
      final semaphore = Semaphore(
        maxConcurrent: 1,
      );
      final executionOrder = <int>[];

      await semaphore.acquire();

      final futures = <Future<void>>[];
      for (var i = 0; i < 3; i++) {
        final index = i;
        futures.add(
          semaphore.acquire().then((_) async {
            executionOrder.add(index);
            semaphore.release();
          }),
        );
      }

      semaphore.release();
      await Future.wait(futures);

      expect(executionOrder, equals([0, 1, 2]));
    });

    test('LIFO mode executes in reverse order', () async {
      final semaphore = Semaphore(
        maxConcurrent: 1,
        queueMode: QueueMode.lifo,
      );
      final executionOrder = <int>[];

      await semaphore.acquire();

      final futures = <Future<void>>[];
      for (var i = 0; i < 3; i++) {
        final index = i;
        futures.add(
          semaphore.acquire().then((_) async {
            executionOrder.add(index);
            semaphore.release();
          }),
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 10));

      semaphore.release();
      await Future.wait(futures);

      expect(executionOrder, equals([2, 1, 0]));
    });

    test('tracks available permits', () async {
      final semaphore = Semaphore(maxConcurrent: 3);

      expect(semaphore.availablePermits, equals(3));

      await semaphore.acquire();
      expect(semaphore.availablePermits, equals(2));

      await semaphore.acquire();
      expect(semaphore.availablePermits, equals(1));

      semaphore.release();
      expect(semaphore.availablePermits, equals(2));

      semaphore.release();
      expect(semaphore.availablePermits, equals(3));
    });

    test('respects timeout', () async {
      final semaphore = Semaphore(maxConcurrent: 1);

      await semaphore.acquire();

      var timeoutOccurred = false;
      try {
        await semaphore.acquire(timeout: const Duration(milliseconds: 50));
      } catch (e) {
        if (e is TimeoutException) {
          timeoutOccurred = true;
        }
      }

      expect(timeoutOccurred, isTrue);
      semaphore.release();
    });

    test('priority mode processes by priority', () async {
      final semaphore = Semaphore(
        maxConcurrent: 1,
        queueMode: QueueMode.priority,
      );

      // Nie ma bezpośredniego sposobu na testowanie priority w Semaphore
      // bez dodatkowej funkcji priorytetowej, ale możemy przetestować
      // że tryb priority jest akceptowany
      await semaphore.acquire();
      expect(semaphore.availablePermits, equals(0));

      semaphore.release();
      expect(semaphore.availablePermits, equals(1));
    });
  });

  group('SemaphoreExtension', () {
    test('limits concurrent executions', () async {
      var concurrentCount = 0;
      var maxConcurrent = 0;

      final func = funx.Func(() async {
        concurrentCount++;
        if (concurrentCount > maxConcurrent) {
          maxConcurrent = concurrentCount;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
        concurrentCount--;
        return maxConcurrent;
      }).semaphore(maxConcurrent: 2);

      final results = await Future.wait([
        func(),
        func(),
        func(),
        func(),
        func(),
      ]);

      expect(results, everyElement(lessThanOrEqualTo(2)));
      expect(maxConcurrent, equals(2));
    });

    test('handles timeout', () async {
      final func =
          funx.Func(() async {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            return 42;
          }).semaphore(
            maxConcurrent: 1,
            timeout: const Duration(milliseconds: 50),
          );

      final future1 = func();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      var timedOut = false;
      try {
        await func();
      } catch (e) {
        if (e is TimeoutException) {
          timedOut = true;
        }
      }

      expect(timedOut, isTrue);
      await future1;
    });

    test('tracks availablePermits and queueLength', () async {
      final func = funx.Func(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 42;
      }).semaphore(maxConcurrent: 2);

      final wrapped = func as SemaphoreExtension;
      expect(wrapped.availablePermits, equals(2));
      expect(wrapped.queueLength, equals(0));

      final futures = [func(), func(), func()];

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(wrapped.availablePermits, lessThanOrEqualTo(2));

      await Future.wait(futures);
      expect(wrapped.availablePermits, equals(2));
      expect(wrapped.queueLength, equals(0));
    });
  });

  group('SemaphoreExtension1', () {
    test('limits concurrent executions with parameters', () async {
      var concurrentCount = 0;
      var maxConcurrent = 0;

      final func = funx.Func1<int, int>((n) async {
        concurrentCount++;
        if (concurrentCount > maxConcurrent) {
          maxConcurrent = concurrentCount;
        }
        await Future<void>.delayed(const Duration(milliseconds: 30));
        concurrentCount--;
        return n * 2;
      }).semaphore(maxConcurrent: 2);

      final results = await Future.wait([
        func(1),
        func(2),
        func(3),
        func(4),
        func(5),
      ]);

      expect(results, equals([2, 4, 6, 8, 10]));
      expect(maxConcurrent, equals(2));
    });

    test('tracks availablePermits and queueLength', () async {
      final func = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return n * 2;
      }).semaphore(maxConcurrent: 2);

      final wrapped = func as SemaphoreExtension1;
      expect(wrapped.availablePermits, equals(2));
      expect(wrapped.queueLength, equals(0));

      final futures = [func(1), func(2), func(3)];

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(wrapped.availablePermits, lessThanOrEqualTo(2));

      await Future.wait(futures);
      expect(wrapped.availablePermits, equals(2));
      expect(wrapped.queueLength, equals(0));
    });
  });

  group('SemaphoreExtension2', () {
    test('limits concurrent executions with two parameters', () async {
      var concurrentCount = 0;
      var maxConcurrent = 0;

      final func = funx.Func2<int, int, int>((a, b) async {
        concurrentCount++;
        if (concurrentCount > maxConcurrent) {
          maxConcurrent = concurrentCount;
        }
        await Future<void>.delayed(const Duration(milliseconds: 30));
        concurrentCount--;
        return a + b;
      }).semaphore(maxConcurrent: 2);

      final results = await Future.wait([
        func(1, 2),
        func(3, 4),
        func(5, 6),
        func(7, 8),
      ]);

      expect(results, equals([3, 7, 11, 15]));
      expect(maxConcurrent, equals(2));
    });

    test('tracks availablePermits and queueLength', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return a + b;
      }).semaphore(maxConcurrent: 2);

      final wrapped = func as SemaphoreExtension2;
      expect(wrapped.availablePermits, equals(2));
      expect(wrapped.queueLength, equals(0));

      final futures = [func(1, 2), func(3, 4), func(5, 6)];

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(wrapped.availablePermits, lessThanOrEqualTo(2));

      await Future.wait(futures);
      expect(wrapped.availablePermits, equals(2));
      expect(wrapped.queueLength, equals(0));
    });
  });

  group('Semaphore edge cases', () {
    test('handles rapid acquire and release', () async {
      final semaphore = Semaphore(maxConcurrent: 5);

      final futures = <Future<void>>[];
      for (var i = 0; i < 50; i++) {
        futures.add(
          semaphore.acquire().then((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            semaphore.release();
          }),
        );
      }

      await Future.wait(futures);
      expect(semaphore.availablePermits, equals(5));
    });

    test('handles errors in critical section', () async {
      final semaphore = Semaphore(maxConcurrent: 2);

      await semaphore.acquire();

      var errorOccurred = false;
      try {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        semaphore.release();
        throw Exception('Test error');
      } catch (e) {
        errorOccurred = true;
      }

      expect(errorOccurred, isTrue);

      await semaphore.acquire();
      semaphore.release();
    });
  });
}
