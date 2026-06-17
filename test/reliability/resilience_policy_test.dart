import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('ResiliencePolicy', () {
    test('empty policy returns the original wrapper unchanged', () async {
      final calls = <int>[];
      final func = Func<int>(() async {
        calls.add(1);
        return 42;
      });

      final decorated = func.withPolicy(const ResiliencePolicy<int>());

      expect(await decorated(), equals(42));
      expect(calls, equals([1]));
    });

    test('applies timeout only', () async {
      final func = Func<String>(() async {
        await Future<void>.delayed(const Duration(seconds: 10));
        return 'late';
      });

      final decorated = func.withPolicy(
        const ResiliencePolicy<String>(
          timeout: Duration(milliseconds: 50),
        ),
      );

      expect(decorated(), throwsA(isA<TimeoutException>()));
    });

    test('applies retry only', () async {
      var attempts = 0;
      final func = Func<String>(() async {
        attempts++;
        if (attempts < 3) throw Exception('fail');
        return 'success';
      });

      final decorated = func.withPolicy(
        const ResiliencePolicy<String>(
          retry: RetryConfig(),
        ),
      );

      expect(await decorated(), equals('success'));
      expect(attempts, equals(3));
    });

    test('applies circuit breaker only', () async {
      final func = Func<int>(() async => throw Exception('always fails'));

      final decorated = func.withPolicy(
        const ResiliencePolicy<int>(
          circuitBreaker: CircuitBreakerConfig(failureThreshold: 2),
        ),
      );

      await expectLater(decorated(), throwsA(isA<Exception>()));
      await expectLater(decorated(), throwsA(isA<Exception>()));
      await expectLater(
        decorated(),
        throwsA(isA<CircuitBreakerOpenException>()),
      );
    });

    test('applies fallback value only', () async {
      final func = Func<String>(() async => throw Exception('fail'));

      final decorated = func.withPolicy(
        const ResiliencePolicy<String>(
          fallback: FallbackConfig(fallbackValue: 'default'),
        ),
      );

      expect(await decorated(), equals('default'));
    });

    test('applies fallback function only', () async {
      final func = Func<int>(() async => throw Exception('fail'));

      final decorated = func.withPolicy(
        ResiliencePolicy<int>(
          fallback: FallbackConfig(
            fallbackFunction: (error) => (error as Exception).toString().length,
          ),
        ),
      );

      expect(await decorated(), isPositive);
    });

    test('respects fallbackIf predicate', () async {
      final func = Func<int>(() async => throw Exception('no fallback'));

      final decorated = func.withPolicy(
        const ResiliencePolicy<int>(
          fallback: FallbackConfig(
            fallbackValue: 0,
            fallbackIf: _isTimeout,
          ),
        ),
      );

      await expectLater(decorated(), throwsA(isA<Exception>()));
    });

    test('calls onFallback when fallback is used', () async {
      Object? capturedError;
      final func = Func<int>(() async => throw Exception('fail'));

      final decorated = func.withPolicy(
        ResiliencePolicy<int>(
          fallback: FallbackConfig(
            fallbackValue: 7,
            onFallback: (error) => capturedError = error,
          ),
        ),
      );

      expect(await decorated(), equals(7));
      expect(capturedError, isA<Exception>());
    });

    test('applies decorators in correct order', () async {
      var attempts = 0;
      final func = Func<int>(() async {
        attempts++;
        throw Exception('transient');
      });

      final decorated = func.withPolicy(
        const ResiliencePolicy<int>(
          timeout: Duration(seconds: 5),
          retry: RetryConfig(maxAttempts: 2),
          circuitBreaker: CircuitBreakerConfig(failureThreshold: 1),
          fallback: FallbackConfig(fallbackValue: -1),
        ),
      );

      // First call: retry twice, then circuit breaker opens and fallback
      // returns -1.
      expect(await decorated(), equals(-1));
      expect(attempts, equals(2));

      // Subsequent calls hit the open circuit and fallback immediately.
      expect(await decorated(), equals(-1));
      expect(attempts, equals(2));
    });

    test('withResilience builder builds and applies policy', () async {
      final func = Func<String>(() async => throw Exception('fail'));

      final decorated = func.withResilience(
        (b) => b
            .timeout(const Duration(seconds: 2))
            .retry(maxAttempts: 2)
            .fallbackValue('safe')
            .build(),
      );

      expect(await decorated(), equals('safe'));
    });

    test('Func1 supports withPolicy', () async {
      final func = Func1<int, int>((int n) async => n * 2);

      final decorated = func.withPolicy(
        const ResiliencePolicy<int>(
          fallback: FallbackConfig(fallbackValue: 0),
        ),
      );

      expect(await decorated(5), equals(10));
    });

    test('Func1 supports withResilience', () async {
      final func = Func1<int, int>((int n) async => throw Exception('fail'));

      final decorated = func.withResilience(
        (ResiliencePolicyBuilder<int> b) =>
            b.retry(maxAttempts: 2).fallbackValue(-1).build(),
      );

      expect(await decorated(5), equals(-1));
    });

    test('Func2 supports withPolicy', () async {
      final func = Func2<int, int, int>(
        (int a, int b) async => a + b,
      );

      final decorated = func.withPolicy(
        const ResiliencePolicy<int>(
          fallback: FallbackConfig(fallbackValue: 0),
        ),
      );

      expect(await decorated(2, 3), equals(5));
    });

    test('Func2 supports withResilience', () async {
      final func = Func2<int, int, int>(
        (int a, int b) async => throw Exception('fail'),
      );

      final decorated = func.withResilience(
        (ResiliencePolicyBuilder<int> b) =>
            b.fallbackFunction((_) => 42).build(),
      );

      expect(await decorated(2, 3), equals(42));
    });

    test('chains with memoize and cancellable', () async {
      var calls = 0;
      final func = Func<int>(() async {
        calls++;
        if (calls.isOdd) throw Exception('fail');
        return calls;
      });

      final decorated = func
          .memoize()
          .withPolicy(
            const ResiliencePolicy<int>(
              retry: RetryConfig(maxAttempts: 2),
              fallback: FallbackConfig(fallbackValue: 99),
            ),
          )
          .cancellable();

      expect(await decorated(), equals(2));
      expect(await decorated(), equals(2));
      expect(calls, equals(2));
    });

    test('copyWith replaces fields', () {
      const policy = ResiliencePolicy<int>(
        timeout: Duration(seconds: 1),
        retry: RetryConfig(maxAttempts: 2),
      );

      final updated = policy.copyWith(
        retry: const RetryConfig(maxAttempts: 5),
        clearTimeout: true,
      );

      expect(updated.timeout, isNull);
      expect(updated.retry?.maxAttempts, equals(5));
      expect(updated.circuitBreaker, isNull);
      expect(updated.fallback, isNull);
    });
  });
}

bool _isTimeout(Object error) => error is TimeoutException;
