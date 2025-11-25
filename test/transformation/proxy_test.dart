import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('ProxyExtension', () {
    test('executes inner function', () async {
      final func = funx.Func(() async => 'result').proxy();

      expect(await func(), 'result');
    });

    test('invokes beforeCall callback', () async {
      var called = false;
      final func = funx.Func(() async => 'result').proxy(
        beforeCall: () => called = true,
      );

      await func();
      expect(called, true);
    });

    test('invokes afterCall and transforms result', () async {
      final func = funx.Func(() async => 42).proxy(
        afterCall: (result) => result * 2,
      );

      expect(await func(), 84);
    });

    test('invokes onError on exception', () async {
      Object? capturedError;
      final func = funx.Func<int>(() async => throw StateError('test')).proxy(
        onError: (error, stack) => capturedError = error,
      );

      expect(func(), throwsStateError);
      await Future<void>.delayed(Duration.zero);
      expect(capturedError, isA<StateError>());
    });

    test('all callbacks work together', () async {
      var beforeCalled = false;
      var errorCalled = false;

      final func = funx.Func(() async => 10).proxy(
        beforeCall: () => beforeCalled = true,
        afterCall: (result) => result + 5,
        onError: (e, s) => errorCalled = true,
      );

      expect(await func(), 15);
      expect(beforeCalled, true);
      expect(errorCalled, false);
    });
  });

  group('ProxyExtension1', () {
    test('executes inner function with argument', () async {
      final func = funx.Func1<String, int>((s) async => s.length).proxy();

      expect(await func('hello'), 5);
    });

    test('invokes beforeCall with argument', () async {
      String? capturedArg;
      final func = funx.Func1<String, int>((s) async => s.length).proxy(
        beforeCall: (arg) => capturedArg = arg,
      );

      await func('test');
      expect(capturedArg, 'test');
    });

    test('transforms argument before execution', () async {
      final func = funx.Func1<String, String>((s) async => s).proxy(
        transformArg: (s) => s.toUpperCase(),
      );

      expect(await func('hello'), 'HELLO');
    });

    test('transforms result after execution', () async {
      final func = funx.Func1<int, int>((n) async => n * 2).proxy(
        afterCall: (result) => result + 10,
      );

      expect(await func(5), 20); // (5 * 2) + 10
    });

    test('combines transformArg and afterCall', () async {
      final func = funx.Func1<String, String>((s) async => s).proxy(
        transformArg: (s) => s.toUpperCase(),
        afterCall: (result) => '$result!',
      );

      expect(await func('hello'), 'HELLO!');
    });

    test('invokes onError on exception', () async {
      var errorCalled = false;
      final func =
          funx.Func1<int, int>(
            (n) async => throw ArgumentError('test'),
          ).proxy(
            onError: (e, s) => errorCalled = true,
          );

      expect(() => func(42), throwsArgumentError);
      await Future<void>.delayed(Duration.zero);
      expect(errorCalled, true);
    });
  });

  group('ProxyExtension2', () {
    test('executes inner function with arguments', () async {
      final func = funx.Func2<int, int, int>((a, b) async => a + b).proxy();

      expect(await func(10, 20), 30);
    });

    test('invokes beforeCall with arguments', () async {
      int? capturedA;
      int? capturedB;
      final func = funx.Func2<int, int, int>((a, b) async => a + b).proxy(
        beforeCall: (a, b) {
          capturedA = a;
          capturedB = b;
        },
      );

      await func(5, 10);
      expect(capturedA, 5);
      expect(capturedB, 10);
    });

    test('transforms arguments before execution', () async {
      final func = funx.Func2<int, int, int>((a, b) async => a + b).proxy(
        transformArgs: (a, b) => (a * 2, b * 3),
      );

      expect(await func(2, 3), 13); // (2*2) + (3*3) = 4 + 9
    });

    test('transforms result after execution', () async {
      final func = funx.Func2<int, int, int>((a, b) async => a * b).proxy(
        afterCall: (result) => result + 100,
      );

      expect(await func(5, 6), 130); // (5*6) + 100
    });

    test('combines all transformations', () async {
      final func = funx.Func2<int, int, String>((a, b) async => '${a + b}')
          .proxy(
            transformArgs: (a, b) => (a + 1, b + 1),
            afterCall: (result) => 'Result: $result',
          );

      expect(await func(10, 20), 'Result: 32'); // (11 + 21)
    });

    test('invokes onError on exception', () async {
      StackTrace? capturedStack;
      final func =
          funx.Func2<int, int, int>(
            (a, b) async => throw UnsupportedError('test'),
          ).proxy(
            onError: (e, s) => capturedStack = s,
          );

      expect(() => func(1, 2), throwsUnsupportedError);
      await Future<void>.delayed(Duration.zero);
      expect(capturedStack, isNotNull);
    });
  });

  group('Proxy edge cases', () {
    test('works with null callbacks', () async {
      final func = funx.Func(() async => 42).proxy(
        beforeCall: null,
        afterCall: null,
        onError: null,
      );

      expect(await func(), 42);
    });

    test('error in afterCall propagates', () async {
      final func = funx.Func(() async => 'test').proxy(
        afterCall: (r) => throw StateError('transform error'),
      );

      expect(func(), throwsStateError);
    });

    test('error in transformArg propagates', () async {
      final func = funx.Func1<String, String>((s) async => s).proxy(
        transformArg: (s) => throw ArgumentError('transform error'),
      );

      expect(() => func('test'), throwsArgumentError);
    });

    test('beforeCall executes before inner function', () async {
      final order = <String>[];
      final func =
          funx.Func(() async {
            order.add('inner');
            return 'result';
          }).proxy(
            beforeCall: () => order.add('before'),
          );

      await func();
      expect(order, ['before', 'inner']);
    });
  });
}
