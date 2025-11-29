import 'dart:async';

import 'package:funx/src/concurrency/bulkhead.dart';
import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('Bulkhead', () {
    test('isolates execution in pools', () async {
      final bulkhead = Bulkhead(poolSize: 2, queueSize: 100);
      var executionCount = 0;

      final futures = <Future<void>>[];
      for (var i = 0; i < 4; i++) {
        futures.add(
          bulkhead.execute(() async {
            executionCount++;
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }),
        );
      }

      await Future.wait(futures);
      expect(executionCount, equals(4));
    });

    test('uses round-robin pool selection', () async {
      final bulkhead = Bulkhead(poolSize: 2, queueSize: 100);
      final poolUsage = <int>[];

      for (var i = 0; i < 6; i++) {
        await bulkhead.execute(() async {
          poolUsage.add(i);
        });
      }

      expect(poolUsage.length, equals(6));
    });

    test('respects timeout', () async {
      final bulkhead = Bulkhead(poolSize: 1, queueSize: 100);

      // Acquire the only pool slot
      final future1 = bulkhead.execute(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return 'done';
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Try to execute with timeout
      var timedOut = false;
      try {
        await bulkhead.execute(
          () async => 'should timeout',
          timeout: const Duration(milliseconds: 50),
        );
      } catch (e) {
        if (e is TimeoutException) {
          timedOut = true;
        }
      }

      expect(timedOut, isTrue);
      await future1;
    });

    test('finally block releases semaphore', () async {
      final bulkhead = Bulkhead(poolSize: 1, queueSize: 100);
      var errorThrown = false;

      try {
        await bulkhead.execute(() async {
          throw Exception('Test error');
        });
      } catch (e) {
        errorThrown = true;
      }

      expect(errorThrown, isTrue);

      // Should be able to execute again
      final result = await bulkhead.execute(() async => 'success');
      expect(result, equals('success'));
    });
  });

  group('BulkheadExtension', () {
    test('isolates function executions', () async {
      var executionCount = 0;

      final func = funx.Func(() async {
        executionCount++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return executionCount;
      }).bulkhead(poolSize: 2);

      final results = await Future.wait([
        func(),
        func(),
        func(),
      ]);

      expect(results.length, equals(3));
      expect(executionCount, equals(3));
    });

    test('calls onIsolationFailure on error', () async {
      var failureCalled = false;
      Object? capturedError;

      final func =
          funx.Func(() async {
            throw Exception('Test failure');
          }).bulkhead(
            poolSize: 2,
            onIsolationFailure: (error, stackTrace) {
              failureCalled = true;
              capturedError = error;
            },
          );

      try {
        await func();
      } catch (e) {
        // Expected
      }

      expect(failureCalled, isTrue);
      expect(capturedError, isA<Exception>());
    });

    test('provides access to bulkhead instance', () async {
      final func = funx.Func(() async => 42).bulkhead(poolSize: 3);
      final wrapped = func as BulkheadExtension;

      expect(wrapped.instance.poolSize, equals(3));
    });

    test('calls onIsolationFailure on timeout', () async {
      var failureCalled = false;

      final func =
          funx.Func(() async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return 42;
          }).bulkhead(
            poolSize: 1,
            timeout: const Duration(milliseconds: 50),
            onIsolationFailure: (error, stackTrace) {
              failureCalled = true;
            },
          );

      final future1 = func();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      try {
        await func();
      } catch (e) {
        // Expected timeout
      }

      expect(failureCalled, isTrue);
      await future1;
    });
  });

  group('BulkheadExtension1', () {
    test('works with parameters', () async {
      final func = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return n * 2;
      }).bulkhead(poolSize: 2);

      final results = await Future.wait([
        func(1),
        func(2),
        func(3),
      ]);

      expect(results, equals([2, 4, 6]));
    });

    test('calls onIsolationFailure on error', () async {
      var failureCalled = false;

      final func =
          funx.Func1<int, int>((n) async {
            throw Exception('Test failure');
          }).bulkhead(
            poolSize: 2,
            onIsolationFailure: (error, stackTrace) {
              failureCalled = true;
            },
          );

      try {
        await func(5);
      } catch (e) {
        // Expected
      }

      expect(failureCalled, isTrue);
    });

    test('provides access to bulkhead instance', () async {
      final func = funx.Func1<int, int>(
        (n) async => n * 2,
      ).bulkhead(poolSize: 4, queueSize: 50);
      final wrapped = func as BulkheadExtension1;

      expect(wrapped.instance.poolSize, equals(4));
      expect(wrapped.instance.queueSize, equals(50));
    });
  });

  group('BulkheadExtension2', () {
    test('works with two parameters', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return a + b;
      }).bulkhead(poolSize: 2);

      final results = await Future.wait([
        func(1, 2),
        func(3, 4),
      ]);

      expect(results, equals([3, 7]));
    });

    test('calls onIsolationFailure on error', () async {
      var failureCalled = false;

      final func =
          funx.Func2<int, int, int>((a, b) async {
            throw Exception('Test failure');
          }).bulkhead(
            poolSize: 2,
            onIsolationFailure: (error, stackTrace) {
              failureCalled = true;
            },
          );

      try {
        await func(1, 2);
      } catch (e) {
        // Expected
      }

      expect(failureCalled, isTrue);
    });

    test('provides access to bulkhead instance', () async {
      final func = funx.Func2<int, int, int>(
        (a, b) async => a + b,
      ).bulkhead(poolSize: 5);
      final wrapped = func as BulkheadExtension2;

      expect(wrapped.instance.poolSize, equals(5));
    });
  });
}
