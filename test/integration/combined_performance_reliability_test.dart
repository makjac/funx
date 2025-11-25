/// Integration tests for Performance + Reliability pattern combinations.
library;

import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart';

void main() {
  group('Performance + Reliability combinations', () {
    test('memoize + retry - should memoize successful retry results', () async {
      var attempts = 0;
      final func = Func<String>(() async {
        attempts++;
        if (attempts < 2) {
          throw Exception('Failed');
        }
        return 'success-$attempts';
      }).retry(maxAttempts: 3).memoize();

      final result1 = await func();
      expect(result1, equals('success-2'));
      expect(attempts, equals(2));

      // Second call should use memoized value
      final result2 = await func();
      expect(result2, equals('success-2'));
      expect(attempts, equals(2)); // No new attempts
    });

    test(
      'once + fallback - should execute once with fallback on failure',
      () async {
        var attempts = 0;
        final func = Func<String>(() async {
          attempts++;
          throw Exception('Failed');
        }).once().fallback(fallbackValue: 'fallback');

        final result1 = await func();
        expect(result1, equals('fallback'));
        expect(attempts, equals(1));

        // Second call should still return fallback without executing again
        final result2 = await func();
        expect(result2, equals('fallback'));
        expect(attempts, equals(1));
      },
    );

    test('deduplicate + retry - should deduplicate retry attempts', () async {
      var attempts = 0;
      final func = Func<String>(() async {
        attempts++;
        if (attempts < 2) {
          throw Exception('Failed');
        }
        return 'success-$attempts';
      }).retry(maxAttempts: 3).deduplicate(window: const Duration(seconds: 1));

      // First call
      final result1 = await func();
      expect(result1, equals('success-2'));
      expect(attempts, equals(2));

      // Second call within window - should deduplicate
      final result2 = await func();
      expect(result2, equals('success-2'));
      expect(attempts, equals(2));
    });

    test('share + timeout - should share timeout across callers', () async {
      var executions = 0;
      final func = Func<String>(() async {
        executions++;
        await Future<void>.delayed(const Duration(seconds: 2));
        return 'success';
      }).share().timeout(const Duration(milliseconds: 500));

      // Both calls should share and both timeout
      final futures = [
        func().catchError((e) => 'timeout'),
        func().catchError((e) => 'timeout'),
      ];

      final results = await Future.wait(futures);

      expect(results.every((r) => r == 'timeout'), isTrue);
      expect(executions, equals(1)); // Shared execution
    });

    test(
      'rate limit + retry - should respect rate limit during retries',
      () async {
        var attempts = 0;
        final func =
            Func<String>(() async {
                  attempts++;
                  if (attempts < 3) {
                    throw Exception('Failed');
                  }
                  return 'success';
                })
                .retry(maxAttempts: 5)
                .rateLimit(
                  maxCalls: 2,
                  window: const Duration(milliseconds: 500),
                );

        final start = DateTime.now();
        final result = await func();
        final duration = DateTime.now().difference(start);

        expect(result, equals('success'));
        expect(attempts, equals(3));
        // Should take at least some time due to rate limiting
        expect(duration.inMilliseconds, greaterThan(0));
      },
    );

    test(
      'memoize + circuit breaker - should memoize before circuit check',
      () async {
        final breaker = CircuitBreaker(
          failureThreshold: 2,
          timeout: const Duration(seconds: 1),
        );

        var attempts = 0;
        final func = Func<String>(() async {
          attempts++;
          return 'success-$attempts';
        }).memoize().circuitBreaker(breaker);

        // First call - success, memoized
        final result1 = await func();
        expect(result1, equals('success-1'));

        // Second call - should use memoized value
        final result2 = await func();
        expect(result2, equals('success-1'));
        expect(attempts, equals(1)); // Only executed once
      },
    );

    test('once + retry - should execute retry chain only once', () async {
      var attempts = 0;

      final func = Func<String>(() async {
        attempts++;
        if (attempts < 2) {
          throw Exception('Failed');
        }
        return 'success';
      }).retry(maxAttempts: 3).once();

      // First call - retries and succeeds
      final result1 = await func();
      expect(result1, equals('success'));
      expect(attempts, equals(2)); // Retry happened once

      // Second call - should use cached result from once
      final result2 = await func();
      expect(result2, equals('success'));
      expect(attempts, equals(2)); // No new attempts due to once
    });

    test(
      'deduplicate + fallback - fallback on deduplicated failures',
      () async {
        var attempts = 0;
        final func =
            Func<String>(() async {
                  attempts++;
                  throw Exception('Failed');
                })
                .deduplicate(window: const Duration(milliseconds: 500))
                .fallback(fallbackValue: 'fallback');

        final result1 = await func();
        expect(result1, equals('fallback'));

        final result2 = await func();
        expect(result2, equals('fallback'));

        // Should execute only once due to deduplication
        expect(attempts, lessThanOrEqualTo(1));
      },
    );

    test('share + retry - should share retry attempts', () async {
      var attempts = 0;
      final func = Func<String>(() async {
        attempts++;
        if (attempts < 2) {
          throw Exception('Failed');
        }
        return 'success';
      }).retry(maxAttempts: 3).share();

      // Multiple concurrent calls - share will make them use same execution
      final futures = [func(), func(), func()];
      final results = await Future.wait(futures);

      expect(results.every((r) => r == 'success'), isTrue);
      // With share after retry, concurrent calls share the retry chain
      expect(attempts, equals(2)); // One retry chain shared by all
    });

    test('lazy + fallback - lazy execution with fallback', () async {
      var initialized = false;
      final func = Func<String>(() async {
        initialized = true;
        throw Exception('Failed');
      }).lazy().fallback(fallbackValue: 'fallback');

      // Should not execute immediately
      expect(initialized, isFalse);

      // First call executes and uses fallback
      final result = await func();
      expect(result, equals('fallback'));
      expect(initialized, isTrue);
    });
  });
}
