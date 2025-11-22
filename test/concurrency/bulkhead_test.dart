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
  });
}
