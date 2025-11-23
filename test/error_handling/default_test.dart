// ignore_for_file: deprecated_member_use test

import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('DefaultExtension', () {
    test('returns default value on error', () async {
      final func = funx.Func<int>(() async {
        throw const FormatException('test');
      }).defaultValue(defaultValue: 42);

      final result = await func();
      expect(result, 42);
    });

    test('returns normal value when no error', () async {
      final func = funx.Func<int>(() async => 100).defaultValue(
        defaultValue: 42,
      );

      final result = await func();
      expect(result, 100);
    });

    test('uses defaultIf predicate', () async {
      final func =
          funx.Func<int>(() async {
            throw StateError('test');
          }).defaultValue(
            defaultValue: 42,
            defaultIf: (e) => e is FormatException,
          );

      expect(func(), throwsStateError);
    });

    test('invokes onDefault callback', () async {
      var called = false;
      final func =
          funx.Func<int>(() async {
            throw const FormatException('test');
          }).defaultValue(
            defaultValue: 42,
            onDefault: () => called = true,
          );

      await func();
      expect(called, true);
    });
  });

  group('DefaultExtension1', () {
    test('returns default value on error', () async {
      final func = funx.Func1<String, int>((s) async {
        return int.parse(s);
      }).defaultValue(defaultValue: 0);

      final result = await func('invalid');
      expect(result, 0);
    });

    test('returns normal value when no error', () async {
      final func = funx.Func1<String, int>((s) async {
        return int.parse(s);
      }).defaultValue(defaultValue: 0);

      final result = await func('42');
      expect(result, 42);
    });

    test('uses defaultIf predicate', () async {
      final func =
          funx.Func1<String, int>((s) async {
            throw StateError('test');
          }).defaultValue(
            defaultValue: 0,
            defaultIf: (e) => e is FormatException,
          );

      expect(() => func('test'), throwsStateError);
    });
  });

  group('DefaultExtension2', () {
    test('returns default value on error', () async {
      final func = funx.Func2<int, int, double>((int a, int b) async {
        if (b == 0) throw const IntegerDivisionByZeroException();
        return a / b;
      }).defaultValue(defaultValue: 0);

      final result = await func(10, 0);
      expect(result, 0.0);
    });

    test('returns normal value when no error', () async {
      final func = funx.Func2<int, int, double>((int a, int b) async {
        return a / b;
      }).defaultValue(defaultValue: 0);

      final result = await func(10, 2);
      expect(result, 5.0);
    });

    test('uses defaultIf predicate', () async {
      final func =
          funx.Func2<int, int, double>((int a, int b) async {
            throw StateError('test');
          }).defaultValue(
            defaultValue: 0,
            defaultIf: (e) => e is IntegerDivisionByZeroException,
          );

      expect(() => func(10, 0), throwsStateError);
    });
  });
}
