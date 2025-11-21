import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/timing/defer.dart';
import 'package:test/test.dart';

void main() {
  group('DeferExtension', () {
    test('defers execution using microtask', () async {
      var executed = false;
      final func = funx.Func<void>(() async {
        executed = true;
      }).asDeferred();

      final promise = func();

      // Microtask executes in next event loop
      await promise;
      expect(executed, isTrue);
    });

    test('executes and returns correct value', () async {
      final func = funx.Func<int>(() async => 42).asDeferred();

      final result = await func();
      expect(result, equals(42));
    });

    test('propagates errors', () async {
      final func = funx.Func<int>(
        () async => throw Exception('error'),
      ).asDeferred();

      expect(func(), throwsException);
    });
  });

  group('DeferExtension1', () {
    test('defers execution using microtask', () async {
      var executed = false;
      final func = funx.Func1<int, void>((n) async {
        executed = true;
      }).asDeferred();

      final promise = func(42);

      await promise;
      expect(executed, isTrue);
    });

    test('passes argument correctly', () async {
      final func = funx.Func1<int, String>(
        (n) async => 'Value: $n',
      ).asDeferred();

      final result = await func(42);
      expect(result, equals('Value: 42'));
    });
  });

  group('DeferExtension2', () {
    test('defers execution using microtask', () async {
      var executed = false;
      final func = funx.Func2<int, int, void>((a, b) async {
        executed = true;
      }).asDeferred();

      final promise = func(1, 2);

      await promise;
      expect(executed, isTrue);
    });

    test('passes arguments correctly', () async {
      final func = funx.Func2<int, int, int>(
        (a, b) async => a + b,
      ).asDeferred();

      final result = await func(10, 20);
      expect(result, equals(30));
    });
  });

  group('Defer extensions', () {
    test('FuncDeferExtension works', () async {
      var executed = false;
      final func = funx.Func<void>(() async {
        executed = true;
      }).asDeferred();

      final promise = func();
      expect(executed, isFalse);

      await promise;
      expect(executed, isTrue);
    });

    test('Func1DeferExtension works', () async {
      final func = funx.Func1<int, int>((n) async => n * 2).asDeferred();

      final result = await func(21);
      expect(result, equals(42));
    });

    test('Func2DeferExtension works', () async {
      final func = funx.Func2<int, int, int>(
        (a, b) async => a * b,
      ).asDeferred();

      final result = await func(6, 7);
      expect(result, equals(42));
    });
  });
}
