import 'package:funx/src/concurrency/barrier.dart';
import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('Barrier', () {
    test('synchronizes N parties', () async {
      final barrier = Barrier(parties: 3);
      final results = <int>[];

      await Future.wait([
        barrier.await_().then((_) => results.add(1)),
        barrier.await_().then((_) => results.add(2)),
        barrier.await_().then((_) => results.add(3)),
      ]);

      expect(results.length, equals(3));
      expect(barrier.arrivedCount, equals(3)); // Non-cyclic barrier keeps count
    });

    test('blocks until all parties arrive', () async {
      final barrier = Barrier(parties: 2);
      var firstComplete = false;

      final future1 = barrier.await_().then((_) {
        firstComplete = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(firstComplete, isFalse);

      await barrier.await_();
      await future1;

      expect(firstComplete, isTrue);
    });

    test('cyclic mode allows reuse', () async {
      final barrier = Barrier(parties: 2, cyclic: true);

      // First cycle
      await Future.wait([
        barrier.await_(),
        barrier.await_(),
      ]);

      expect(barrier.arrivedCount, equals(0));

      // Second cycle
      await Future.wait([
        barrier.await_(),
        barrier.await_(),
      ]);

      expect(barrier.arrivedCount, equals(0));
    });
  });

  group('BarrierExtension', () {
    test('synchronizes function executions', () async {
      final barrier = Barrier(parties: 3);
      final results = <int>[];

      final func1 = funx.Func(() async {
        results.add(1);
        return 1;
      }).barrier(barrier);

      final func2 = funx.Func(() async {
        results.add(2);
        return 2;
      }).barrier(barrier);

      final func3 = funx.Func(() async {
        results.add(3);
        return 3;
      }).barrier(barrier);

      await Future.wait([func1(), func2(), func3()]);

      expect(results.length, equals(3));
    });
  });

  group('BarrierExtension1', () {
    test('works with parameters', () async {
      final barrier = Barrier(parties: 2);

      final func = funx.Func1<int, int>((n) async {
        return n * 2;
      }).barrier(barrier);

      final results = await Future.wait([
        func(5),
        func(10),
      ]);

      expect(results, equals([10, 20]));
    });
  });

  group('BarrierExtension2', () {
    test('works with two parameters', () async {
      final barrier = Barrier(parties: 2);

      final func = funx.Func2<int, int, int>((a, b) async {
        return a + b;
      }).barrier(barrier);

      final results = await Future.wait([
        func(1, 2),
        func(3, 4),
      ]);

      expect(results, equals([3, 7]));
    });
  });
}
