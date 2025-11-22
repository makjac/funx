import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('FallbackExtension', () {
    test('returns result on success', () async {
      final func = funx.Func<String>(
        () async => 'success',
      ).fallback(fallbackValue: 'fallback');

      final result = await func();
      expect(result, equals('success'));
    });

    test('returns fallback value on error', () async {
      final func = funx.Func<String>(
        () async => throw Exception('error'),
      ).fallback(fallbackValue: 'fallback');

      final result = await func();
      expect(result, equals('fallback'));
    });

    test('calls fallback function on error', () async {
      var fallbackCalled = false;
      final fallbackFunc = funx.Func<String>(() async {
        fallbackCalled = true;
        return 'fallback result';
      });

      final func = funx.Func<String>(
        () async => throw Exception('error'),
      ).fallback(fallbackFunction: fallbackFunc);

      final result = await func();
      expect(result, equals('fallback result'));
      expect(fallbackCalled, isTrue);
    });

    test('respects fallbackIf predicate', () async {
      final func =
          funx.Func<String>(
            () async => throw const FormatException('error'),
          ).fallback(
            fallbackValue: 'fallback',
            fallbackIf: (error) => error is StateError,
          );

      await expectLater(func(), throwsA(isA<FormatException>()));
    });

    test('calls onFallback callback', () async {
      Object? capturedError;
      final func = funx.Func<String>(() async => throw Exception('test error'))
          .fallback(
            fallbackValue: 'fallback',
            onFallback: (error) {
              capturedError = error;
            },
          );

      await func();
      expect(capturedError, isA<Exception>());
    });

    test('requires either fallbackValue or fallbackFunction', () {
      expect(
        () => funx.Func<String>(() async => 'test').fallback(),
        throwsA(isA<AssertionError>()),
      );
    });

    test('does not allow both fallbackValue and fallbackFunction', () {
      expect(
        () => funx.Func<String>(() async => 'test').fallback(
          fallbackValue: 'value',
          fallbackFunction: funx.Func<String>(() async => 'func'),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('can chain multiple fallbacks', () async {
      final func = funx.Func<String>(() async => throw Exception('primary'))
          .fallback(
            fallbackFunction: funx.Func<String>(
              () async => throw Exception('first fallback'),
            ),
          )
          .fallback(fallbackValue: 'final fallback');

      final result = await func();
      expect(result, equals('final fallback'));
    });
  });

  group('FallbackExtension1', () {
    test('returns fallback value on error with argument', () async {
      final func = funx.Func1<int, String>(
        (value) async => throw Exception('error'),
      ).fallback(fallbackValue: 'fallback');

      final result = await func(42);
      expect(result, equals('fallback'));
    });

    test('passes argument to fallback function', () async {
      final fallbackFunc = funx.Func1<int, String>(
        (value) async => 'fallback: $value',
      );

      final func = funx.Func1<int, String>(
        (value) async => throw Exception('error'),
      ).fallback(fallbackFunction: fallbackFunc);

      final result = await func(42);
      expect(result, equals('fallback: 42'));
    });
  });

  group('FallbackExtension2', () {
    test('returns fallback value on error with arguments', () async {
      final func = funx.Func2<int, String, String>(
        (n, str) async => throw Exception('error'),
      ).fallback(fallbackValue: 'fallback');

      final result = await func(42, 'test');
      expect(result, equals('fallback'));
    });

    test('passes arguments to fallback function', () async {
      final fallbackFunc = funx.Func2<int, String, String>(
        (n, str) async => 'fallback: $str $n',
      );

      final func = funx.Func2<int, String, String>(
        (n, str) async => throw Exception('error'),
      ).fallback(fallbackFunction: fallbackFunc);

      final result = await func(42, 'test');
      expect(result, equals('fallback: test 42'));
    });
  });
}
