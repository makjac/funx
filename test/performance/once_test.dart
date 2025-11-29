import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('OnceExtension', () {
    test('executes function only once', () async {
      var callCount = 0;
      final func = Func(() async {
        callCount++;
        return 'result';
      }).once();

      final result1 = await func();
      final result2 = await func();
      final result3 = await func();

      expect(result1, equals('result'));
      expect(result2, equals('result'));
      expect(result3, equals('result'));
      expect(callCount, equals(1));
    });

    test('caches error and rethrows', () async {
      var callCount = 0;
      final func = Func(() async {
        callCount++;
        throw Exception('test error');
      }).once();

      await expectLater(func(), throwsException);
      await expectLater(func(), throwsException);
      expect(callCount, equals(1));
    });

    test('resets cache when reset() is called', () async {
      var callCount = 0;
      final func =
          Func(() async {
                return ++callCount;
              }).once()
              as OnceExtension<int>;

      final result1 = await func();
      expect(result1, equals(1));

      func.reset();

      final result2 = await func();
      expect(result2, equals(2));
      expect(callCount, equals(2));
    });

    test(
      'resetOn allows retry on specific errors using OnceExtension',
      () async {
        var callCount = 0;
        final func = OnceExtension(
          Func(() async {
            callCount++;
            if (callCount == 1) {
              throw ArgumentError('retry me');
            }
            return 'success';
          }),
          resetOn: (error) => error is ArgumentError,
        );

        await expectLater(func(), throwsArgumentError);
        final result = await func();

        expect(result, equals('success'));
        expect(callCount, equals(2));
      },
    );

    test('caches Error with stackTrace', () async {
      final func = Func(() async {
        throw StateError('test');
      }).once();

      await expectLater(func(), throwsStateError);
      await expectLater(func(), throwsStateError);
    });
  });

  group('OnceExtension1', () {
    test('executes once per unique argument', () async {
      var callCount = 0;
      final func = Func1((String arg) async {
        callCount++;
        return 'result-$arg';
      }).once();

      final result1 = await func('a');
      final result2 = await func('a');
      final result3 = await func('b');
      final result4 = await func('b');

      expect(result1, equals('result-a'));
      expect(result2, equals('result-a'));
      expect(result3, equals('result-b'));
      expect(result4, equals('result-b'));
      expect(callCount, equals(2)); // Once for 'a', once for 'b'
    });

    test('resets cache for specific argument', () async {
      var callCount = 0;
      final func =
          Func1((String arg) async {
                callCount++;
                return '$arg-$callCount';
              }).once()
              as OnceExtension1<String, String>;

      final result1 = await func('a');
      expect(result1, equals('a-1'));

      func.reset('a');

      final result2 = await func('a');
      expect(result2, equals('a-2'));
    });

    test('caches errors per argument', () async {
      var callCount = 0;
      final func = Func1((String arg) async {
        callCount++;
        if (arg == 'error') {
          throw Exception('error for $arg');
        }
        return 'result-$arg';
      }).once();

      await expectLater(func('error'), throwsException);
      await expectLater(func('error'), throwsException);
      final result = await func('ok');

      expect(result, equals('result-ok'));
      expect(callCount, equals(2));
    });

    test('reset all clears entire cache', () async {
      var callCount = 0;
      final func =
          Func1((String arg) async {
                callCount++;
                return '$arg-$callCount';
              }).once()
              as OnceExtension1<String, String>;

      await func('a');
      await func('b');

      func.reset(); // Clear all

      final result1 = await func('a');
      final result2 = await func('b');

      expect(result1, equals('a-3'));
      expect(result2, equals('b-4'));
    });
  });

  group('OnceExtension2', () {
    test('executes once per unique argument pair', () async {
      var callCount = 0;
      final func = Func2((int a, int b) async {
        callCount++;
        return a + b;
      }).once();

      final result1 = await func(1, 2);
      final result2 = await func(1, 2);
      final result3 = await func(2, 3);

      expect(result1, equals(3));
      expect(result2, equals(3));
      expect(result3, equals(5));
      expect(callCount, equals(2));
    });

    test('resets cache for specific argument pair', () async {
      var callCount = 0;
      final func =
          Func2((int a, int b) async {
                callCount++;
                return a + b + callCount;
              }).once()
              as OnceExtension2<int, int, int>;

      final result1 = await func(1, 2);
      expect(result1, equals(4)); // 1+2+1

      func.reset(1, 2);

      final result2 = await func(1, 2);
      expect(result2, equals(5)); // 1+2+2
    });

    test('caches errors per argument pair', () async {
      var callCount = 0;
      final func = Func2((int a, int b) async {
        callCount++;
        if (a == 0 && b == 0) {
          throw Exception('error for (0,0)');
        }
        return a + b;
      }).once();

      await expectLater(func(0, 0), throwsException);
      await expectLater(func(0, 0), throwsException);
      final result = await func(1, 2);

      expect(result, equals(3));
      expect(callCount, equals(2));
    });

    test('reset all clears entire cache', () async {
      var callCount = 0;
      final func =
          Func2((int a, int b) async {
                callCount++;
                return a + b + callCount;
              }).once()
              as OnceExtension2<int, int, int>;

      await func(1, 2);
      await func(3, 4);

      func.reset(); // Clear all

      final result1 = await func(1, 2);
      final result2 = await func(3, 4);

      expect(result1, equals(6)); // 1+2+3
      expect(result2, equals(11)); // 3+4+4
    });

    test('_ArgPair equality and hashCode work correctly', () async {
      var callCount = 0;
      final func = Func2((int a, int b) async {
        callCount++;
        return a * b;
      }).once();

      await func(2, 3);
      await func(2, 3); // Same pair
      await func(3, 2); // Different pair

      expect(callCount, equals(2));
    });
  });
}
