// Test files use typed local function variables to trigger the extensions on
// specific arities. The lints below would require rewriting every test as a
// local function declaration, which makes chaining less readable.
// ignore_for_file: prefer_final_locals, omit_local_variable_types,
// ignore_for_file: prefer_function_declarations_over_variables

import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart';

void main() {
  group('AsyncFunctionExtension (0-arg)', () {
    test('timeout returns value when fast enough', () async {
      Future<String> Function() fn = () async => 'ok';
      final decorated = fn.timeout(const Duration(seconds: 1));
      expect(await decorated(), 'ok');
    });

    test('timeout throws TimeoutException when slow', () async {
      Future<String> Function() fn = () async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return 'ok';
      };
      final decorated = fn.timeout(const Duration(milliseconds: 10));
      expect(decorated(), throwsA(isA<TimeoutException>()));
    });

    test('delay adds delay before execution', () async {
      Future<String> Function() fn = () async => 'ok';
      final stopwatch = Stopwatch()..start();
      final decorated = fn.delay(const Duration(milliseconds: 50));
      expect(await decorated(), 'ok');
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
    });

    test('asDeferred delays execution until awaited', () async {
      var executed = false;
      Future<String> Function() fn = () async {
        executed = true;
        return 'ok';
      };
      final decorated = fn.asDeferred();
      final future = decorated();
      expect(executed, isFalse);
      expect(await future, 'ok');
      expect(executed, isTrue);
    });

    test('idleCallback executes function', () async {
      Future<String> Function() fn = () async => 'ok';
      final decorated = fn.idleCallback(
        checkInterval: const Duration(milliseconds: 1),
        idleDetector: () => true,
      );
      expect(await decorated(), 'ok');
    });

    test('retry succeeds after transient failures', () async {
      var attempts = 0;
      Future<String> Function() fn = () async {
        attempts++;
        if (attempts < 3) throw Exception('fail');
        return 'ok';
      };
      final decorated = fn.retry(maxAttempts: 3);
      expect(await decorated(), 'ok');
      expect(attempts, 3);
    });

    test('fallback uses value on error', () async {
      Future<String> Function() fn = () async => throw Exception('fail');
      final decorated = fn.fallback(fallbackValue: 'default');
      expect(await decorated(), 'default');
    });

    test('fallback uses function on error', () async {
      Future<String> Function() fn = () async => throw Exception('fail');
      final decorated = fn.fallback(
        fallbackFunction: () async => 'recovered',
      );
      expect(await decorated(), 'recovered');
    });

    test('recover invokes recovery action', () async {
      var recovered = false;
      Future<String> Function() fn = () async => throw Exception('fail');
      final decorated = fn.recover(
        RecoveryStrategy(
          onError: (_) async => recovered = true,
        ),
      );
      expect(decorated(), throwsA(isA<Exception>()));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(recovered, isTrue);
    });

    test('catchError handles matching error', () async {
      Future<String> Function() fn = () async =>
          throw const FormatException('bad');
      final decorated = fn.catchError(
        handlers: {
          FormatException: (_) async => 'handled',
        },
      );
      expect(await decorated(), 'handled');
    });

    test('defaultValue returns default on error', () async {
      Future<String> Function() fn = () async => throw Exception('fail');
      final decorated = fn.defaultValue(defaultValue: 'default');
      expect(await decorated(), 'default');
    });

    test('guard enforces pre-condition', () async {
      Future<String> Function() fn = () async => 'ok';
      final decorated = fn.guard(
        preCondition: () => false,
        preConditionMessage: 'not ready',
      );
      expect(decorated(), throwsA(isA<GuardException>()));
    });

    test('proxy runs hooks', () async {
      var before = false;
      var after = false;
      Future<String> Function() fn = () async => 'ok';
      final decorated = fn.proxy(
        beforeCall: () => before = true,
        afterCall: (result) {
          after = true;
          return result;
        },
      );
      expect(await decorated(), 'ok');
      expect(before, isTrue);
      expect(after, isTrue);
    });

    test('transform maps result', () async {
      Future<int> Function() fn = () async => 21;
      final decorated = fn.transform((value) => value * 2);
      expect(await decorated(), 42);
    });

    test('when executes conditionally', () async {
      Future<String> Function() fn = () async => 'primary';
      final decorated = fn.when(
        condition: () => false,
        otherwise: () async => 'fallback',
      );
      expect(await decorated(), 'fallback');
    });

    test('repeat executes multiple times', () async {
      var count = 0;
      Future<int> Function() fn = () async => ++count;
      final decorated = fn.repeat(times: 3);
      expect(await decorated(), 3);
      expect(count, 3);
    });

    test('tap runs side effects', () async {
      String? captured;
      Future<String> Function() fn = () async => 'ok';
      final decorated = fn.tap(onValue: (value) => captured = value);
      expect(await decorated(), 'ok');
      expect(captured, 'ok');
    });

    test('chains multiple decorators', () async {
      var attempts = 0;
      Future<String> Function() fn = () async {
        attempts++;
        if (attempts < 2) throw Exception('fail');
        return 'ok';
      };
      final decorated = fn
          .retry(maxAttempts: 3)
          .timeout(const Duration(seconds: 1))
          .transform((value) => value.toUpperCase());
      expect(await decorated(), 'OK');
    });
  });

  group('AsyncFunction1Extension (1-arg)', () {
    test('timeout returns value when fast enough', () async {
      Future<String> Function(int) fn = (value) async => '$value';
      final decorated = fn.timeout(const Duration(seconds: 1));
      expect(await decorated(42), '42');
    });

    test('retry succeeds after transient failures', () async {
      var attempts = 0;
      Future<String> Function(int) fn = (value) async {
        attempts++;
        if (attempts < 3) throw Exception('fail');
        return '$value';
      };
      final decorated = fn.retry(maxAttempts: 3);
      expect(await decorated(42), '42');
      expect(attempts, 3);
    });

    test('fallback uses function receiving argument', () async {
      Future<String> Function(int) fn = (_) async => throw Exception('fail');
      final decorated = fn.fallback(
        fallbackFunction: (value) async => 'fallback-$value',
      );
      expect(await decorated(42), 'fallback-42');
    });

    test('guard validates argument', () async {
      Future<String> Function(int) fn = (value) async => '$value';
      final decorated = fn.guard(
        preCondition: (value) => value > 0,
        preConditionMessage: 'must be positive',
      );
      expect(await decorated(42), '42');
      expect(decorated(-1), throwsA(isA<GuardException>()));
    });

    test('validate validates argument', () async {
      Future<String> Function(int) fn = (value) async => '$value';
      final decorated = fn.validate(
        validators: [
          (value) => value > 0 ? null : 'must be positive',
        ],
      );
      expect(await decorated(42), '42');
      expect(decorated(-1), throwsA(isA<ValidationException>()));
    });

    test('proxy transforms argument', () async {
      Future<String> Function(int) fn = (value) async => '$value';
      final decorated = fn.proxy(
        transformArg: (value) => value * 2,
      );
      expect(await decorated(21), '42');
    });

    test('when receives argument', () async {
      Future<String> Function(int) fn = (value) async => '$value';
      final decorated = fn.when(
        condition: (value) => value > 0,
        otherwise: (value) async => 'negative-$value',
      );
      expect(await decorated(42), '42');
      expect(await decorated(-1), 'negative--1');
    });

    test('transform maps result', () async {
      Future<int> Function(int) fn = (value) async => value;
      final decorated = fn.transform((value) => value * 2);
      expect(await decorated(21), 42);
    });

    test('chains decorators', () async {
      Future<int> Function(int) fn = (value) async => value;
      final decorated = fn
          .validate(
            validators: [(value) => value >= 0 ? null : 'negative'],
          )
          .retry(maxAttempts: 2)
          .transform((value) => value * 2);
      expect(await decorated(21), 42);
    });
  });

  group('AsyncFunction2Extension (2-arg)', () {
    test('timeout returns value when fast enough', () async {
      Future<int> Function(int, int) fn = (a, b) async => a + b;
      final decorated = fn.timeout(const Duration(seconds: 1));
      expect(await decorated(20, 22), 42);
    });

    test('retry succeeds after transient failures', () async {
      var attempts = 0;
      Future<int> Function(int, int) fn = (a, b) async {
        attempts++;
        if (attempts < 3) throw Exception('fail');
        return a + b;
      };
      final decorated = fn.retry(maxAttempts: 3);
      expect(await decorated(20, 22), 42);
      expect(attempts, 3);
    });

    test('fallback uses function receiving arguments', () async {
      Future<int> Function(int, int) fn = (a, b) async =>
          throw Exception('fail');
      final decorated = fn.fallback(
        fallbackFunction: (a, b) async => a * b,
      );
      expect(await decorated(6, 7), 42);
    });

    test('guard validates arguments', () async {
      Future<int> Function(int, int) fn = (a, b) async => a + b;
      final decorated = fn.guard(
        preCondition: (a, b) => b != 0,
        preConditionMessage: 'b must not be zero',
      );
      expect(await decorated(40, 2), 42);
      expect(decorated(40, 0), throwsA(isA<GuardException>()));
    });

    test('validate validates arguments', () async {
      Future<int> Function(int, int) fn = (a, b) async => a + b;
      final decorated = fn.validate(
        validators: [
          (a, b) => b != 0 ? null : 'b must not be zero',
        ],
      );
      expect(await decorated(40, 2), 42);
      expect(decorated(40, 0), throwsA(isA<ValidationException>()));
    });

    test('proxy transforms arguments', () async {
      Future<int> Function(int, int) fn = (a, b) async => a + b;
      final decorated = fn.proxy(
        transformArgs: (a, b) => (a * 2, b * 2),
      );
      expect(await decorated(10, 11), 42);
    });

    test('when receives arguments', () async {
      Future<int> Function(int, int) fn = (a, b) async => a + b;
      final decorated = fn.when(
        condition: (a, b) => b != 0,
        otherwise: (a, b) async => a * b,
      );
      expect(await decorated(40, 2), 42);
      expect(await decorated(6, 0), 0);
    });

    test('transform maps result', () async {
      Future<int> Function(int, int) fn = (a, b) async => a + b;
      final decorated = fn.transform((value) => 'sum:$value');
      expect(await decorated(20, 22), 'sum:42');
    });

    test('chains decorators', () async {
      Future<int> Function(int, int) fn = (a, b) async => a + b;
      final decorated = fn
          .guard(preCondition: (a, b) => b != 0)
          .timeout(const Duration(seconds: 1))
          .transform((value) => value * 10);
      expect(await decorated(2, 3), 50);
    });
  });
}
