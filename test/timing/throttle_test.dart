import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/core/types.dart';
import 'package:funx/src/timing/throttle.dart';
import 'package:test/test.dart';

void main() {
  group('ThrottleExtension', () {
    test(
      'leading mode executes immediately, ignores subsequent calls',
      () async {
        var executeCount = 0;
        final func = funx.Func<int>(
          () async => ++executeCount,
        ).throttle(const Duration(milliseconds: 100));

        final result = await func();
        expect(result, equals(1));

        // Within throttle window - should throw
        expect(func(), throwsStateError);

        await Future<void>.delayed(const Duration(milliseconds: 150));

        // After window - should execute
        final result2 = await func();
        expect(result2, equals(2));
      },
    );

    test('trailing mode schedules execution at end of window', () async {
      var executeCount = 0;
      final func = funx.Func<int>(() async => ++executeCount).throttle(
        const Duration(milliseconds: 100),
        mode: ThrottleMode.trailing,
      );

      final future = func();

      // Not executed yet
      expect(executeCount, equals(0));

      await Future<void>.delayed(const Duration(milliseconds: 150));

      final result = await future;
      expect(result, equals(1));
    });

    test('can be reset', () async {
      var executeCount = 0;
      final throttled = ThrottleExtension(
        funx.Func<int>(() async => ++executeCount),
        const Duration(milliseconds: 100),
        ThrottleMode.leading,
      );

      await throttled();
      expect(executeCount, equals(1));

      throttled.reset();

      // Should execute immediately after reset
      await throttled();
      expect(executeCount, equals(2));
    });
  });

  group('ThrottleExtension1', () {
    test('throttles function with argument', () async {
      var lastValue = 0;
      final func = funx.Func1<int, int>((n) async {
        lastValue = n;
        return n;
      }).throttle(const Duration(milliseconds: 100));

      final result = await func(42);
      expect(result, equals(42));
      expect(lastValue, equals(42));

      expect(() => func(100), throwsStateError);
    });

    test('allows execution after window expires', () async {
      final func = funx.Func1<int, int>(
        (n) async => n,
      ).throttle(const Duration(milliseconds: 100));

      await func(1);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final result = await func(2);

      expect(result, equals(2));
    });
  });

  group('ThrottleExtension2', () {
    test('throttles function with two arguments', () async {
      var lastSum = 0;
      final func = funx.Func2<int, int, int>((a, b) async {
        return lastSum = a + b;
      }).throttle(const Duration(milliseconds: 100));

      final result = await func(10, 20);
      expect(result, equals(30));
      expect(lastSum, equals(30));

      expect(() => func(5, 5), throwsStateError);
    });

    test('can be reset', () async {
      final throttled = ThrottleExtension2(
        funx.Func2<int, int, int>((a, b) async => a + b),
        const Duration(milliseconds: 100),
        ThrottleMode.leading,
      );

      await throttled(1, 2);
      throttled.reset();
      final result = await throttled(3, 4);

      expect(result, equals(7));
    });
  });
}
