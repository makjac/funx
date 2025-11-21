import 'package:funx/src/core/func_sync.dart';
import 'package:test/test.dart';

void main() {
  group('FuncSync', () {
    test('wraps and executes sync function', () {
      final func = FuncSync<int>(() => 42);
      expect(func(), equals(42));
    });

    test('can be called multiple times', () {
      var counter = 0;
      final func = FuncSync<int>(() => ++counter);

      expect(func(), equals(1));
      expect(func(), equals(2));
      expect(func(), equals(3));
    });

    test('executes immediately', () {
      var executed = false;
      final func = FuncSync<void>(() => executed = true);

      func();
      expect(executed, isTrue);
    });

    test('returns correct types', () {
      final intFunc = FuncSync<int>(() => 42);
      final stringFunc = FuncSync<String>(() => 'hello');
      final boolFunc = FuncSync<bool>(() => true);

      expect(intFunc(), isA<int>());
      expect(stringFunc(), isA<String>());
      expect(boolFunc(), isA<bool>());
    });
  });

  group('FuncSync1', () {
    test('wraps and executes sync function with one argument', () {
      final func = FuncSync1<int, String>((n) => 'Value: $n');
      expect(func(42), equals('Value: 42'));
    });

    test('passes argument correctly', () {
      final func = FuncSync1<String, int>((str) => str.length);
      expect(func('hello'), equals(5));
    });

    test('can be called multiple times with different arguments', () {
      final func = FuncSync1<int, int>((n) => n * 2);

      expect(func(5), equals(10));
      expect(func(10), equals(20));
      expect(func(15), equals(30));
    });

    test('propagates errors', () {
      final func = FuncSync1<int, int>((n) => throw Exception('error'));
      expect(() => func(42), throwsException);
    });

    test('works with different types', () {
      final toUpper = FuncSync1<String, String>((s) => s.toUpperCase());
      final double = FuncSync1<int, int>((n) => n * 2);
      final negate = FuncSync1<bool, bool>((b) => !b);

      expect(toUpper('hello'), equals('HELLO'));
      expect(double(21), equals(42));
      expect(negate(true), isFalse);
    });

    test('can transform types', () {
      final func = FuncSync1<int, String>((n) => n.toString());
      expect(func(123), equals('123'));
      expect(func(123), isA<String>());
    });
  });

  group('FuncSync2', () {
    test('wraps and executes sync function with two arguments', () {
      final func = FuncSync2<int, int, int>((a, b) => a + b);
      expect(func(10, 20), equals(30));
    });

    test('passes both arguments correctly', () {
      final func = FuncSync2<String, int, String>((str, times) => str * times);
      expect(func('x', 3), equals('xxx'));
    });

    test('can be called multiple times', () {
      final func = FuncSync2<int, int, int>((a, b) => a * b);

      expect(func(2, 3), equals(6));
      expect(func(4, 5), equals(20));
      expect(func(10, 10), equals(100));
    });

    test('propagates errors', () {
      final func = FuncSync2<int, int, int>((a, b) => throw Exception('error'));
      expect(() => func(1, 2), throwsException);
    });

    test('works with different operations', () {
      final add = FuncSync2<int, int, int>((a, b) => a + b);
      final subtract = FuncSync2<int, int, int>((a, b) => a - b);
      final multiply = FuncSync2<int, int, int>((a, b) => a * b);
      final divide = FuncSync2<int, int, double>((a, b) => a / b);

      expect(add(10, 5), equals(15));
      expect(subtract(10, 5), equals(5));
      expect(multiply(10, 5), equals(50));
      expect(divide(10, 5), equals(2.0));
    });

    test('can work with different types', () {
      final concat = FuncSync2<String, String, String>((a, b) => a + b);
      final repeat = FuncSync2<String, int, String>((s, n) => s * n);
      final compare = FuncSync2<int, int, bool>((a, b) => a > b);

      expect(concat('Hello', ' World'), equals('Hello World'));
      expect(repeat('ab', 3), equals('ababab'));
      expect(compare(10, 5), isTrue);
      expect(compare(5, 10), isFalse);
    });

    test('preserves argument order', () {
      final func = FuncSync2<int, int, String>((a, b) => '$a-$b');

      expect(func(1, 2), equals('1-2'));
      expect(func(2, 1), equals('2-1'));
    });
  });

  group('FuncSync integration', () {
    test('can compose multiple sync functions', () {
      final add5 = FuncSync1<int, int>((n) => n + 5);
      final double = FuncSync1<int, int>((n) => n * 2);

      final result = double(add5(10));
      expect(result, equals(30)); // (10 + 5) * 2
    });

    test('can use with higher-order functions', () {
      final numbers = [1, 2, 3, 4, 5];
      final double = FuncSync1<int, int>((n) => n * 2);

      final doubled = numbers.map(double.call).toList();
      expect(doubled, equals([2, 4, 6, 8, 10]));
    });

    test('different arities work together', () {
      final getValue = FuncSync<int>(() => 10);
      final addTo = FuncSync1<int, int>((n) => n + getValue());
      final multiply = FuncSync2<int, int, int>((a, b) => a * b);

      final result = multiply(addTo(5), getValue());
      expect(result, equals(150)); // (5 + 10) * 10
    });
  });
}
