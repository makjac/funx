import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('TransformExtension', () {
    test('transforms result to different type', () async {
      final func = funx.Func(
        () async => 42,
      ).transform<String>((n) => 'Number: $n');

      expect(await func(), 'Number: 42');
    });

    test('chains multiple transformations', () async {
      final func = funx.Func(
        () async => 10,
      ).transform<int>((n) => n * 2).transform<String>((n) => 'Result: $n');

      expect(await func(), 'Result: 20');
    });

    test('transforms to complex type', () async {
      final func = funx.Func(() async => 'test').transform<Map<String, int>>(
        (s) => {'length': s.length},
      );

      expect(await func(), {'length': 4});
    });

    test('propagates errors from inner function', () async {
      final func = funx.Func<int>(
        () async => throw StateError('test'),
      ).transform<String>((n) => '$n');

      expect(func(), throwsStateError);
    });

    test('propagates errors from mapper', () async {
      final func = funx.Func(() async => 42).transform<String>(
        (n) => throw ArgumentError('mapper error'),
      );

      expect(func(), throwsArgumentError);
    });
  });

  group('TransformExtension1', () {
    test('transforms result with argument context', () async {
      final func = funx.Func1<int, int>(
        (n) async => n * 2,
      ).transform<String>((result) => 'Doubled: $result');

      expect(await func(5), 'Doubled: 10');
    });

    test('transforms from int to bool', () async {
      final func = funx.Func1<int, int>(
        (n) async => n,
      ).transform<bool>((result) => result > 0);

      expect(await func(5), true);
      expect(await func(-5), false);
    });

    test('transforms to list', () async {
      final func = funx.Func1<String, String>(
        (s) async => s,
      ).transform<List<String>>((s) => s.split(''));

      expect(await func('abc'), ['a', 'b', 'c']);
    });

    test('chains multiple transforms', () async {
      final func = funx.Func1<int, int>((n) async => n)
          .transform<int>((n) => n + 10)
          .transform<String>((n) => 'Value: $n')
          .transform<int>((s) => s.length);

      expect(await func(5), 9); // 'Value: 15'.length
    });

    test('propagates errors from mapper', () async {
      final func = funx.Func1<int, int>((n) async => n).transform<String>(
        (n) => throw StateError('transform error'),
      );

      expect(() => func(42), throwsStateError);
    });
  });

  group('TransformExtension2', () {
    test('transforms result of two-argument function', () async {
      final func = funx.Func2<int, int, int>(
        (a, b) async => a + b,
      ).transform<String>((sum) => 'Sum: $sum');

      expect(await func(10, 20), 'Sum: 30');
    });

    test('transforms to bool based on result', () async {
      final func = funx.Func2<int, int, int>(
        (a, b) async => a - b,
      ).transform<bool>((diff) => diff >= 0);

      expect(await func(10, 5), true);
      expect(await func(5, 10), false);
    });

    test('transforms to complex type', () async {
      final func =
          funx.Func2<String, String, String>(
            (a, b) async => '$a$b',
          ).transform<Map<String, dynamic>>(
            (result) => {
              'value': result,
              'length': result.length,
            },
          );

      final result = await func('Hello', 'World');
      expect(result['value'], 'HelloWorld');
      expect(result['length'], 10);
    });

    test('chains multiple transforms', () async {
      final func = funx.Func2<int, int, int>((a, b) async => a * b)
          .transform<int>((n) => n + 100)
          .transform<String>((n) => 'Result: $n')
          .transform<bool>((s) => s.contains('Result'));

      expect(await func(5, 6), true); // 'Result: 130'.contains('Result')
    });

    test('propagates errors from inner function', () async {
      final func = funx.Func2<int, int, int>(
        (a, b) async => throw UnsupportedError('test'),
      ).transform<String>((n) => '$n');

      expect(() => func(1, 2), throwsUnsupportedError);
    });
  });

  group('Transform edge cases', () {
    test('transforms null value', () async {
      final func = funx.Func<int?>(
        () async => null,
      ).transform<String>((n) => n == null ? 'null' : '$n');

      expect(await func(), 'null');
    });

    test('transforms to same type', () async {
      final func = funx.Func(() async => 42).transform<int>((n) => n * 2);

      expect(await func(), 84);
    });

    test('works with async mapper (via Future)', () async {
      final func = funx.Func(
        () async => 42,
      ).transform<Future<String>>((n) async => 'Value: $n');

      final result = await func();
      expect(await result, 'Value: 42');
    });

    test('preserves type safety', () async {
      final func = funx.Func(
        () async => 'hello',
      ).transform<int>((s) => s.length);

      expect(await func(), 5);
      // Type is Func<int>, not Func<String>
    });
  });
}
