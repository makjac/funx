import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('LazyExtension', () {
    test('defers execution until first call', () async {
      var callCount = 0;
      final func = Func(() async {
        callCount++;
        return 42;
      }).lazy();

      expect(callCount, equals(0)); // Not called yet

      final result = await func();
      expect(result, equals(42));
      expect(callCount, equals(1)); // Called once
    });

    test('executes on every call', () async {
      var callCount = 0;
      final func = Func(() async {
        return ++callCount;
      }).lazy();

      final result1 = await func();
      final result2 = await func();
      final result3 = await func();

      expect(result1, equals(1));
      expect(result2, equals(2));
      expect(result3, equals(3));
      expect(callCount, equals(3));
    });
  });

  group('LazyExtension1', () {
    test('defers execution until first call', () async {
      var callCount = 0;
      final func = Func1((int x) async {
        callCount++;
        return x * 2;
      }).lazy();

      expect(callCount, equals(0));

      final result = await func(5);
      expect(result, equals(10));
      expect(callCount, equals(1));
    });

    test('executes on every call with different arguments', () async {
      var callCount = 0;
      final func = Func1((int x) async {
        callCount++;
        return x * 2;
      }).lazy();

      final result1 = await func(3);
      final result2 = await func(5);
      final result3 = await func(7);

      expect(result1, equals(6));
      expect(result2, equals(10));
      expect(result3, equals(14));
      expect(callCount, equals(3));
    });

    test('executes on every call even with same argument', () async {
      var callCount = 0;
      final func = Func1((int x) async {
        callCount++;
        return x * 2;
      }).lazy();

      await func(5);
      await func(5);
      await func(5);

      expect(callCount, equals(3)); // Called 3 times, no caching
    });
  });

  group('LazyExtension2', () {
    test('defers execution until first call', () async {
      var callCount = 0;
      final func = Func2((int a, int b) async {
        callCount++;
        return a + b;
      }).lazy();

      expect(callCount, equals(0));

      final result = await func(3, 4);
      expect(result, equals(7));
      expect(callCount, equals(1));
    });

    test('executes on every call', () async {
      var callCount = 0;
      final func = Func2((int a, int b) async {
        callCount++;
        return a + b;
      }).lazy();

      final result1 = await func(1, 2);
      final result2 = await func(3, 4);
      final result3 = await func(5, 6);

      expect(result1, equals(3));
      expect(result2, equals(7));
      expect(result3, equals(11));
      expect(callCount, equals(3));
    });
  });
}
