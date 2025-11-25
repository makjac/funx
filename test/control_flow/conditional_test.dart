import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('ConditionalExtension', () {
    test('executes when condition is true', () async {
      final func = funx.Func<String>(() async => 'executed');

      final conditional = func.when(
        condition: () => true,
      );

      expect(await conditional(), 'executed');
    });

    test(
      'throws StateError when condition is false and no otherwise',
      () async {
        final func = funx.Func<String>(() async => 'executed');

        final conditional = func.when(
          condition: () => false,
        );

        expect(conditional.call, throwsStateError);
      },
    );

    test('executes otherwise when condition is false', () async {
      final func = funx.Func<String>(() async => 'executed');

      final conditional = func.when(
        condition: () => false,
        otherwise: () async => 'alternative',
      );

      expect(await conditional(), 'alternative');
    });

    test('does not execute inner when condition is false', () async {
      var innerCalled = false;

      final func = funx.Func<String>(() async {
        innerCalled = true;
        return 'executed';
      });

      final conditional = func.when(
        condition: () => false,
        otherwise: () async => 'alternative',
      );

      await conditional();

      expect(innerCalled, false);
    });

    test('does not execute otherwise when condition is true', () async {
      var otherwiseCalled = false;

      final func = funx.Func<String>(() async => 'executed');

      final conditional = func.when(
        condition: () => true,
        otherwise: () async {
          otherwiseCalled = true;
          return 'alternative';
        },
      );

      await conditional();

      expect(otherwiseCalled, false);
    });
  });

  group('ConditionalExtension1', () {
    test('executes when condition is true', () async {
      final func = funx.Func1<int, String>((n) async => 'Result: $n');

      final conditional = func.when(
        condition: (n) => n > 0,
      );

      expect(await conditional(5), 'Result: 5');
    });

    test(
      'throws StateError when condition is false and no otherwise',
      () async {
        final func = funx.Func1<int, String>((n) async => 'Result: $n');

        final conditional = func.when(
          condition: (n) => n > 0,
        );

        expect(() => conditional(-5), throwsStateError);
      },
    );

    test('executes otherwise when condition is false', () async {
      final func = funx.Func1<int, String>((n) async => 'Result: $n');

      final conditional = func.when(
        condition: (n) => n > 0,
        otherwise: (n) async => 'Negative: $n',
      );

      expect(await conditional(5), 'Result: 5');
      expect(await conditional(-5), 'Negative: -5');
    });

    test('condition receives argument', () async {
      int? conditionArg;

      final func = funx.Func1<int, String>((n) async => 'Result: $n');

      final conditional = func.when(
        condition: (n) {
          conditionArg = n;
          return true;
        },
      );

      await conditional(42);

      expect(conditionArg, 42);
    });

    test('otherwise receives argument', () async {
      int? otherwiseArg;

      final func = funx.Func1<int, String>((n) async => 'Result: $n');

      final conditional = func.when(
        condition: (n) => false,
        otherwise: (n) async {
          otherwiseArg = n;
          return 'Alternative';
        },
      );

      await conditional(42);

      expect(otherwiseArg, 42);
    });
  });

  group('ConditionalExtension2', () {
    test('executes when condition is true', () async {
      final func = funx.Func2<int, int, String>(
        (a, b) async => 'Sum: ${a + b}',
      );

      final conditional = func.when(
        condition: (a, b) => a + b > 0,
      );

      expect(await conditional(3, 2), 'Sum: 5');
    });

    test(
      'throws StateError when condition is false and no otherwise',
      () async {
        final func = funx.Func2<int, int, String>(
          (a, b) async => 'Sum: ${a + b}',
        );

        final conditional = func.when(
          condition: (a, b) => a + b > 0,
        );

        expect(() => conditional(-3, -2), throwsStateError);
      },
    );

    test('executes otherwise when condition is false', () async {
      final func = funx.Func2<int, int, String>(
        (a, b) async => 'Sum: ${a + b}',
      );

      final conditional = func.when(
        condition: (a, b) => a + b > 0,
        otherwise: (a, b) async => 'Negative sum: ${a + b}',
      );

      expect(await conditional(3, 2), 'Sum: 5');
      expect(await conditional(-3, -2), 'Negative sum: -5');
    });

    test('condition receives both arguments', () async {
      int? conditionArg1;
      int? conditionArg2;

      final func = funx.Func2<int, int, String>(
        (a, b) async => 'Result',
      );

      final conditional = func.when(
        condition: (a, b) {
          conditionArg1 = a;
          conditionArg2 = b;
          return true;
        },
      );

      await conditional(10, 20);

      expect(conditionArg1, 10);
      expect(conditionArg2, 20);
    });

    test('otherwise receives both arguments', () async {
      int? otherwiseArg1;
      int? otherwiseArg2;

      final func = funx.Func2<int, int, String>(
        (a, b) async => 'Result',
      );

      final conditional = func.when(
        condition: (a, b) => false,
        otherwise: (a, b) async {
          otherwiseArg1 = a;
          otherwiseArg2 = b;
          return 'Alternative';
        },
      );

      await conditional(10, 20);

      expect(otherwiseArg1, 10);
      expect(otherwiseArg2, 20);
    });
  });

  group('Conditional edge cases', () {
    test('condition errors propagate', () async {
      final func = funx.Func1<int, String>((n) async => 'Result: $n');

      final conditional = func.when(
        condition: (n) => throw StateError('condition error'),
      );

      expect(() => conditional(5), throwsStateError);
    });

    test('inner function errors propagate when condition true', () async {
      final func = funx.Func1<int, String>(
        (n) async => throw StateError('inner error'),
      );

      final conditional = func.when(
        condition: (n) => true,
      );

      expect(() => conditional(5), throwsStateError);
    });

    test('otherwise errors propagate when condition false', () async {
      final func = funx.Func1<int, String>((n) async => 'Result: $n');

      final conditional = func.when(
        condition: (n) => false,
        otherwise: (n) async => throw StateError('otherwise error'),
      );

      expect(() => conditional(5), throwsStateError);
    });

    test('can be chained', () async {
      final func = funx.Func1<int, String>((n) async => 'Result: $n');

      final conditional = func
          .when(condition: (n) => n >= 0)
          .when(condition: (n) => n <= 100);

      expect(await conditional(50), 'Result: 50');
      expect(() => conditional(-1), throwsStateError);
      expect(() => conditional(101), throwsStateError);
    });
  });
}
