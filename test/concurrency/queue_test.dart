import 'package:funx/src/concurrency/queue.dart';
import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/core/types.dart';
import 'package:test/test.dart';

void main() {
  group('FunctionQueue', () {
    test('executes tasks sequentially with concurrency 1', () async {
      final queue = FunctionQueue<int, int>(
        concurrency: 1,
        mode: QueueMode.fifo,
      );
      final executionOrder = <int>[];

      final futures = <Future<int>>[];
      for (var i = 0; i < 3; i++) {
        final index = i;
        futures.add(
          queue.enqueue(index, (int arg) async {
            executionOrder.add(arg);
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return arg;
          }),
        );
      }

      final results = await Future.wait(futures);

      expect(executionOrder, equals([0, 1, 2]));
      expect(results, equals([0, 1, 2]));
    });

    test('executes tasks in parallel with higher concurrency', () async {
      final queue = FunctionQueue<int, int>(
        concurrency: 3,
        mode: QueueMode.fifo,
      );
      var maxConcurrent = 0;
      var currentConcurrent = 0;

      final futures = <Future<int>>[];
      for (var i = 0; i < 5; i++) {
        futures.add(
          queue.enqueue(i, (int arg) async {
            currentConcurrent++;
            if (currentConcurrent > maxConcurrent) {
              maxConcurrent = currentConcurrent;
            }
            await Future<void>.delayed(const Duration(milliseconds: 50));
            currentConcurrent--;
            return arg;
          }),
        );
      }

      await Future.wait(futures);
      expect(maxConcurrent, greaterThanOrEqualTo(2));
    });

    test('FIFO mode respects order', () async {
      final queue = FunctionQueue<int, int>(
        concurrency: 1,
        mode: QueueMode.fifo,
      );
      final executionOrder = <int>[];

      final futures = <Future<int>>[];
      for (var i = 0; i < 3; i++) {
        futures.add(
          queue.enqueue(i, (int arg) async {
            executionOrder.add(arg);
            return arg;
          }),
        );
      }

      await Future.wait(futures);
      expect(executionOrder, equals([0, 1, 2]));
    });

    test('LIFO mode executes in reverse', () async {
      final queue = FunctionQueue<int, int>(
        concurrency: 1,
        mode: QueueMode.lifo,
      );
      final executionOrder = <int>[];

      final futures = <Future<int>>[];
      for (var i = 0; i < 3; i++) {
        futures.add(
          queue.enqueue(i, (int arg) async {
            executionOrder.add(arg);
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return arg;
          }),
        );
      }

      await Future.wait(futures);
      expect(executionOrder, equals([0, 2, 1]));
    });
  });

  group('QueueExtension1', () {
    test('queues function executions', () async {
      final executionOrder = <int>[];

      final func = funx.Func1<int, int>((n) async {
        executionOrder.add(n);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return n * 2;
      }).queue(concurrency: 1);

      final results = await Future.wait([
        func(1),
        func(2),
        func(3),
      ]);

      expect(executionOrder, equals([1, 2, 3]));
      expect(results, equals([2, 4, 6]));
    });
  });

  group('QueueExtension2', () {
    test('queues function executions with two parameters', () async {
      final executionOrder = <int>[];

      final func = funx.Func2<int, int, int>((a, b) async {
        executionOrder.add(a + b);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return a + b;
      }).queue(concurrency: 1);

      final results = await Future.wait([
        func(1, 2),
        func(3, 4),
      ]);

      expect(executionOrder, equals([3, 7]));
      expect(results, equals([3, 7]));
    });
  });
}
