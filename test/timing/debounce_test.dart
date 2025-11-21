import 'dart:async';

import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/core/types.dart';
import 'package:funx/src/timing/debounce.dart';
import 'package:test/test.dart';

void main() {
  group('DebounceExtension', () {
    test('trailing mode executes after delay', () async {
      var executeCount = 0;
      final func = funx.Func<int>(
        () async => ++executeCount,
      ).debounce(const Duration(milliseconds: 100));

      // Call multiple times rapidly
      unawaited(func());
      unawaited(func());
      final future = func();

      // Should not execute yet
      expect(executeCount, equals(0));

      // Wait for debounce
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final result = await future;
      expect(result, equals(1)); // Only executed once
      expect(executeCount, equals(1));
    });

    test('leading mode executes immediately on first call', () async {
      var executeCount = 0;
      final func = funx.Func<int>(
        () async => ++executeCount,
      ).debounce(const Duration(milliseconds: 100), mode: DebounceMode.leading);

      final result = await func();
      expect(result, equals(1)); // Executed immediately
      expect(executeCount, equals(1));

      // Subsequent calls within window throw error
      expect(func(), throwsStateError);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(executeCount, equals(1)); // Still only one execution
    });

    test('both mode executes on first and last call', () async {
      var executeCount = 0;
      final func = funx.Func<int>(
        () async => ++executeCount,
      ).debounce(const Duration(milliseconds: 100), mode: DebounceMode.both);

      final firstResult = await func(); // Leading execution
      expect(firstResult, equals(1));

      // Make more calls
      unawaited(func());
      final lastFuture = func();

      // Wait for trailing execution
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final lastResult = await lastFuture;
      expect(lastResult, equals(2)); // Trailing execution
      expect(executeCount, equals(2));
    });

    test('can be cancelled', () async {
      var executeCount = 0;
      final debounced = DebounceExtension(
        funx.Func<int>(() async => ++executeCount),
        const Duration(milliseconds: 100),
        DebounceMode.trailing,
      );

      unawaited(debounced());

      // Cancel before execution
      debounced.cancel();

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(executeCount, equals(0)); // Never executed
    });
  });

  group('DebounceExtension1', () {
    test('trailing mode uses last argument', () async {
      var lastValue = 0;
      final func = funx.Func1<int, int>((n) async {
        lastValue = n;
        return n;
      }).debounce(const Duration(milliseconds: 100));

      unawaited(func(1));
      unawaited(func(2));
      expect(lastValue, equals(0));
      final future = func(3);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      final result = await future;
      expect(result, equals(3));
      expect(lastValue, equals(3));
    });

    test('leading mode uses first argument', () async {
      var lastValue = 0;
      final func = funx.Func1<int, int>(
        (n) async {
          lastValue = n;
          return n;
        },
      ).debounce(const Duration(milliseconds: 100), mode: DebounceMode.leading);

      final result = await func(42);
      expect(result, equals(42));
      expect(lastValue, equals(42));

      expect(func(100), throwsStateError); // Ignored

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(lastValue, equals(42)); // Only first value was used
    });

    test('can be cancelled', () async {
      var executeCount = 0;
      final debounced = DebounceExtension1(
        funx.Func1<int, int>((n) async {
          executeCount++;
          return n;
        }),
        const Duration(milliseconds: 100),
        DebounceMode.trailing,
      );

      unawaited(debounced(42));

      // Cancel before execution
      debounced.cancel();

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(executeCount, equals(0));
    });
  });

  group('DebounceExtension2', () {
    test('trailing mode executes with last arguments', () async {
      var lastSum = 0;
      final func = funx.Func2<int, int, int>((a, b) async {
        return lastSum = a + b;
      }).debounce(const Duration(milliseconds: 100));

      unawaited(func(1, 1));
      unawaited(func(2, 2));
      final future = func(3, 3);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      final result = await future;
      expect(result, equals(6));
      expect(lastSum, equals(6));
    });

    test('leading mode executes immediately', () async {
      var executeCount = 0;
      final func = funx.Func2<int, int, int>(
        (a, b) async {
          executeCount++;
          return a + b;
        },
      ).debounce(const Duration(milliseconds: 100), mode: DebounceMode.leading);

      final result = await func(10, 20);
      expect(result, equals(30));
      expect(executeCount, equals(1));

      expect(func(5, 5), throwsStateError); // Ignored
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(executeCount, equals(1));
    });

    test('can be cancelled', () async {
      var executeCount = 0;
      final debounced = DebounceExtension2(
        funx.Func2<int, int, int>((a, b) async {
          executeCount++;
          return a + b;
        }),
        const Duration(milliseconds: 100),
        DebounceMode.trailing,
      );

      unawaited(debounced(10, 20));

      // Cancel before execution
      debounced.cancel();

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(executeCount, equals(0));
    });
  });

  group('Debounce edge cases', () {
    test('handles rapid successive calls correctly', () async {
      var executeCount = 0;
      final func = funx.Func<int>(
        () async => ++executeCount,
      ).debounce(const Duration(milliseconds: 100));

      // Make 10 rapid calls
      for (var i = 0; i < 10; i++) {
        unawaited(func());
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      // All calls should be within the debounce window
      expect(executeCount, equals(0));

      // Wait for final execution
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(executeCount, equals(1)); // Only one execution
    });

    test('resets after debounce window expires', () async {
      var executeCount = 0;
      final func = funx.Func<int>(
        () async => ++executeCount,
      ).debounce(const Duration(milliseconds: 100), mode: DebounceMode.leading);

      await func(); // First execution
      expect(executeCount, equals(1));

      // Wait for window to expire
      await Future<void>.delayed(const Duration(milliseconds: 150));

      await func(); // Second execution (new window)
      expect(executeCount, equals(2));
    });
  });
}
