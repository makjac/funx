import 'dart:async';

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

    test('trailing mode handles multiple pending calls', () async {
      var executeCount = 0;
      final func = funx.Func<int>(() async => ++executeCount).throttle(
        const Duration(milliseconds: 100),
        mode: ThrottleMode.trailing,
      );

      final future1 = func();
      final future2 = func();
      final future3 = func();

      await Future<void>.delayed(const Duration(milliseconds: 150));

      final result1 = await future1;
      final result2 = await future2;
      final result3 = await future3;

      expect(result1, equals(1));
      expect(result2, equals(1));
      expect(result3, equals(1));
      expect(executeCount, equals(1));
    });

    test('both mode executes immediately and schedules trailing', () async {
      var executeCount = 0;
      final func = funx.Func<int>(() async => ++executeCount).throttle(
        const Duration(milliseconds: 100),
        mode: ThrottleMode.both,
      );

      final result1 = await func();
      expect(result1, equals(1));

      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Both mode should have executed trailing as well
      expect(executeCount, equals(2));
    });

    test('both mode handles calls in throttle window', () async {
      var executeCount = 0;
      final func = funx.Func<int>(() async => ++executeCount).throttle(
        const Duration(milliseconds: 100),
        mode: ThrottleMode.both,
      );

      await func(); // Leading execution
      final trailing = func(); // Schedules trailing

      await Future<void>.delayed(const Duration(milliseconds: 150));

      await trailing;
      expect(
        executeCount,
        equals(3),
      ); // 1 leading + 1 trailing from first + 1 trailing from second
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

    test('trailing mode works with arguments', () async {
      var executeCount = 0;
      final func =
          funx.Func1<int, int>((n) async {
            executeCount++;
            return n;
          }).throttle(
            const Duration(milliseconds: 100),
            mode: ThrottleMode.trailing,
          );

      final future = func(42);
      expect(executeCount, equals(0));

      await Future<void>.delayed(const Duration(milliseconds: 150));

      final result = await future;
      expect(result, equals(42));
      expect(executeCount, equals(1));
    });

    test('both mode works with arguments', () async {
      var executeCount = 0;
      final func =
          funx.Func1<int, int>((n) async {
            executeCount++;
            return n;
          }).throttle(
            const Duration(milliseconds: 100),
            mode: ThrottleMode.both,
          );

      final result = await func(42);
      expect(result, equals(42));

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(executeCount, equals(2));
    });

    test('reset works for Func1', () async {
      final throttled = ThrottleExtension1(
        funx.Func1<int, int>((n) async => n),
        const Duration(milliseconds: 100),
        ThrottleMode.leading,
      );

      await throttled(1);
      throttled.reset();
      final result = await throttled(2);

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

    test('trailing mode works with two arguments', () async {
      var executeCount = 0;
      final func =
          funx.Func2<int, int, int>((a, b) async {
            executeCount++;
            return a + b;
          }).throttle(
            const Duration(milliseconds: 100),
            mode: ThrottleMode.trailing,
          );

      final future = func(10, 20);
      expect(executeCount, equals(0));

      await Future<void>.delayed(const Duration(milliseconds: 150));

      final result = await future;
      expect(result, equals(30));
      expect(executeCount, equals(1));
    });

    test('both mode works with two arguments', () async {
      var executeCount = 0;
      final func =
          funx.Func2<int, int, int>((a, b) async {
            executeCount++;
            return a + b;
          }).throttle(
            const Duration(milliseconds: 100),
            mode: ThrottleMode.both,
          );

      final result = await func(5, 10);
      expect(result, equals(15));

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(executeCount, equals(2));
    });

    test('reset clears timer and pending state', () async {
      final throttled = ThrottleExtension(
        funx.Func<int>(() async => 42),
        const Duration(milliseconds: 100),
        ThrottleMode.trailing,
      );

      unawaited(throttled()); // Schedule trailing
      throttled.reset(); // Should cancel timer and clear state

      // After reset, should be able to execute immediately
      final result = await throttled();
      expect(result, equals(42));
    });

    test('trailing mode multiple calls return same pending future', () async {
      var executeCount = 0;
      final throttled = ThrottleExtension(
        funx.Func<int>(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return ++executeCount;
        }),
        const Duration(milliseconds: 100),
        ThrottleMode.trailing,
      );

      final future1 = throttled();
      final future2 = throttled();

      await Future<void>.delayed(const Duration(milliseconds: 150));

      final result1 = await future1;
      final result2 = await future2;

      // Both futures should return same result
      expect(result1, equals(result2));
      expect(executeCount, equals(1));
    });

    test('trailing mode handles timer cancellation correctly', () async {
      var executeCount = 0;
      final throttled = ThrottleExtension(
        funx.Func<int>(() async => ++executeCount),
        const Duration(milliseconds: 200),
        ThrottleMode.trailing,
      );

      // First call schedules trailing
      unawaited(throttled());

      // Second call before first timer fires - should cancel first timer
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final future = throttled();

      // Wait for trailing to execute
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final result = await future;
      expect(result, equals(1));
      expect(executeCount, equals(1));
    });
  });
}
