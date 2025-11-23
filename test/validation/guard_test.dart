import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/validation/guard.dart';
import 'package:test/test.dart';

void main() {
  group('GuardException', () {
    test('toString includes message', () {
      final ex = GuardException('Failed');
      expect(ex.toString(), contains('Failed'));
    });

    test('toString includes value when provided', () {
      final ex = GuardException('Failed', value: 42);
      expect(ex.toString(), contains('42'));
    });
  });

  group('GuardExtension', () {
    test('executes when pre-condition passes', () async {
      const ready = true;
      final func = funx.Func<String>(() async => 'success').guard(
        preCondition: () => ready,
      );

      expect(await func(), 'success');
    });

    test('throws when pre-condition fails', () async {
      const ready = false;
      final func = funx.Func<String>(() async => 'success').guard(
        preCondition: () => ready,
      );

      expect(func(), throwsA(isA<GuardException>()));
    });

    test('uses custom pre-condition message', () async {
      final func = funx.Func<String>(() async => 'success').guard(
        preCondition: () => false,
        preConditionMessage: 'Custom pre failure',
      );

      try {
        await func();
        fail('Should have thrown');
      } on GuardException catch (e) {
        expect(e.message, 'Custom pre failure');
      }
    });

    test('executes inner function when pre-condition passes', () async {
      var executed = false;
      final func =
          funx.Func<String>(() async {
            executed = true;
            return 'success';
          }).guard(
            preCondition: () => true,
          );

      await func();
      expect(executed, true);
    });

    test('validates post-condition', () async {
      final func = funx.Func<int>(() async => 42).guard(
        postCondition: (result) => result > 0,
      );

      expect(await func(), 42);
    });

    test('throws when post-condition fails', () async {
      final func = funx.Func<int>(() async => -1).guard(
        postCondition: (result) => result > 0,
      );

      expect(func(), throwsA(isA<GuardException>()));
    });

    test('uses custom post-condition message', () async {
      final func = funx.Func<int>(() async => -1).guard(
        postCondition: (result) => result > 0,
        postConditionMessage: 'Must be positive',
      );

      try {
        await func();
        fail('Should have thrown');
      } on GuardException catch (e) {
        expect(e.message, 'Must be positive');
      }
    });

    test('includes value in post-condition exception', () async {
      final func = funx.Func<int>(() async => -1).guard(
        postCondition: (result) => result > 0,
        postConditionMessage: 'Must be positive',
      );

      try {
        await func();
        fail('Should have thrown');
      } on GuardException catch (e) {
        expect(e.message, 'Must be positive');
        expect(e.value, -1);
      }
    });

    test('validates both pre and post conditions', () async {
      const ready = true;
      final func = funx.Func<int>(() async => 100).guard(
        preCondition: () => ready,
        postCondition: (result) => result > 0,
      );

      expect(await func(), 100);
    });
  });

  group('GuardExtension1', () {
    test('validates pre-condition with argument', () async {
      final func = funx.Func1<int, String>((n) async => 'Value: $n').guard(
        preCondition: (n) => n > 0,
      );

      expect(await func(5), 'Value: 5');
      expect(func(-1), throwsA(isA<GuardException>()));
    });

    test('validates post-condition with result', () async {
      final func = funx.Func1<String, int>((s) async => int.tryParse(s) ?? -1)
          .guard(
            postCondition: (result) => result >= 0,
          );

      expect(await func('42'), 42);
      expect(func('invalid'), throwsA(isA<GuardException>()));
    });

    test('pre-condition receives argument value', () async {
      String? capturedArg;
      final func = funx.Func1<String, String>((s) async => s).guard(
        preCondition: (s) {
          capturedArg = s;
          return s.isNotEmpty;
        },
      );

      try {
        await func('');
      } catch (_) {
        // Expected
      }

      expect(capturedArg, '');
    });

    test('pre-condition has access to argument value', () async {
      var receivedNegative = false;
      final func = funx.Func1<int, String>((n) async => 'Value: $n').guard(
        preCondition: (n) {
          if (n < 0) receivedNegative = true;
          return n >= 0;
        },
        preConditionMessage: 'Value must be non-negative',
      );

      expect(func(-1), throwsA(isA<GuardException>()));
      expect(receivedNegative, true);
    });

    test('combines pre and post conditions for Func1', () async {
      final func = funx.Func1<int, int>((n) async => n * 2).guard(
        preCondition: (n) => n >= 0,
        postCondition: (result) => result <= 200,
      );

      expect(await func(50), 100);
      expect(func(-1), throwsA(isA<GuardException>()));
      expect(func(101), throwsA(isA<GuardException>()));
    });
  });

  group('GuardExtension2', () {
    test('validates pre-condition with two arguments', () async {
      final func = funx.Func2<int, int, double>((a, b) async => a / b).guard(
        preCondition: (a, b) => b != 0,
      );

      expect(await func(10, 2), 5.0);
      expect(func(10, 0), throwsA(isA<GuardException>()));
    });

    test('validates post-condition for Func2', () async {
      final func = funx.Func2<int, int, int>((a, b) async => a - b).guard(
        postCondition: (result) => result >= 0,
      );

      expect(await func(10, 5), 5);
      expect(func(5, 10), throwsA(isA<GuardException>()));
    });

    test('pre-condition receives both arguments', () async {
      int? capturedA;
      int? capturedB;
      final func = funx.Func2<int, int, int>((a, b) async => a + b).guard(
        preCondition: (a, b) {
          capturedA = a;
          capturedB = b;
          return a > 0 && b > 0;
        },
      );

      try {
        await func(-1, 5);
      } catch (_) {
        // Expected
      }

      expect(capturedA, -1);
      expect(capturedB, 5);
    });

    test('exception includes both arguments tuple', () async {
      final func = funx.Func2<int, int, int>((a, b) async => a + b).guard(
        preCondition: (a, b) => b != 0,
        preConditionMessage: 'Divisor cannot be zero',
      );

      try {
        await func(10, 0);
        fail('Should have thrown');
      } on GuardException catch (e) {
        expect(e.message, 'Divisor cannot be zero');
        expect(e.value, (10, 0));
      }
    });

    test('combines pre and post conditions for Func2', () async {
      final func = funx.Func2<int, int, int>((a, b) async => a + b).guard(
        preCondition: (a, b) => a >= 0 && b >= 0,
        postCondition: (result) => result <= 100,
      );

      expect(await func(30, 40), 70);
      expect(func(-1, 5), throwsA(isA<GuardException>()));
      expect(func(60, 50), throwsA(isA<GuardException>()));
    });
  });

  group('Guard edge cases', () {
    test('works with async pre-condition check', () async {
      final func = funx.Func<String>(() async => 'result').guard(
        preCondition: () {
          // Simulate async check
          return DateTime.now().millisecondsSinceEpoch > 0;
        },
      );

      expect(await func(), 'result');
    });

    test('works with complex post-condition', () async {
      final func = funx.Func<List<int>>(() async => [1, 2, 3]).guard(
        postCondition: (result) => result.isNotEmpty && result.length <= 10,
      );

      expect(await func(), [1, 2, 3]);
    });

    test('guard exception includes value in string', () async {
      final func = funx.Func<int>(() async => -5).guard(
        postCondition: (result) => result > 0,
      );

      try {
        await func();
        fail('Should have thrown');
      } on GuardException catch (e) {
        expect(e.toString(), contains('-5'));
      }
    });
  });
}
