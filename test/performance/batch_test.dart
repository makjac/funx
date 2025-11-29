import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('BatchExtension', () {
    test('batches calls up to maxSize', () async {
      var batchCount = 0;
      final receivedBatches = <List<String>>[];

      final executor = Func1((List<String> items) async {
        batchCount++;
        receivedBatches.add(items);
      });

      final batched = Func1((String item) async => item).batch(
        executor: executor,
        maxSize: 3,
        maxWait: const Duration(seconds: 10),
      );

      final futures = [
        batched('a'),
        batched('b'),
        batched('c'), // Should trigger batch
      ];

      await Future.wait(futures);

      expect(batchCount, equals(1));
      expect(receivedBatches[0], equals(['a', 'b', 'c']));
    });

    test('batches calls after maxWait', () async {
      var batchCount = 0;
      final receivedBatches = <List<String>>[];

      final executor = Func1((List<String> items) async {
        batchCount++;
        receivedBatches.add(items);
      });

      final batched = Func1((String item) async => item).batch(
        executor: executor,
        maxSize: 10,
        maxWait: const Duration(milliseconds: 100),
      );

      unawaited(batched('a'));
      unawaited(batched('b'));

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(batchCount, equals(1));
      expect(receivedBatches[0], equals(['a', 'b']));
    });

    test('returns individual results', () async {
      final executor = Func1((List<int> items) async {
        // Batch executor doesn't need to return anything
      });

      final batched = Func1((int x) async => x * 2).batch(
        executor: executor,
        maxSize: 3,
        maxWait: const Duration(seconds: 1),
      );

      final results = await Future.wait([
        batched(1),
        batched(2),
        batched(3),
      ]);

      expect(results, equals([2, 4, 6]));
    });

    test('flush() executes pending batch immediately', () async {
      var batchCount = 0;
      final executor = Func1((List<String> items) async {
        batchCount++;
      });

      final batched =
          Func1((String item) async => item).batch(
                executor: executor,
                maxSize: 10,
                maxWait: const Duration(seconds: 10),
              )
              as BatchExtension<String, String>;

      unawaited(batched('a'));
      unawaited(batched('b'));

      expect(batchCount, equals(0)); // Not executed yet

      await batched.flush();

      expect(batchCount, equals(1)); // Executed after flush
    });

    test('cancel() clears pending batch', () async {
      var batchCount = 0;
      final executor = Func1((List<String> items) async {
        batchCount++;
      });

      final batched =
          Func1((String item) async => item).batch(
                executor: executor,
                maxSize: 10,
                maxWait: const Duration(seconds: 10),
              )
              as BatchExtension<String, String>;

      final future1 = batched('a');
      final future2 = batched('b');

      batched.cancel();

      await expectLater(future1, throwsStateError);
      await expectLater(future2, throwsStateError);
      expect(batchCount, equals(0)); // Never executed
    });
  });

  group('BatchExtension2', () {
    test('batches calls with argument pairs', () async {
      var batchCount = 0;
      final receivedBatches = <List<(int, int)>>[];

      final executor = Func1((List<(int, int)> pairs) async {
        batchCount++;
        receivedBatches.add(pairs);
      });

      final batched = Func2((int a, int b) async => a + b).batch(
        executor: executor,
        maxSize: 2,
        maxWait: const Duration(seconds: 10),
      );

      await Future.wait([
        batched(1, 2),
        batched(3, 4),
      ]);

      expect(batchCount, equals(1));
      expect(receivedBatches[0], equals([(1, 2), (3, 4)]));
    });

    test('returns individual results for pairs', () async {
      final executor = Func1((List<(int, int)> pairs) async {});

      final batched = Func2((int a, int b) async => a + b).batch(
        executor: executor,
        maxSize: 3,
        maxWait: const Duration(seconds: 1),
      );

      final results = await Future.wait([
        batched(1, 2),
        batched(3, 4),
        batched(5, 6),
      ]);

      expect(results, equals([3, 7, 11]));
    });

    test('flush() works for Func2', () async {
      var batchCount = 0;
      final executor = Func1((List<(int, int)> pairs) async {
        batchCount++;
      });

      final batched =
          Func2((int a, int b) async => a + b).batch(
                executor: executor,
                maxSize: 10,
                maxWait: const Duration(seconds: 10),
              )
              as BatchExtension2<int, int, int>;

      unawaited(batched(1, 2));
      await batched.flush();

      expect(batchCount, equals(1));
    });

    test('cancel() works for Func2', () async {
      var batchCount = 0;
      final executor = Func1((List<(int, int)> pairs) async {
        batchCount++;
      });

      final batched =
          Func2((int a, int b) async => a + b).batch(
                executor: executor,
                maxSize: 10,
                maxWait: const Duration(seconds: 10),
              )
              as BatchExtension2<int, int, int>;

      final future = batched(1, 2);
      batched.cancel();

      await expectLater(future, throwsStateError);
      expect(batchCount, equals(0));
    });
  });

  group('BatchExtension - Error handling', () {
    test('handles individual item errors', () async {
      final executor = Func1((List<int> items) async {});

      final batched =
          Func1((int x) async {
            if (x == 2) throw Exception('Error for 2');
            return x * 2;
          }).batch(
            executor: executor,
            maxSize: 3,
            maxWait: const Duration(seconds: 1),
          );

      final futures = [
        batched(1),
        batched(2),
        batched(3),
      ];

      final results = await Future.wait(
        futures.map((f) => f.catchError((e) => -1)),
      );

      expect(results[0], equals(2));
      expect(results[1], equals(-1)); // Error
      expect(results[2], equals(6));
    });

    test('fails all if batch executor fails', () async {
      final executor = Func1((List<int> items) async {
        throw Exception('Batch failed');
      });

      final batched = Func1((int x) async => x * 2).batch(
        executor: executor,
        maxSize: 3,
        maxWait: const Duration(seconds: 1),
      );

      final futures = [
        batched(1),
        batched(2),
        batched(3),
      ];

      for (final future in futures) {
        await expectLater(future, throwsException);
      }
    });

    test('handles individual item errors for Func2', () async {
      final executor = Func1((List<(int, int)> pairs) async {});

      final batched =
          Func2((int a, int b) async {
            if (a == 2) throw Exception('Error for 2');
            return a + b;
          }).batch(
            executor: executor,
            maxSize: 3,
            maxWait: const Duration(seconds: 1),
          );

      final futures = [
        batched(1, 10),
        batched(2, 20),
        batched(3, 30),
      ];

      final results = await Future.wait(
        futures.map((f) => f.catchError((e) => -1)),
      );

      expect(results[0], equals(11));
      expect(results[1], equals(-1)); // Error
      expect(results[2], equals(33));
    });
  });
}
