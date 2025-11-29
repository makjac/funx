// ignore_for_file: avoid_catches_without_on_clauses test

import 'dart:async';

import 'package:funx/src/concurrency/rw_lock.dart';
import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('RWLock', () {
    test('allows concurrent readers', () async {
      final rwLock = RWLock();
      var concurrentReads = 0;
      var maxConcurrentReads = 0;

      final futures = <Future<void>>[];
      for (var i = 0; i < 3; i++) {
        futures.add(
          rwLock.acquireRead().then((_) async {
            concurrentReads++;
            if (concurrentReads > maxConcurrentReads) {
              maxConcurrentReads = concurrentReads;
            }
            await Future<void>.delayed(const Duration(milliseconds: 30));
            concurrentReads--;
            rwLock.releaseRead();
          }),
        );
      }

      await Future.wait(futures);
      expect(maxConcurrentReads, greaterThan(1));
    });

    test('serializes writers', () async {
      final rwLock = RWLock();
      final executionOrder = <int>[];

      // Execute writes sequentially
      await rwLock.acquireWrite();
      executionOrder.add(1);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      rwLock.releaseWrite();

      await rwLock.acquireWrite();
      executionOrder.add(2);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      rwLock.releaseWrite();

      expect(executionOrder, equals([1, 2]));
      expect(rwLock.isWriting, isFalse);
    });

    test('writer blocks readers', () async {
      final rwLock = RWLock();
      var readerExecuted = false;

      await rwLock.acquireWrite();

      final readerFuture = rwLock.acquireRead().then((_) {
        readerExecuted = true;
        rwLock.releaseRead();
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(readerExecuted, isFalse);

      rwLock.releaseWrite();
      await readerFuture;

      expect(readerExecuted, isTrue);
    });

    test('respects read timeout', () async {
      final rwLock = RWLock();

      await rwLock.acquireWrite();

      var timeoutOccurred = false;
      try {
        await rwLock.acquireRead(timeout: const Duration(milliseconds: 50));
      } catch (e) {
        if (e is TimeoutException) {
          timeoutOccurred = true;
        }
      }

      expect(timeoutOccurred, isTrue);
      rwLock.releaseWrite();
    });

    test('respects write timeout', () async {
      final rwLock = RWLock();

      await rwLock.acquireRead();

      var timeoutOccurred = false;
      try {
        await rwLock.acquireWrite(timeout: const Duration(milliseconds: 50));
      } catch (e) {
        if (e is TimeoutException) {
          timeoutOccurred = true;
        }
      }

      expect(timeoutOccurred, isTrue);
      rwLock.releaseRead();
    });

    test('readLock and writeLock helper methods', () async {
      final rwLock = RWLock();

      final readResult = await rwLock.readLock(() async {
        return 'read-data';
      });

      expect(readResult, equals('read-data'));
      expect(rwLock.readerCount, equals(0));

      final writeResult = await rwLock.writeLock(() async {
        return 'write-data';
      });

      expect(writeResult, equals('write-data'));
      expect(rwLock.isWriting, isFalse);
    });

    test('tracks readerCount', () async {
      final rwLock = RWLock();

      expect(rwLock.readerCount, equals(0));

      await rwLock.acquireRead();
      expect(rwLock.readerCount, equals(1));

      await rwLock.acquireRead();
      expect(rwLock.readerCount, equals(2));

      rwLock.releaseRead();
      expect(rwLock.readerCount, equals(1));

      rwLock.releaseRead();
      expect(rwLock.readerCount, equals(0));
    });
  });

  group('ReadLockExtension', () {
    test('allows concurrent reads', () async {
      final rwLock = RWLock();
      var concurrentReads = 0;
      var maxConcurrent = 0;

      final func = funx.Func(() async {
        concurrentReads++;
        if (concurrentReads > maxConcurrent) {
          maxConcurrent = concurrentReads;
        }
        await Future<void>.delayed(const Duration(milliseconds: 30));
        concurrentReads--;
        return 'read';
      }).readLock(rwLock);

      await Future.wait([
        func(),
        func(),
        func(),
      ]);

      expect(maxConcurrent, greaterThan(1));
    });

    test('provides access to rwLock instance', () async {
      final rwLock = RWLock();
      final wrapped = funx.Func(() async => 'data').readLock(rwLock);

      expect((wrapped as ReadLockExtension).rwLock, equals(rwLock));
    });
  });

  group('ReadLockExtension1', () {
    test('allows concurrent reads with parameters', () async {
      final rwLock = RWLock();

      final func = funx.Func1<int, String>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return 'read-$n';
      }).readLock(rwLock);

      final results = await Future.wait([
        func(1),
        func(2),
        func(3),
      ]);

      expect(results.length, equals(3));
    });

    test('provides access to rwLock instance', () async {
      final rwLock = RWLock();
      final wrapped = funx.Func1<int, String>(
        (n) async => 'data-$n',
      ).readLock(rwLock);

      expect((wrapped as ReadLockExtension1).rwLock, equals(rwLock));
    });
  });

  group('ReadLockExtension2', () {
    test('allows concurrent reads with two parameters', () async {
      final rwLock = RWLock();

      final func = funx.Func2<int, int, int>((a, b) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return a + b;
      }).readLock(rwLock);

      final results = await Future.wait([
        func(1, 2),
        func(3, 4),
        func(5, 6),
      ]);

      expect(results, equals([3, 7, 11]));
    });

    test('provides access to rwLock instance', () async {
      final rwLock = RWLock();
      final wrapped = funx.Func2<int, int, int>(
        (a, b) async => a + b,
      ).readLock(rwLock);

      expect((wrapped as ReadLockExtension2).rwLock, equals(rwLock));
    });
  });

  group('WriteLockExtension', () {
    test('serializes writes', () async {
      final rwLock = RWLock();
      final executionOrder = <int>[];

      final func = funx.Func(() async {
        final value = executionOrder.length + 1;
        executionOrder.add(value);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return value;
      }).writeLock(rwLock);

      // Execute sequentially
      await func();
      await func();
      await func();

      expect(executionOrder, equals([1, 2, 3]));
    });

    test('provides access to rwLock instance', () async {
      final rwLock = RWLock();
      final wrapped = funx.Func(() async => 'data').writeLock(rwLock);

      expect((wrapped as WriteLockExtension).rwLock, equals(rwLock));
    });
  });

  group('WriteLockExtension1', () {
    test('serializes writes with parameters', () async {
      final rwLock = RWLock();
      final executionOrder = <int>[];

      final func = funx.Func1<int, int>((n) async {
        executionOrder.add(n);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return n;
      }).writeLock(rwLock);

      // Execute sequentially
      await func(1);
      await func(2);
      await func(3);

      expect(executionOrder, equals([1, 2, 3]));
    });

    test('provides access to rwLock instance', () async {
      final rwLock = RWLock();
      final wrapped = funx.Func1<int, int>(
        (n) async => n * 2,
      ).writeLock(rwLock);

      expect((wrapped as WriteLockExtension1).rwLock, equals(rwLock));
    });
  });

  group('WriteLockExtension2', () {
    test('serializes writes with two parameters', () async {
      final rwLock = RWLock();
      final results = <int>[];

      final func = funx.Func2<int, int, int>((a, b) async {
        final result = a + b;
        results.add(result);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return result;
      }).writeLock(rwLock);

      // Execute sequentially
      await func(1, 2);
      await func(3, 4);
      await func(5, 6);

      expect(results, equals([3, 7, 11]));
    });

    test('provides access to rwLock instance', () async {
      final rwLock = RWLock();
      final wrapped = funx.Func2<int, int, int>(
        (a, b) async => a + b,
      ).writeLock(rwLock);

      expect((wrapped as WriteLockExtension2).rwLock, equals(rwLock));
    });
  });

  group('RWLock edge cases', () {
    test('handles rapid read requests', () async {
      final rwLock = RWLock();

      final futures = <Future<void>>[];
      for (var i = 0; i < 20; i++) {
        futures.add(
          rwLock.acquireRead().then((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            rwLock.releaseRead();
          }),
        );
      }

      await Future.wait(futures);
    });

    test('handles errors in critical section', () async {
      final rwLock = RWLock();

      await rwLock.acquireRead();

      var errorOccurred = false;
      try {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        rwLock.releaseRead();
        throw Exception('Test error');
      } catch (e) {
        errorOccurred = true;
      }

      expect(errorOccurred, isTrue);

      await rwLock.acquireRead();
      rwLock.releaseRead();
    });
  });
}
