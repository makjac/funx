import 'dart:async';

import 'package:funx/funx.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('CancellableFunc', () {
    test('operation returns value when not cancelled', () async {
      final func = funx.Func<String>(() async => 'hello').cancellable();
      final operation = func.operation();

      final result = await operation.value;
      expect(result, equals('hello'));
    });

    test('call returns value when not cancelled', () async {
      final func = funx.Func<int>(() async => 42).cancellable();

      final result = await func();
      expect(result, equals(42));
    });

    test('cancel throws CancelException on awaiter', () async {
      final func = funx.Func<String>(() async {
        await Future<void>.delayed(const Duration(seconds: 10));
        return 'done';
      }).cancellable();

      final operation = func.operation()..cancel();

      expect(operation.value, throwsA(isA<funx.CancelException>()));
    });

    test('cancel via instance cancel method', () async {
      final func = funx.Func<String>(() async {
        await Future<void>.delayed(const Duration(seconds: 10));
        return 'done';
      }).cancellable();

      final future = func();
      func.cancel();

      expect(future, throwsA(isA<funx.CancelException>()));
    });

    test('cancellation after completion is a no-op', () async {
      final func = funx.Func<String>(() async => 'done').cancellable();
      final operation = func.operation();

      final result = await operation.value;
      expect(result, equals('done'));

      operation.cancel();
      expect(operation.isCompleted, isTrue);
      expect(operation.isCanceled, isFalse);
    });

    test('double cancel is a no-op', () async {
      final func = funx.Func<String>(() async {
        await Future<void>.delayed(const Duration(seconds: 10));
        return 'done';
      }).cancellable();

      final operation = func.operation()
        ..cancel()
        ..cancel();

      expect(operation.value, throwsA(isA<funx.CancelException>()));
    });

    test('CancelToken cancels multiple active operations', () async {
      final token = funx.CancelToken();
      final a = funx.Func<String>(() async {
        await Future<void>.delayed(const Duration(seconds: 10));
        return 'a';
      }).cancellable(token: token);
      final b = funx.Func<String>(() async {
        await Future<void>.delayed(const Duration(seconds: 10));
        return 'b';
      }).cancellable(token: token);

      final futureA = a();
      final futureB = b();
      token.cancel();

      expect(futureA, throwsA(isA<funx.CancelException>()));
      expect(futureB, throwsA(isA<funx.CancelException>()));
    });

    test('token cancelled before invocation cancels immediately', () async {
      final token = funx.CancelToken()..cancel();
      final func = funx.Func<String>(
        () async => 'done',
      ).cancellable(token: token);

      expect(func(), throwsA(isA<funx.CancelException>()));
    });

    test('double token cancel is a no-op', () async {
      final token = funx.CancelToken();
      final func = funx.Func<String>(() async {
        await Future<void>.delayed(const Duration(seconds: 10));
        return 'done';
      }).cancellable(token: token);

      final future = func();
      token
        ..cancel()
        ..cancel();

      expect(future, throwsA(isA<funx.CancelException>()));
    });

    test('inner work continues after cancellation', () async {
      var innerCompleted = false;
      final func = funx.Func<String>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        innerCompleted = true;
        return 'done';
      }).cancellable();

      final operation = func.operation()..cancel();

      try {
        await operation.value;
      } on funx.CancelException {
        // expected
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(innerCompleted, isTrue);
    });

    test('chains with retry and timeout as outer layer', () async {
      final func =
          funx.Func<String>(() async {
                await Future<void>.delayed(const Duration(seconds: 10));
                return 'done';
              })
              .retry(maxAttempts: 3)
              .timeout(const Duration(seconds: 15))
              .cancellable();

      final operation = func.operation()..cancel();

      expect(operation.value, throwsA(isA<funx.CancelException>()));
    });

    test('error from inner function is propagated', () async {
      final func = funx.Func<String>(
        () async => throw Exception('boom'),
      ).cancellable();

      expect(func(), throwsException);
    });

    test('CancelException message is readable', () {
      const exception = funx.CancelException();
      expect(
        exception.toString(),
        contains('operation was cancelled'),
      );
    });
  });

  group('CancellableFunc1', () {
    test('operation returns value when not cancelled', () async {
      final func = funx.Func1<int, int>((int n) async => n * 2).cancellable();
      final operation = func.operation(5);

      expect(await operation.value, equals(10));
    });

    test('cancel throws CancelException', () async {
      final func = funx.Func1<int, String>((int n) async {
        await Future<void>.delayed(const Duration(seconds: 10));
        return '$n';
      }).cancellable();

      final future = func(1);
      func.cancel(1);

      expect(future, throwsA(isA<funx.CancelException>()));
    });

    test('CancelToken cancels invocation', () async {
      final token = funx.CancelToken();
      final func = funx.Func1<int, String>((int n) async {
        await Future<void>.delayed(const Duration(seconds: 10));
        return '$n';
      }).cancellable(token: token);

      final future = func(7);
      token.cancel();

      expect(future, throwsA(isA<funx.CancelException>()));
    });
  });

  group('CancellableFunc2', () {
    test('operation returns value when not cancelled', () async {
      final func = funx.Func2<int, int, int>(
        (int a, int b) async => a + b,
      ).cancellable();
      final operation = func.operation(2, 3);

      expect(await operation.value, equals(5));
    });

    test('cancel throws CancelException', () async {
      final func = funx.Func2<int, int, String>(
        (int a, int b) async {
          await Future<void>.delayed(const Duration(seconds: 10));
          return '$a-$b';
        },
      ).cancellable();

      final future = func(1, 2);
      func.cancel(1, 2);

      expect(future, throwsA(isA<funx.CancelException>()));
    });
  });
}
