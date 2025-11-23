// ignore_for_file: deprecated_member_use test

import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('CatchExtension', () {
    test('catches specific error type with handler', () async {
      final func =
          funx.Func<int>(() async {
            throw const FormatException('test');
          }).catchError(
            handlers: {
              FormatException: (e) async => 42,
            },
          );

      final result = await func();
      expect(result, 42);
    });

    test('uses catchAll for unmatched error types', () async {
      final func =
          funx.Func<int>(() async {
            throw StateError('test');
          }).catchError(
            handlers: {
              FormatException: (e) async => 42,
            },
            catchAll: (e) async => 99,
          );

      final result = await func();
      expect(result, 99);
    });

    test('rethrows when no handler matches and no catchAll', () async {
      final func =
          funx.Func<int>(() async {
            throw StateError('test');
          }).catchError(
            handlers: {
              FormatException: (e) async => 42,
            },
          );

      expect(func(), throwsStateError);
    });

    test('invokes onCatch callback', () async {
      Object? caughtError;
      final func =
          funx.Func<int>(() async {
            throw const FormatException('test');
          }).catchError(
            handlers: {
              FormatException: (e) async => 42,
            },
            onCatch: (Object e) => caughtError = e,
          );

      await func();
      expect(caughtError, isA<FormatException>());
    });

    test('handles multiple error types', () async {
      final func1 =
          funx.Func<int>(() async {
            throw const FormatException('test');
          }).catchError(
            handlers: {
              FormatException: (e) async => 1,
              StateError: (e) async => 2,
            },
          );

      final func2 =
          funx.Func<int>(() async {
            throw StateError('test');
          }).catchError(
            handlers: {
              FormatException: (e) async => 1,
              StateError: (e) async => 2,
            },
          );

      expect(await func1(), 1);
      expect(await func2(), 2);
    });

    test('passes when no error occurs', () async {
      final func = funx.Func<int>(() async => 100).catchError(
        handlers: {
          FormatException: (e) async => 42,
        },
      );

      final result = await func();
      expect(result, 100);
    });
  });

  group('CatchExtension1', () {
    test('catches specific error type with handler', () async {
      final func =
          funx.Func1<String, int>((s) async {
            throw const FormatException('test');
          }).catchError(
            handlers: {
              FormatException: (e) async => -1,
            },
          );

      final result = await func('test');
      expect(result, -1);
    });

    test('uses catchAll for unmatched error types', () async {
      final func =
          funx.Func1<String, int>((s) async {
            throw StateError('test');
          }).catchError(
            handlers: {
              FormatException: (e) async => -1,
            },
            catchAll: (e) async => -999,
          );

      final result = await func('test');
      expect(result, -999);
    });

    test('rethrows when no handler matches', () async {
      final func =
          funx.Func1<String, int>((s) async {
            throw StateError('test');
          }).catchError(
            handlers: {
              FormatException: (e) async => -1,
            },
          );

      expect(() => func('test'), throwsStateError);
    });

    test('invokes onCatch callback', () async {
      Object? caughtError;
      final func =
          funx.Func1<String, int>((s) async {
            throw const FormatException('test');
          }).catchError(
            handlers: {
              FormatException: (e) async => -1,
            },
            onCatch: (Object e) => caughtError = e,
          );

      await func('test');
      expect(caughtError, isA<FormatException>());
    });
  });

  group('CatchExtension2', () {
    test('catches specific error type with handler', () async {
      final func =
          funx.Func2<int, int, double>((a, b) async {
            throw const IntegerDivisionByZeroException();
          }).catchError(
            handlers: {
              IntegerDivisionByZeroException: (e) async => 0.0,
            },
          );

      final result = await func(10, 0);
      expect(result, 0.0);
    });

    test('uses catchAll for unmatched error types', () async {
      final func =
          funx.Func2<int, int, double>((a, b) async {
            throw StateError('test');
          }).catchError(
            handlers: {
              FormatException: (e) async => 0.0,
            },
            catchAll: (e) async => -1.0,
          );

      final result = await func(10, 2);
      expect(result, -1.0);
    });

    test('rethrows when no handler matches', () async {
      final func =
          funx.Func2<int, int, double>((a, b) async {
            throw StateError('test');
          }).catchError(
            handlers: {
              FormatException: (e) async => 0.0,
            },
          );

      expect(() => func(10, 2), throwsStateError);
    });

    test('invokes onCatch callback', () async {
      Object? caughtError;
      final func =
          funx.Func2<int, int, double>((a, b) async {
            throw const IntegerDivisionByZeroException();
          }).catchError(
            handlers: {
              IntegerDivisionByZeroException: (e) async => 0.0,
            },
            onCatch: (Object e) => caughtError = e,
          );

      await func(10, 0);
      expect(caughtError, isA<IntegerDivisionByZeroException>());
    });

    test('passes when no error occurs', () async {
      final func =
          funx.Func2<int, int, double>((int a, int b) async {
            return a / b;
          }).catchError(
            handlers: {
              IntegerDivisionByZeroException: (e) async => 0.0,
            },
          );

      final result = await func(10, 2);
      expect(result, 5.0);
    });
  });
}
