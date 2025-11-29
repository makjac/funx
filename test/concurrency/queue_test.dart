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

    test('throws error when queue is full', () async {
      final queue = FunctionQueue<int, int>(
        concurrency: 1,
        mode: QueueMode.fifo,
        maxQueueSize: 2,
      );

      // Add tasks to fill queue
      final future1 = queue.enqueue(1, (arg) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return arg;
      });

      final future2 = queue.enqueue(2, (arg) async => arg);
      final future3 = queue.enqueue(3, (arg) async => arg);

      // Queue is full, next enqueue should throw
      expect(
        () => queue.enqueue(4, (arg) async => arg),
        throwsStateError,
      );

      await Future.wait([future1, future2, future3]);
    });

    test('priority mode sorts by priority', () async {
      final queue = FunctionQueue<int, int>(
        concurrency: 1,
        mode: QueueMode.priority,
        priorityFn: (arg) => arg,
      );
      final executionOrder = <int>[];

      // Hold the queue
      final firstFuture = queue.enqueue(0, (arg) async {
        executionOrder.add(arg);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return arg;
      });

      // Add tasks with different priorities while queue is busy
      final futures = <Future<int>>[];
      for (final priority in [1, 5, 3]) {
        futures.add(
          queue.enqueue(priority, (arg) async {
            executionOrder.add(arg);
            return arg;
          }),
        );
      }

      await firstFuture;
      await Future.wait(futures);

      // Should execute in order: 0 (first), then 5, 3, 1 (by priority)
      expect(executionOrder, equals([0, 5, 3, 1]));
    });

    test('tracks queueLength and runningTasks', () async {
      final queue = FunctionQueue<int, int>(
        concurrency: 2,
        mode: QueueMode.fifo,
      );

      expect(queue.queueLength, equals(0));
      expect(queue.runningTasks, equals(0));

      final futures = <Future<int>>[];
      for (var i = 0; i < 5; i++) {
        futures.add(
          queue.enqueue(i, (arg) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return arg;
          }),
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(queue.runningTasks, lessThanOrEqualTo(2));

      await Future.wait(futures);
      expect(queue.queueLength, equals(0));
      expect(queue.runningTasks, equals(0));
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

    test('tracks queueLength and runningTasks', () async {
      final func = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return n * 2;
      }).queue(concurrency: 1);

      final wrapped = func as QueueExtension1;
      expect(wrapped.queueLength, equals(0));
      expect(wrapped.runningTasks, equals(0));

      final futures = [func(1), func(2), func(3)];

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(wrapped.runningTasks, greaterThan(0));

      await Future.wait(futures);
      expect(wrapped.queueLength, equals(0));
      expect(wrapped.runningTasks, equals(0));
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

    test('tracks queueLength and runningTasks', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return a + b;
      }).queue(concurrency: 1);

      final wrapped = func as QueueExtension2;
      expect(wrapped.queueLength, equals(0));
      expect(wrapped.runningTasks, equals(0));

      final futures = [func(1, 2), func(3, 4), func(5, 6)];

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(wrapped.runningTasks, greaterThan(0));

      await Future.wait(futures);
      expect(wrapped.queueLength, equals(0));
      expect(wrapped.runningTasks, equals(0));
    });
  });
}
