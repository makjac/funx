import 'dart:async';

import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('TimeoutExtension', () {
    test('completes if execution finishes in time', () async {
      final func = funx.Func<int>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 42;
      }).timeout(const Duration(milliseconds: 200));

      expect(await func(), equals(42));
    });

    test('throws TimeoutException if execution takes too long', () async {
      final func = funx.Func<int>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return 42;
      }).timeout(const Duration(milliseconds: 50));

      expect(func(), throwsA(isA<TimeoutException>()));
    });

    test('uses onTimeout callback when provided', () async {
      final func = funx.Func<int>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return 42;
      }).timeout(const Duration(milliseconds: 50), onTimeout: () => 0);

      expect(await func(), equals(0));
    });
  });

  group('TimeoutExtension1', () {
    test('completes if execution finishes in time', () async {
      final func = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return n * 2;
      }).timeout(const Duration(milliseconds: 200));

      expect(await func(21), equals(42));
    });

    test('throws TimeoutException if execution takes too long', () async {
      final func = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return n;
      }).timeout(const Duration(milliseconds: 50));

      expect(() => func(42), throwsA(isA<TimeoutException>()));
    });

    test('uses onTimeout callback', () async {
      final func = funx.Func1<int, int>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return n;
      }).timeout(const Duration(milliseconds: 50), onTimeout: () => -1);

      expect(await func(42), equals(-1));
    });
  });

  group('TimeoutExtension2', () {
    test('completes if execution finishes in time', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return a + b;
      }).timeout(const Duration(milliseconds: 200));

      expect(await func(10, 20), equals(30));
    });

    test('throws TimeoutException if execution takes too long', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return a + b;
      }).timeout(const Duration(milliseconds: 50));

      expect(() => func(10, 20), throwsA(isA<TimeoutException>()));
    });

    test('uses onTimeout callback', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return a + b;
      }).timeout(const Duration(milliseconds: 50), onTimeout: () => 0);

      expect(await func(10, 20), equals(0));
    });
  });

  group('Timeout edge cases', () {
    test('works with very short timeouts', () async {
      final func = funx.Func<int>(
        () async => 42,
      ).timeout(const Duration(microseconds: 1));

      // This might complete or timeout depending on system load
      try {
        await func();
      } on TimeoutException {
        // Expected in most cases
      }
    });

    test('works with zero delay functions', () async {
      final func = funx.Func<int>(
        () async => 42,
      ).timeout(const Duration(seconds: 1));

      expect(await func(), equals(42));
    });
  });
}
