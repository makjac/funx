import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/core/types.dart';
import 'package:test/test.dart';

void main() {
  group('DelayExtension', () {
    test('before mode delays before execution', () async {
      final stopwatch = Stopwatch()..start();
      final func = funx.Func<int>(
        () async => 42,
      ).delay(const Duration(milliseconds: 100), mode: DelayMode.before);

      final result = await func();
      stopwatch.stop();

      expect(result, equals(42));
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
    });

    test('after mode delays after execution', () async {
      var executed = false;
      final stopwatch = Stopwatch()..start();

      final func = funx.Func<void>(() async {
        executed = true;
      }).delay(const Duration(milliseconds: 100), mode: DelayMode.after);

      await func();
      stopwatch.stop();

      expect(executed, isTrue);
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
    });

    test('both mode delays before and after', () async {
      final stopwatch = Stopwatch()..start();
      final func = funx.Func<int>(
        () async => 42,
      ).delay(const Duration(milliseconds: 50), mode: DelayMode.both);

      final result = await func();
      stopwatch.stop();

      expect(result, equals(42));
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
    });
  });

  group('DelayExtension1', () {
    test('delays function with one argument', () async {
      final stopwatch = Stopwatch()..start();
      final func = funx.Func1<int, int>(
        (n) async => n,
      ).delay(const Duration(milliseconds: 100));

      final result = await func(42);
      stopwatch.stop();

      expect(result, equals(42));
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
    });

    test('propagates errors after delay', () async {
      final func = funx.Func1<int, int>(
        (n) async => throw Exception('error'),
      ).delay(const Duration(milliseconds: 50));

      expect(() => func(42), throwsException);
    });
  });

  group('DelayExtension2', () {
    test('delays function with two arguments', () async {
      final stopwatch = Stopwatch()..start();
      final func = funx.Func2<int, int, int>(
        (a, b) async => a + b,
      ).delay(const Duration(milliseconds: 100));

      final result = await func(10, 20);
      stopwatch.stop();

      expect(result, equals(30));
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
    });

    test('both mode works correctly', () async {
      final stopwatch = Stopwatch()..start();
      final func = funx.Func2<int, int, int>(
        (a, b) async => a + b,
      ).delay(const Duration(milliseconds: 50), mode: DelayMode.both);

      await func(1, 1);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
    });
  });
}
