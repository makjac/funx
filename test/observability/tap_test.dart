import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('TapExtension', () {
    test('calls onValue with result', () async {
      String? tapped;
      final func = funx.Func<String>(() async {
        return 'result';
      }).tap(onValue: (value) => tapped = value);

      final result = await func();
      expect(result, 'result');
      expect(tapped, 'result');
    });

    test('does not modify result', () async {
      final func = funx.Func<int>(() async {
        return 42;
      }).tap(onValue: (value) => value + 1);

      final result = await func();
      expect(result, 42);
    });

    test('calls onError on exception', () async {
      Object? caughtError;
      final func = funx.Func<String>(() async {
        throw Exception('test');
      }).tap(onError: (error, stack) => caughtError = error);

      expect(func.call, throwsException);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(caughtError, isA<Exception>());
    });

    test('rethrows errors', () async {
      final func = funx.Func<String>(() async {
        throw Exception('test');
      }).tap(onError: (e, s) {});

      expect(func.call, throwsException);
    });
  });

  group('TapExtension1', () {
    test('calls onValue with result', () async {
      String? tapped;
      final func = funx.Func1<int, String>((n) async {
        return 'result: $n';
      }).tap(onValue: (value) => tapped = value);

      final result = await func(42);
      expect(result, 'result: 42');
      expect(tapped, 'result: 42');
    });

    test('does not modify result', () async {
      final func = funx.Func1<int, int>((n) async {
        return n * 2;
      }).tap(onValue: (value) {});

      final result = await func(21);
      expect(result, 42);
    });
  });

  group('TapExtension2', () {
    test('calls onValue with result', () async {
      String? tapped;
      final func = funx.Func2<int, int, String>((a, b) async {
        return 'result: ${a + b}';
      }).tap(onValue: (value) => tapped = value);

      final result = await func(10, 32);
      expect(result, 'result: 42');
      expect(tapped, 'result: 42');
    });

    test('does not modify result', () async {
      final func = funx.Func2<int, int, int>((a, b) async {
        return a + b;
      }).tap(onValue: (value) {});

      final result = await func(40, 2);
      expect(result, 42);
    });
  });
}
