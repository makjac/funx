import 'package:funx/src/concurrency/monitor.dart';
import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('Monitor', () {
    test('provides synchronized execution', () async {
      final monitor = Monitor();
      var executionCount = 0;

      await Future.wait([
        monitor.synchronized(() async {
          executionCount++;
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }),
        monitor.synchronized(() async {
          executionCount++;
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }),
      ]);

      expect(executionCount, equals(2));
    });

    test('notifies waiting threads', () async {
      final monitor = Monitor();
      var value = 0;

      final waiterFuture = monitor.synchronized(() async {
        await monitor.waitWhile(() => value == 0);
        return value;
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await monitor.synchronized(() async {
        value = 42;
        monitor.notify();
      });

      final result = await waiterFuture;
      expect(result, equals(42));
    });

    test('notifyAll wakes all waiters', () async {
      final monitor = Monitor();
      var value = 0;

      final waiters = [
        monitor.synchronized(() async {
          await monitor.waitWhile(() => value == 0);
          return 1;
        }),
        monitor.synchronized(() async {
          await monitor.waitWhile(() => value == 0);
          return 2;
        }),
      ];

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await monitor.synchronized(() async {
        value = 1;
        monitor.notifyAll();
      });

      final results = await Future.wait(waiters);
      expect(results.length, equals(2));
    });

    test('waitWhile with timeout', () async {
      final monitor = Monitor();
      const value = 0;

      final result = await monitor.synchronized(() async {
        final success = await monitor.waitWhile(
          () => value == 0,
          timeout: const Duration(milliseconds: 100),
        );
        return success;
      });

      expect(result, isFalse); // Should timeout
    });

    test('waitUntil delegates to waitWhile', () async {
      final monitor = Monitor();
      var value = 0;

      final waiterFuture = monitor.synchronized(() async {
        await monitor.waitUntil(() => value != 0);
        return value;
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await monitor.synchronized(() async {
        value = 99;
        monitor.notify();
      });

      final result = await waiterFuture;
      expect(result, equals(99));
    });
  });

  group('MonitorExtension', () {
    test('executes within monitor', () async {
      final monitor = Monitor();
      var executionCount = 0;

      final func = funx.Func(() async {
        executionCount++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return executionCount;
      }).monitor(monitor);

      await Future.wait([func(), func()]);

      expect(executionCount, equals(2));
    });

    test('provides access to monitor instance', () async {
      final monitor = Monitor();
      final wrapped = funx.Func(() async => 42).monitor(monitor);

      expect((wrapped as MonitorExtension).instance, equals(monitor));
    });
  });

  group('MonitorExtension1', () {
    test('works with parameters', () async {
      final monitor = Monitor();

      final func = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return n * 2;
      }).monitor(monitor);

      final results = await Future.wait([func(5), func(10)]);

      expect(results, equals([10, 20]));
    });

    test('provides access to monitor instance', () async {
      final monitor = Monitor();
      final wrapped = funx.Func1<int, int>((n) async => n * 2).monitor(monitor);

      expect((wrapped as MonitorExtension1).instance, equals(monitor));
    });
  });

  group('MonitorExtension2', () {
    test('works with two parameters', () async {
      final monitor = Monitor();

      final func = funx.Func2<int, int, int>((a, b) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return a + b;
      }).monitor(monitor);

      final results = await Future.wait([func(1, 2), func(3, 4)]);

      expect(results, equals([3, 7]));
    });

    test('provides access to monitor instance', () async {
      final monitor = Monitor();
      final wrapped = funx.Func2<int, int, int>(
        (a, b) async => a + b,
      ).monitor(monitor);

      expect((wrapped as MonitorExtension2).instance, equals(monitor));
    });
  });
}
