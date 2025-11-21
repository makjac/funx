import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/timing/idle_callback.dart';
import 'package:test/test.dart';

void main() {
  group('IdleCallbackExtension', () {
    test('executes when system is idle using default detector', () async {
      var executed = false;
      final func = funx.Func<void>(() async {
        executed = true;
      }).idleCallback();

      await func();
      expect(executed, isTrue);
    });

    test('uses custom idle detector', () async {
      var checkCount = 0;
      var executed = false;

      bool customDetector() {
        checkCount++;
        return checkCount >= 3; // Become idle after 3 checks
      }

      final func =
          funx.Func<void>(() async {
            executed = true;
          }).idleCallback(
            checkInterval: const Duration(milliseconds: 10),
            idleDetector: customDetector,
          );

      await func();

      expect(executed, isTrue);
      expect(checkCount, greaterThanOrEqualTo(3));
    });

    test('waits for idle state before executing', () async {
      var executed = false;
      var isIdle = false;

      final func =
          funx.Func<void>(() async {
            executed = true;
          }).idleCallback(
            checkInterval: const Duration(milliseconds: 10),
            idleDetector: () => isIdle,
          );

      final future = func();

      // Not executed while not idle
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(executed, isFalse);

      // Become idle
      isIdle = true;

      await future;
      expect(executed, isTrue);
    });

    test('returns correct value', () async {
      final func = funx.Func<int>(() async => 42).idleCallback();

      final result = await func();
      expect(result, equals(42));
    });
  });

  group('IdleCallbackExtension1', () {
    test('executes with argument when idle', () async {
      var lastValue = 0;
      final func = funx.Func1<int, void>((n) async {
        lastValue = n;
      }).idleCallback();

      await func(42);
      expect(lastValue, equals(42));
    });

    test('uses custom idle detector', () async {
      var checkCount = 0;

      final func = funx.Func1<int, int>((n) async => n * 2).idleCallback(
        checkInterval: const Duration(milliseconds: 10),
        idleDetector: () => ++checkCount >= 2,
      );

      final result = await func(21);
      expect(result, equals(42));
      expect(checkCount, greaterThanOrEqualTo(2));
    });
  });

  group('IdleCallbackExtension2', () {
    test('executes with arguments when idle', () async {
      var lastSum = 0;
      final func = funx.Func2<int, int, void>((a, b) async {
        lastSum = a + b;
      }).idleCallback();

      await func(10, 20);
      expect(lastSum, equals(30));
    });

    test('uses custom idle detector', () async {
      var checkCount = 0;

      final func = funx.Func2<int, int, int>((a, b) async => a + b)
          .idleCallback(
            checkInterval: const Duration(milliseconds: 10),
            idleDetector: () => ++checkCount >= 2,
          );

      final result = await func(15, 27);
      expect(result, equals(42));
      expect(checkCount, greaterThanOrEqualTo(2));
    });
  });

  group('defaultIdleDetector', () {
    test('always returns true', () {
      expect(defaultIdleDetector(), isTrue);
      expect(defaultIdleDetector(), isTrue);
      expect(defaultIdleDetector(), isTrue);
    });
  });

  group('Idle callback edge cases', () {
    test('handles never-idle scenario with timeout', () async {
      var executed = false;
      var callCount = 0;

      final func =
          funx.Func<void>(() async {
            executed = true;
          }).idleCallback(
            checkInterval: const Duration(milliseconds: 10),
            idleDetector: () => callCount++ > 10, // Eventually becomes idle
          );

      await func();
      expect(executed, isTrue);
      expect(callCount, greaterThan(10));
    });

    test('propagates errors', () async {
      final func = funx.Func<int>(
        () async => throw Exception('error'),
      ).idleCallback();

      expect(func(), throwsException);
    });
  });
}
