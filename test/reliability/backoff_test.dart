import 'package:funx/src/reliability/backoff.dart';
import 'package:test/test.dart';

void main() {
  group('ConstantBackoff', () {
    test('returns same delay for all attempts', () {
      const backoff = ConstantBackoff(Duration(seconds: 1));

      expect(backoff.calculate(attempt: 1), equals(const Duration(seconds: 1)));
      expect(backoff.calculate(attempt: 5), equals(const Duration(seconds: 1)));
      expect(
        backoff.calculate(attempt: 100),
        equals(const Duration(seconds: 1)),
      );
    });
  });

  group('LinearBackoff', () {
    test('increases delay linearly', () {
      const backoff = LinearBackoff(
        initialDelay: Duration(milliseconds: 100),
        increment: Duration(milliseconds: 50),
      );

      expect(
        backoff.calculate(attempt: 1),
        equals(const Duration(milliseconds: 100)),
      );
      expect(
        backoff.calculate(attempt: 2),
        equals(const Duration(milliseconds: 150)),
      );
      expect(
        backoff.calculate(attempt: 3),
        equals(const Duration(milliseconds: 200)),
      );
      expect(
        backoff.calculate(attempt: 4),
        equals(const Duration(milliseconds: 250)),
      );
    });

    test('respects maxDelay cap', () {
      const backoff = LinearBackoff(
        initialDelay: Duration(milliseconds: 100),
        increment: Duration(milliseconds: 100),
        maxDelay: Duration(milliseconds: 250),
      );

      expect(
        backoff.calculate(attempt: 1),
        equals(const Duration(milliseconds: 100)),
      );
      expect(
        backoff.calculate(attempt: 2),
        equals(const Duration(milliseconds: 200)),
      );
      expect(
        backoff.calculate(attempt: 3),
        equals(const Duration(milliseconds: 250)),
      );
      expect(
        backoff.calculate(attempt: 4),
        equals(const Duration(milliseconds: 250)),
      );
      expect(
        backoff.calculate(attempt: 10),
        equals(const Duration(milliseconds: 250)),
      );
    });
  });

  group('ExponentialBackoff', () {
    test('increases delay exponentially with default multiplier', () {
      const backoff = ExponentialBackoff(
        initialDelay: Duration(milliseconds: 100),
      );

      expect(
        backoff.calculate(attempt: 1),
        equals(const Duration(milliseconds: 100)),
      );
      expect(
        backoff.calculate(attempt: 2),
        equals(const Duration(milliseconds: 200)),
      );
      expect(
        backoff.calculate(attempt: 3),
        equals(const Duration(milliseconds: 400)),
      );
      expect(
        backoff.calculate(attempt: 4),
        equals(const Duration(milliseconds: 800)),
      );
    });

    test('uses custom multiplier', () {
      const backoff = ExponentialBackoff(
        initialDelay: Duration(milliseconds: 100),
        multiplier: 3,
      );

      expect(
        backoff.calculate(attempt: 1),
        equals(const Duration(milliseconds: 100)),
      );
      expect(
        backoff.calculate(attempt: 2),
        equals(const Duration(milliseconds: 300)),
      );
      expect(
        backoff.calculate(attempt: 3),
        equals(const Duration(milliseconds: 900)),
      );
    });

    test('respects maxDelay cap', () {
      const backoff = ExponentialBackoff(
        initialDelay: Duration(milliseconds: 100),
        maxDelay: Duration(milliseconds: 500),
      );

      expect(
        backoff.calculate(attempt: 1),
        equals(const Duration(milliseconds: 100)),
      );
      expect(
        backoff.calculate(attempt: 2),
        equals(const Duration(milliseconds: 200)),
      );
      expect(
        backoff.calculate(attempt: 3),
        equals(const Duration(milliseconds: 400)),
      );
      expect(
        backoff.calculate(attempt: 4),
        equals(const Duration(milliseconds: 500)),
      );
      expect(
        backoff.calculate(attempt: 10),
        equals(const Duration(milliseconds: 500)),
      );
    });
  });

  group('FibonacciBackoff', () {
    test('follows Fibonacci sequence', () {
      const backoff = FibonacciBackoff(
        baseDelay: Duration(milliseconds: 100),
      );

      expect(
        backoff.calculate(attempt: 1),
        equals(const Duration(milliseconds: 100)),
      ); // F(1) = 1
      expect(
        backoff.calculate(attempt: 2),
        equals(const Duration(milliseconds: 100)),
      ); // F(2) = 1
      expect(
        backoff.calculate(attempt: 3),
        equals(const Duration(milliseconds: 200)),
      ); // F(3) = 2
      expect(
        backoff.calculate(attempt: 4),
        equals(const Duration(milliseconds: 300)),
      ); // F(4) = 3
      expect(
        backoff.calculate(attempt: 5),
        equals(const Duration(milliseconds: 500)),
      ); // F(5) = 5
      expect(
        backoff.calculate(attempt: 6),
        equals(const Duration(milliseconds: 800)),
      ); // F(6) = 8
    });

    test('respects maxDelay cap', () {
      const backoff = FibonacciBackoff(
        baseDelay: Duration(milliseconds: 100),
        maxDelay: Duration(milliseconds: 400),
      );

      expect(
        backoff.calculate(attempt: 1),
        equals(const Duration(milliseconds: 100)),
      );
      expect(
        backoff.calculate(attempt: 3),
        equals(const Duration(milliseconds: 200)),
      );
      expect(
        backoff.calculate(attempt: 4),
        equals(const Duration(milliseconds: 300)),
      );
      expect(
        backoff.calculate(attempt: 5),
        equals(const Duration(milliseconds: 400)),
      );
      expect(
        backoff.calculate(attempt: 6),
        equals(const Duration(milliseconds: 400)),
      );
    });
  });

  group('DecorrelatedJitterBackoff', () {
    test('returns values within expected range', () {
      final backoff = DecorrelatedJitterBackoff(
        baseDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(seconds: 10),
      );

      for (var i = 1; i <= 10; i++) {
        final delay = backoff.calculate(attempt: i);
        expect(delay.inMilliseconds, greaterThanOrEqualTo(100));
        expect(delay.inMilliseconds, lessThanOrEqualTo(10000));
      }
    });

    test('respects maxDelay cap', () {
      final backoff = DecorrelatedJitterBackoff(
        baseDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(milliseconds: 500),
      );

      for (var i = 1; i <= 20; i++) {
        final delay = backoff.calculate(attempt: i);
        expect(delay.inMilliseconds, lessThanOrEqualTo(500));
      }
    });

    test('reset clears previous delay', () {
      final backoff =
          DecorrelatedJitterBackoff(
              baseDelay: const Duration(milliseconds: 100),
            )
            ..calculate(attempt: 1)
            ..calculate(attempt: 2)
            ..reset();

      // After reset, should start fresh
      final delay = backoff.calculate(attempt: 1);
      expect(delay.inMilliseconds, greaterThanOrEqualTo(100));
    });
  });

  group('CustomBackoff', () {
    test('uses custom calculator function', () {
      final backoff = CustomBackoff(
        calculator: (attempt) => Duration(seconds: attempt * attempt),
      );

      expect(backoff.calculate(attempt: 1), equals(const Duration(seconds: 1)));
      expect(backoff.calculate(attempt: 2), equals(const Duration(seconds: 4)));
      expect(backoff.calculate(attempt: 3), equals(const Duration(seconds: 9)));
      expect(
        backoff.calculate(attempt: 4),
        equals(const Duration(seconds: 16)),
      );
    });

    test('allows any custom logic', () {
      var callCount = 0;
      final backoff = CustomBackoff(
        calculator: (attempt) {
          callCount++;
          return Duration(milliseconds: 100 * (attempt % 3 + 1));
        },
      );

      expect(
        backoff.calculate(attempt: 1),
        equals(const Duration(milliseconds: 200)),
      );
      expect(
        backoff.calculate(attempt: 2),
        equals(const Duration(milliseconds: 300)),
      );
      expect(
        backoff.calculate(attempt: 3),
        equals(const Duration(milliseconds: 100)),
      );
      expect(callCount, equals(3));
    });
  });
}
