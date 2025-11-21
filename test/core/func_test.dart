import 'dart:async';

import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('Func', () {
    test('wraps and executes async function', () async {
      final func = funx.Func<int>(() async => 42);
      expect(await func(), equals(42));
    });

    test('can be called multiple times', () async {
      var counter = 0;
      final func = funx.Func<int>(() async => ++counter);

      expect(await func(), equals(1));
      expect(await func(), equals(2));
      expect(await func(), equals(3));
    });

    test('propagates errors', () async {
      final func = funx.Func<int>(() async => throw Exception('error'));
      await expectLater(func(), throwsException);
    });

    test('can debounce', () async {
      var counter = 0;
      final func = funx.Func<int>(
        () async => ++counter,
      ).debounce(const Duration(milliseconds: 50));

      // Call multiple times rapidly
      unawaited(func());
      unawaited(func());
      final future = func();

      // Wait for debounce
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = await future;
      expect(result, equals(1)); // Should only execute once
    });

    test('can throttle', () async {
      var counter = 0;
      final func = funx.Func<int>(
        () async => ++counter,
      ).throttle(const Duration(milliseconds: 100));

      final result1 = await func();
      expect(result1, equals(1));

      // This should be throttled
      await expectLater(func(), throwsStateError);
    });

    test('can delay', () async {
      final stopwatch = Stopwatch()..start();
      final func = funx.Func<int>(
        () async => 42,
      ).delay(const Duration(milliseconds: 100));

      final result = await func();
      stopwatch.stop();

      expect(result, equals(42));
      expect(
        stopwatch.elapsedMilliseconds,
        greaterThanOrEqualTo(100),
      );
    });

    test('can timeout', () async {
      final func = funx.Func<int>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return 42;
      }).timeout(const Duration(milliseconds: 50));

      expect(func(), throwsA(isA<Exception>()));
    });

    test('chains multiple decorators', () async {
      var counter = 0;
      final func = funx.Func<int>(() async => ++counter)
          .delay(const Duration(milliseconds: 50))
          .timeout(const Duration(seconds: 1));

      expect(await func(), equals(1));
    });
  });

  group('Func1', () {
    test('wraps and executes async function with one argument', () async {
      final func = funx.Func1<int, String>((n) async => 'Value: $n');
      expect(await func(42), equals('Value: 42'));
    });

    test('passes argument correctly', () async {
      final func = funx.Func1<String, int>((str) async => str.length);
      expect(await func('hello'), equals(5));
    });

    test('can be called multiple times with different arguments', () async {
      final func = funx.Func1<int, int>((n) async => n * 2);

      expect(await func(5), equals(10));
      expect(await func(10), equals(20));
      expect(await func(15), equals(30));
    });

    test('propagates errors', () async {
      final func = funx.Func<int>(() async => throw Exception('error'));
      expect(func(), throwsException);
    });

    test('can debounce', () async {
      var lastValue = 0;
      final func = funx.Func1<int, int>((n) async {
        lastValue = n;
        return n;
      }).debounce(const Duration(milliseconds: 50));

      await func(1);
      await func(2);
      final future = func(3);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = await future;
      expect(result, equals(3));
      expect(lastValue, equals(3));
    });

    test('can throttle', () async {
      final func = funx.Func1<int, int>(
        (n) async => n,
      ).throttle(const Duration(milliseconds: 100));

      final result = await func(42);
      expect(result, equals(42));

      expect(() => func(43), throwsStateError);
    });

    test('can delay', () async {
      final stopwatch = Stopwatch()..start();
      final func = funx.Func1<int, int>(
        (n) async => n,
      ).delay(const Duration(milliseconds: 100));

      final result = await func(42);
      stopwatch.stop();

      expect(result, equals(42));
      expect(
        stopwatch.elapsedMilliseconds,
        greaterThanOrEqualTo(100),
      );
    });

    test('can timeout', () async {
      final func = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return n;
      }).timeout(const Duration(milliseconds: 50));

      expect(() => func(42), throwsA(isA<Exception>()));
    });
  });

  group('Func2', () {
    test('wraps and executes async function with two arguments', () async {
      final func = funx.Func2<int, int, int>((a, b) async => a + b);
      expect(await func(10, 20), equals(30));
    });

    test('passes both arguments correctly', () async {
      final func = funx.Func2<String, int, String>(
        (str, times) async => str * times,
      );
      expect(await func('x', 3), equals('xxx'));
    });

    test('can be called multiple times', () async {
      final func = funx.Func2<int, int, int>((a, b) async => a * b);

      expect(await func(2, 3), equals(6));
      expect(await func(4, 5), equals(20));
      expect(await func(10, 10), equals(100));
    });

    test('propagates errors', () async {
      final func = funx.Func2<int, int, int>(
        (a, b) async => throw Exception('error'),
      );
      expect(() => func(1, 2), throwsException);
    });

    test('can debounce', () async {
      var lastSum = 0;
      final func = funx.Func2<int, int, int>((a, b) async {
        return lastSum = a + b;
      }).debounce(const Duration(milliseconds: 50));

      await func(1, 1);
      await func(2, 2);
      final future = func(3, 3);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = await future;
      expect(result, equals(6));
      expect(lastSum, equals(6));
    });

    test('can throttle', () async {
      final func = funx.Func2<int, int, int>(
        (a, b) async => a + b,
      ).throttle(const Duration(milliseconds: 100));

      final result = await func(10, 20);
      expect(result, equals(30));

      expect(() => func(5, 5), throwsStateError);
    });

    test('can delay', () async {
      final stopwatch = Stopwatch()..start();
      final func = funx.Func2<int, int, int>(
        (a, b) async => a + b,
      ).delay(const Duration(milliseconds: 100));

      final result = await func(10, 20);
      stopwatch.stop();

      expect(result, equals(30));
      expect(
        stopwatch.elapsedMilliseconds,
        greaterThanOrEqualTo(100),
      );
    });

    test('can timeout', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return a + b;
      }).timeout(const Duration(milliseconds: 50));

      expect(() => func(10, 20), throwsA(isA<Exception>()));
    });
  });
}
