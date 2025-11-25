/// Integration tests for Timing + Reliability pattern combinations.
library;

import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart';

void main() {
  group('Timing + Reliability combinations', () {
    test('debounce + retry - should retry debounced function', () async {
      var attempts = 0;
      final func = Func<String>(() async {
        attempts++;
        if (attempts < 2) {
          throw Exception('Failed');
        }
        return 'success';
      }).debounce(const Duration(milliseconds: 100)).retry(maxAttempts: 3);

      final result = await func();
      expect(result, equals('success'));
      expect(attempts, equals(2));
    });

    test(
      'debounce + fallback - should provide fallback for failed debounced call',
      () async {
        final func =
            Func<String>(() async {
                  throw Exception('Failed');
                })
                .debounce(const Duration(milliseconds: 100))
                .fallback(fallbackValue: 'fallback');

        final result = await func();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(result, equals('fallback'));
      },
    );

    test('delay + retry - should retry with delay', () async {
      var attempts = 0;
      final func = Func<String>(() async {
        attempts++;
        if (attempts < 3) {
          throw Exception('Failed');
        }
        return 'success';
      }).delay(const Duration(milliseconds: 50)).retry(maxAttempts: 5);

      final result = await func();
      expect(result, equals('success'));
      expect(attempts, equals(3));
    });

    test('timeout + retry - should retry before timing out', () async {
      var attempts = 0;
      final func = Func<String>(() async {
        attempts++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (attempts < 2) {
          throw Exception('Failed');
        }
        return 'success';
      }).retry(maxAttempts: 3).timeout(const Duration(seconds: 2));

      final result = await func();
      expect(result, equals('success'));
      expect(attempts, equals(2));
    });

    test('timeout + fallback - should use fallback on timeout', () async {
      final func =
          Func<String>(() async {
                await Future<void>.delayed(const Duration(seconds: 2));
                return 'success';
              })
              .timeout(const Duration(milliseconds: 100))
              .fallback(fallbackValue: 'fallback');

      final result = await func();
      expect(result, equals('fallback'));
    });

    test('throttle + retry - retries should respect throttle', () async {
      var attempts = 0;
      final func = Func<String>(() async {
        attempts++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (attempts < 2) {
          throw Exception('Failed');
        }
        return 'success-$attempts';
      }).retry(maxAttempts: 3).throttle(const Duration(milliseconds: 100));

      final result = await func();
      expect(result, equals('success-2'));
      expect(attempts, greaterThanOrEqualTo(2));
    });

    test(
      'debounce + circuit breaker - debounced calls through circuit breaker',
      () async {
        final breaker = CircuitBreaker(
          failureThreshold: 2,
          timeout: const Duration(seconds: 1),
        );

        final func = Func<String>(() async {
          throw Exception('Failed');
        }).circuitBreaker(breaker).debounce(const Duration(milliseconds: 50));

        // Multiple separate calls to trigger failures
        await func().catchError((e) => 'error');
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await func().catchError((e) => 'error');
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Circuit should be open after threshold failures
        expect(breaker.state, equals(CircuitBreakerState.open));
      },
    );

    test('delay + fallback - fallback when delayed execution fails', () async {
      final func =
          Func<String>(() async {
                throw Exception('Failed');
              })
              .delay(const Duration(milliseconds: 50))
              .fallback(fallbackValue: 'fallback');

      final result = await func();
      expect(result, equals('fallback'));
    });
  });
}
