// ignore_for_file: omit_local_variable_types test
// ignore_for_file: prefer_function_declarations_over_variables test

import 'package:funx/src/core/types.dart';
import 'package:test/test.dart';

void main() {
  group('AsyncFunction', () {
    test('executes async function with no arguments', () async {
      final AsyncFunction<int> fn = () async => 42;
      expect(await fn(), equals(42));
    });

    test('can throw errors', () async {
      final AsyncFunction<int> fn = () async => throw Exception('error');
      expect(fn(), throwsException);
    });
  });

  group('AsyncFunction1', () {
    test('executes async function with one argument', () async {
      final AsyncFunction1<int, String> fn = (n) async => 'Value: $n';
      expect(await fn(42), equals('Value: 42'));
    });

    test('passes argument correctly', () async {
      final AsyncFunction1<String, int> fn = (str) async => str.length;
      expect(await fn('hello'), equals(5));
    });
  });

  group('AsyncFunction2', () {
    test('executes async function with two arguments', () async {
      final AsyncFunction2<int, int, int> fn = (a, b) async => a + b;
      expect(await fn(10, 20), equals(30));
    });

    test('passes both arguments correctly', () async {
      final AsyncFunction2<String, int, String> fn = (str, times) async =>
          str * times;
      expect(await fn('x', 3), equals('xxx'));
    });
  });

  group('SyncFunction', () {
    test('executes sync function with no arguments', () {
      final SyncFunction<int> fn = () => 42;
      expect(fn(), equals(42));
    });
  });

  group('SyncFunction1', () {
    test('executes sync function with one argument', () {
      final SyncFunction1<int, String> fn = (n) => 'Value: $n';
      expect(fn(42), equals('Value: 42'));
    });

    test('passes argument correctly', () {
      final SyncFunction1<String, int> fn = (str) => str.length;
      expect(fn('hello'), equals(5));
    });
  });

  group('SyncFunction2', () {
    test('executes sync function with two arguments', () {
      final SyncFunction2<int, int, int> fn = (a, b) => a + b;
      expect(fn(10, 20), equals(30));
    });

    test('passes both arguments correctly', () {
      final SyncFunction2<String, int, String> fn = (str, times) => str * times;
      expect(fn('x', 3), equals('xxx'));
    });
  });

  group('Factory', () {
    test('creates instances', () {
      const Factory<DateTime> fn = DateTime.now;
      expect(fn(), isA<DateTime>());
    });
  });

  group('AsyncFactory', () {
    test('creates instances asynchronously', () async {
      final AsyncFactory<int> fn = () async => 42;
      expect(await fn(), equals(42));
    });
  });

  group('ErrorCallback', () {
    test('receives error and stack trace', () {
      Object? capturedError;
      StackTrace? capturedStack;

      final ErrorCallback callback = (error, stack) {
        capturedError = error;
        capturedStack = stack;
      };

      final error = Exception('test');
      final stack = StackTrace.current;

      callback(error, stack);

      expect(capturedError, equals(error));
      expect(capturedStack, equals(stack));
    });
  });

  group('DebounceMode', () {
    test('has all expected values', () {
      expect(DebounceMode.values, hasLength(3));
      expect(DebounceMode.values, contains(DebounceMode.trailing));
      expect(DebounceMode.values, contains(DebounceMode.leading));
      expect(DebounceMode.values, contains(DebounceMode.both));
    });
  });

  group('ThrottleMode', () {
    test('has all expected values', () {
      expect(ThrottleMode.values, hasLength(3));
      expect(ThrottleMode.values, contains(ThrottleMode.leading));
      expect(ThrottleMode.values, contains(ThrottleMode.trailing));
      expect(ThrottleMode.values, contains(ThrottleMode.both));
    });
  });

  group('DelayMode', () {
    test('has all expected values', () {
      expect(DelayMode.values, hasLength(3));
      expect(DelayMode.values, contains(DelayMode.before));
      expect(DelayMode.values, contains(DelayMode.after));
      expect(DelayMode.values, contains(DelayMode.both));
    });
  });
}
