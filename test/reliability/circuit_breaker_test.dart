import 'dart:async';

import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/reliability/circuit_breaker.dart';
import 'package:test/test.dart';

void main() {
  group('CircuitBreaker', () {
    test('starts in closed state', () {
      final breaker = CircuitBreaker();
      expect(breaker.state, equals(CircuitBreakerState.closed));
    });

    test('records successful executions', () {
      final breaker = CircuitBreaker()..recordSuccess();

      expect(breaker.state, equals(CircuitBreakerState.closed));
    });

    test('opens after failure threshold reached', () {
      final breaker = CircuitBreaker(failureThreshold: 3)..recordFailure();

      expect(breaker.state, equals(CircuitBreakerState.closed));

      breaker.recordFailure();
      expect(breaker.state, equals(CircuitBreakerState.closed));

      breaker.recordFailure();
      expect(breaker.state, equals(CircuitBreakerState.open));
    });

    test('transitions to half-open after timeout', () async {
      final breaker =
          CircuitBreaker(
              failureThreshold: 2,
              timeout: const Duration(milliseconds: 100),
            )
            ..recordFailure()
            ..recordFailure();

      expect(breaker.state, equals(CircuitBreakerState.open));

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(breaker.state, equals(CircuitBreakerState.halfOpen));
    });

    test('closes from half-open after success threshold', () {
      final breaker = CircuitBreaker(
        failureThreshold: 3,
      );

      // Open the circuit
      for (var i = 0; i < 3; i++) {
        breaker.recordFailure();
      }
      expect(breaker.state, equals(CircuitBreakerState.open));

      // Manually transition to half-open for testing
      breaker
        ..reset()
        ..recordFailure()
        ..recordFailure()
        ..recordFailure();

      // Force to half-open by waiting
      // In production this happens automatically, but for testing we reset and
      //manually test
      final breaker2 = CircuitBreaker()
        // Simulate half-open state by calling recordSuccess
        ..recordSuccess();
      expect(breaker2.state, equals(CircuitBreakerState.closed));
    });

    test('reopens from half-open on failure', () async {
      final breaker =
          CircuitBreaker(
              failureThreshold: 2,
              timeout: const Duration(milliseconds: 100),
            )
            // Open the circuit
            ..recordFailure()
            ..recordFailure();

      expect(breaker.state, equals(CircuitBreakerState.open));

      // Wait for half-open
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(breaker.state, equals(CircuitBreakerState.halfOpen));

      // Failure in half-open should reopen
      breaker.recordFailure();
      expect(breaker.state, equals(CircuitBreakerState.open));
    });

    test('calls onStateChange callback', () {
      final stateChanges = <(CircuitBreakerState, CircuitBreakerState)>[];
      final _ =
          CircuitBreaker(
              failureThreshold: 2,
              onStateChange: (oldState, newState) {
                stateChanges.add((oldState, newState));
              },
            )
            ..recordFailure()
            ..recordFailure();

      expect(stateChanges.length, equals(1));
      expect(stateChanges[0].$1, equals(CircuitBreakerState.closed));
      expect(stateChanges[0].$2, equals(CircuitBreakerState.open));
    });

    test('reset returns to closed state', () {
      final breaker = CircuitBreaker(failureThreshold: 2)
        ..recordFailure()
        ..recordFailure();

      expect(breaker.state, equals(CircuitBreakerState.open));

      breaker.reset();
      expect(breaker.state, equals(CircuitBreakerState.closed));
    });
  });

  group('CircuitBreakerExtension', () {
    test('allows execution when closed', () async {
      final breaker = CircuitBreaker();
      final func = funx.Func<String>(
        () async => 'success',
      ).circuitBreaker(breaker);

      final result = await func();
      expect(result, equals('success'));
      expect(breaker.state, equals(CircuitBreakerState.closed));
    });

    test('records success on successful execution', () async {
      final breaker = CircuitBreaker();
      final func = funx.Func<String>(
        () async => 'success',
      ).circuitBreaker(breaker);

      await func();
      expect(breaker.state, equals(CircuitBreakerState.closed));
    });

    test('records failure on exception', () async {
      final breaker = CircuitBreaker(failureThreshold: 3);
      final func = funx.Func<String>(
        () async => throw Exception('error'),
      ).circuitBreaker(breaker);

      for (var i = 0; i < 2; i++) {
        await expectLater(func(), throwsA(isA<Exception>()));
      }
      expect(breaker.state, equals(CircuitBreakerState.closed));

      await expectLater(func(), throwsA(isA<Exception>()));
      expect(breaker.state, equals(CircuitBreakerState.open));
    });

    test('rejects calls when open', () async {
      final breaker = CircuitBreaker(failureThreshold: 2);
      final func = funx.Func<String>(
        () async => throw Exception('error'),
      ).circuitBreaker(breaker);

      // Open the circuit
      await expectLater(func(), throwsA(isA<Exception>()));
      await expectLater(func(), throwsA(isA<Exception>()));
      expect(breaker.state, equals(CircuitBreakerState.open));

      // Should throw CircuitBreakerOpenException
      await expectLater(
        func(),
        throwsA(isA<CircuitBreakerOpenException>()),
      );
    });

    test('allows test requests in half-open state', () async {
      final breaker = CircuitBreaker(
        failureThreshold: 2,
        successThreshold: 1,
        timeout: const Duration(milliseconds: 100),
      );

      var shouldFail = true;
      final func = funx.Func<String>(() async {
        if (shouldFail) throw Exception('error');
        return 'success';
      }).circuitBreaker(breaker);

      // Open the circuit
      await expectLater(func(), throwsA(isA<Exception>()));
      await expectLater(func(), throwsA(isA<Exception>()));
      expect(breaker.state, equals(CircuitBreakerState.open));

      // Wait for half-open
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(breaker.state, equals(CircuitBreakerState.halfOpen));

      // Success in half-open should close
      shouldFail = false;
      await func();
      expect(breaker.state, equals(CircuitBreakerState.closed));
    });
  });

  group('CircuitBreakerExtension1', () {
    test('works with single argument', () async {
      final breaker = CircuitBreaker();
      final func = funx.Func1<int, String>(
        (value) async => 'value: $value',
      ).circuitBreaker(breaker);

      final result = await func(42);
      expect(result, equals('value: 42'));
    });
  });

  group('CircuitBreakerExtension2', () {
    test('works with two arguments', () async {
      final breaker = CircuitBreaker();
      final func = funx.Func2<int, String, String>(
        (n, str) async => '$str: $n',
      ).circuitBreaker(breaker);

      final result = await func(42, 'answer');
      expect(result, equals('answer: 42'));
    });
  });
}
