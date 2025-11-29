// ignore_for_file: inference_failure_on_untyped_parameter test

import 'dart:async';

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

    test('non-cyclic barrier becomes broken after first use', () async {
      final barrier = Barrier(parties: 2);

      await Future.wait([
        barrier.await_(),
        barrier.await_(),
      ]);

      expect(barrier.isBroken, isTrue);
      expect(barrier.await_, throwsStateError);
    });

    test('reset() clears broken state', () async {
      final barrier = Barrier(parties: 2);

      await Future.wait([
        barrier.await_(),
        barrier.await_(),
      ]);

      expect(barrier.isBroken, isTrue);

      barrier.reset();

      expect(barrier.isBroken, isFalse);
      expect(barrier.arrivedCount, equals(0));

      // Should work after reset
      await Future.wait([
        barrier.await_(),
        barrier.await_(),
      ]);

      expect(barrier.arrivedCount, equals(2));
    });

    test('executes barrierAction when all parties arrive', () async {
      var actionExecuted = false;
      final barrier = Barrier(
        parties: 3,
        barrierAction: () async {
          actionExecuted = true;
        },
      );

      await Future.wait([
        barrier.await_(),
        barrier.await_(),
        barrier.await_(),
      ]);

      expect(actionExecuted, isTrue);
    });

    test('timeout breaks barrier and calls onTimeout', () async {
      var timeoutCalled = false;
      final barrier = Barrier(
        parties: 3,
        timeout: const Duration(milliseconds: 100),
        onTimeout: () {
          timeoutCalled = true;
        },
      );

      // Only 2 parties arrive, barrier should timeout
      final future1 = barrier.await_();
      final future2 = barrier.await_();

      await expectLater(future1, throwsA(isA<TimeoutException>()));
      await expectLater(future2, throwsA(isA<TimeoutException>()));

      expect(timeoutCalled, isTrue);
      expect(barrier.isBroken, isTrue);
      expect(barrier.arrivedCount, equals(0));
    });

    test('timeout completes waiting parties with error', () async {
      final barrier = Barrier(
        parties: 3,
        timeout: const Duration(milliseconds: 100),
      );

      var error1Caught = false;
      var error2Caught = false;

      final future1 = barrier.await_().catchError((e) {
        error1Caught = e is TimeoutException;
      });

      final future2 = barrier.await_().catchError((e) {
        error2Caught = e is TimeoutException;
      });

      await Future.wait([future1, future2]);

      expect(error1Caught, isTrue);
      expect(error2Caught, isTrue);
      expect(barrier.isBroken, isTrue);
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

    test('provides access to barrier instance', () async {
      final barrier = Barrier(parties: 2);
      final wrapped = funx.Func(() async => 42).barrier(barrier);

      expect((wrapped as BarrierExtension).instance, equals(barrier));
      expect((wrapped as BarrierExtension).instance.parties, equals(2));
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

    test('provides access to barrier instance', () async {
      final barrier = Barrier(parties: 2);
      final wrapped = funx.Func1<int, int>((n) async => n).barrier(barrier);

      expect((wrapped as BarrierExtension1).instance, equals(barrier));
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

    test('provides access to barrier instance', () async {
      final barrier = Barrier(parties: 2);
      final wrapped = funx.Func2<int, int, int>(
        (a, b) async => a + b,
      ).barrier(barrier);

      expect((wrapped as BarrierExtension2).instance, equals(barrier));
    });
  });
}
