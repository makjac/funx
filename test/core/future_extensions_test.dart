// Test file uses mutable captured variables and typed locals for clarity.

import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart';

void main() {
  group('FutureExtension', () {
    test('withTimeout returns value when fast enough', () async {
      final future = Future.value('ok').withTimeout(const Duration(seconds: 1));
      expect(await future, 'ok');
    });

    test('withTimeout throws TimeoutException when slow', () async {
      final future = Future<String>.delayed(
        const Duration(seconds: 1),
        () => 'ok',
      ).withTimeout(const Duration(milliseconds: 10));
      expect(future, throwsA(isA<TimeoutException>()));
    });

    test('withTimeout uses onTimeout callback', () async {
      final future =
          Future<String>.delayed(
            const Duration(seconds: 1),
            () => 'ok',
          ).withTimeout(
            const Duration(milliseconds: 10),
            onTimeout: () => 'fallback',
          );
      expect(await future, 'fallback');
    });

    test('withFallback uses value on error', () async {
      final future = Future<String>.error(Exception('fail')).withFallback(
        fallbackValue: 'default',
      );
      expect(await future, 'default');
    });

    test('withFallback uses function on error', () async {
      final future = Future<String>.error(Exception('fail')).withFallback(
        fallbackFunction: (error) async => 'recovered:$error',
      );
      expect(await future, startsWith('recovered:'));
    });

    test('withFallback respects fallbackIf predicate', () async {
      final future =
          Future<String>.error(
            const FormatException('bad'),
          ).withFallback(
            fallbackValue: 'default',
            fallbackIf: (error) => error is TimeoutException,
          );
      expect(future, throwsA(isA<FormatException>()));
    });

    test('withFallback invokes onFallback callback', () async {
      Object? captured;
      final future = Future<String>.error(Exception('fail')).withFallback(
        fallbackValue: 'default',
        onFallback: (error) => captured = error,
      );
      expect(await future, 'default');
      expect(captured, isA<Exception>());
    });

    test('withTimeout and withFallback chain', () async {
      final future =
          Future<String>.delayed(
                const Duration(seconds: 1),
                () => 'ok',
              )
              .withTimeout(
                const Duration(milliseconds: 10),
                onTimeout: () => throw Exception('timeout'),
              )
              .withFallback(fallbackValue: 'default');
      expect(await future, 'default');
    });
  });
}
