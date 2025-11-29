import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/reliability/backoff.dart';
import 'package:test/test.dart';

void main() {
  group('RetryExtension', () {
    test('succeeds on first attempt', () async {
      var attempts = 0;
      final func = funx.Func<String>(() async {
        attempts++;
        return 'success';
      }).retry(maxAttempts: 3);

      final result = await func();
      expect(result, equals('success'));
      expect(attempts, equals(1));
    });

    test('retries on failure up to maxAttempts', () async {
      var attempts = 0;
      final func = funx.Func<String>(() async {
        attempts++;
        if (attempts < 3) {
          throw Exception('Failed attempt $attempts');
        }
        return 'success';
      }).retry(maxAttempts: 3);

      final result = await func();
      expect(result, equals('success'));
      expect(attempts, equals(3));
    });

    test('throws after maxAttempts exceeded', () async {
      var attempts = 0;
      final func = funx.Func<String>(() async {
        attempts++;
        throw Exception('Always fails');
      }).retry(maxAttempts: 3);

      await expectLater(func(), throwsA(isA<Exception>()));
      expect(attempts, equals(3));
    });

    test('uses backoff strategy between retries', () async {
      var attempts = 0;
      final timestamps = <DateTime>[];

      final func =
          funx.Func<String>(() async {
            attempts++;
            timestamps.add(DateTime.now());
            if (attempts < 3) {
              throw Exception('Failed');
            }
            return 'success';
          }).retry(
            maxAttempts: 3,
            backoff: const ConstantBackoff(Duration(milliseconds: 100)),
          );

      await func();

      expect(attempts, equals(3));
      expect(timestamps.length, equals(3));

      // Check delays between attempts
      final delay1 = timestamps[1].difference(timestamps[0]);
      final delay2 = timestamps[2].difference(timestamps[1]);

      expect(delay1.inMilliseconds, greaterThanOrEqualTo(90));
      expect(delay2.inMilliseconds, greaterThanOrEqualTo(90));
    });

    test('respects retryIf predicate', () async {
      var attempts = 0;
      final func =
          funx.Func<String>(() async {
            attempts++;
            throw const FormatException('Should not retry');
          }).retry(
            maxAttempts: 3,
            retryIf: (error) => error is StateError, // Only retry StateError
          );

      await expectLater(func(), throwsA(isA<FormatException>()));
      expect(attempts, equals(1)); // Should not retry FormatException
    });

    test('calls onRetry callback', () async {
      var attempts = 0;
      final retryCallbacks = <int>[];
      final errors = <Object>[];

      final func =
          funx.Func<String>(() async {
            attempts++;
            if (attempts < 3) {
              throw Exception('Failed attempt $attempts');
            }
            return 'success';
          }).retry(
            maxAttempts: 3,
            backoff: const ConstantBackoff(Duration(milliseconds: 10)),
            onRetry: (attempt, error) {
              retryCallbacks.add(attempt);
              errors.add(error);
            },
          );

      await func();

      expect(retryCallbacks, equals([1, 2])); // Called on attempts 1 and 2
      expect(errors.length, equals(2));
    });

    test('works with default exponential backoff', () async {
      var attempts = 0;
      final timestamps = <DateTime>[];

      final func = funx.Func<String>(() async {
        attempts++;
        timestamps.add(DateTime.now());
        if (attempts < 3) {
          throw Exception('Failed');
        }
        return 'success';
      }).retry(maxAttempts: 3);

      await func();

      expect(attempts, equals(3));
      expect(timestamps.length, equals(3));

      // With exponential backoff (100ms * 2^attempt), delays should increase
      final delay1 = timestamps[1].difference(timestamps[0]);
      final delay2 = timestamps[2].difference(timestamps[1]);

      expect(delay1.inMilliseconds, greaterThanOrEqualTo(90));
      expect(
        delay2.inMilliseconds,
        greaterThanOrEqualTo(180),
      ); // Should be ~2x first delay
    });

    test('works with maxAttempts=1', () async {
      var attempts = 0;
      final func = funx.Func<String>(() async {
        attempts++;
        throw Exception('Failed');
      }).retry(maxAttempts: 1);

      await expectLater(func(), throwsException);
      expect(attempts, equals(1));
    });
  });

  group('RetryExtension1', () {
    test('retries with function argument', () async {
      var attempts = 0;
      final func = funx.Func1<int, String>((value) async {
        attempts++;
        if (attempts < 2) {
          throw Exception('Failed');
        }
        return 'value: $value';
      }).retry(maxAttempts: 3);

      final result = await func(42);
      expect(result, equals('value: 42'));
      expect(attempts, equals(2));
    });

    test('respects retryIf for Func1', () async {
      var attempts = 0;
      final func =
          funx.Func1<int, String>((value) async {
            attempts++;
            throw StateError('Should not retry');
          }).retry(
            maxAttempts: 3,
            retryIf: (error) => error is FormatException,
          );

      await expectLater(func(42), throwsStateError);
      expect(attempts, equals(1));
    });

    test('uses backoff for Func1', () async {
      var attempts = 0;
      final timestamps = <DateTime>[];

      final func =
          funx.Func1<int, String>((value) async {
            attempts++;
            timestamps.add(DateTime.now());
            if (attempts < 3) {
              throw Exception('Failed');
            }
            return 'success';
          }).retry(
            maxAttempts: 3,
            backoff: const ConstantBackoff(Duration(milliseconds: 50)),
          );

      await func(42);
      expect(timestamps.length, equals(3));
    });

    test('calls onRetry for Func1', () async {
      var attempts = 0;
      final retryCallbacks = <int>[];

      final func =
          funx.Func1<int, String>((value) async {
            attempts++;
            if (attempts < 3) {
              throw Exception('Failed');
            }
            return 'success';
          }).retry(
            maxAttempts: 3,
            backoff: const ConstantBackoff(Duration(milliseconds: 10)),
            onRetry: (attempt, error) => retryCallbacks.add(attempt),
          );

      await func(42);
      expect(retryCallbacks, equals([1, 2]));
    });
  });

  group('RetryExtension2', () {
    test('retries with function arguments', () async {
      var attempts = 0;
      final func = funx.Func2<int, String, String>((n, str) async {
        attempts++;
        if (attempts < 2) {
          throw Exception('Failed');
        }
        return '$str: $n';
      }).retry(maxAttempts: 3);

      final result = await func(42, 'answer');
      expect(result, equals('answer: 42'));
      expect(attempts, equals(2));
    });

    test('respects retryIf for Func2', () async {
      var attempts = 0;
      final func =
          funx.Func2<int, String, String>((n, str) async {
            attempts++;
            throw ArgumentError('Should not retry');
          }).retry(
            maxAttempts: 3,
            retryIf: (error) => error is StateError,
          );

      await expectLater(func(42, 'test'), throwsArgumentError);
      expect(attempts, equals(1));
    });

    test('calls onRetry for Func2', () async {
      var attempts = 0;
      final retryCallbacks = <int>[];

      final func =
          funx.Func2<int, String, String>((n, str) async {
            attempts++;
            if (attempts < 3) {
              throw Exception('Failed');
            }
            return 'success';
          }).retry(
            maxAttempts: 3,
            backoff: const ConstantBackoff(Duration(milliseconds: 10)),
            onRetry: (attempt, error) => retryCallbacks.add(attempt),
          );

      await func(42, 'test');
      expect(retryCallbacks, equals([1, 2]));
    });

    test('uses backoff for Func2', () async {
      var attempts = 0;
      final timestamps = <DateTime>[];

      final func =
          funx.Func2<int, String, String>((n, str) async {
            attempts++;
            timestamps.add(DateTime.now());
            if (attempts < 3) {
              throw Exception('Failed');
            }
            return 'success';
          }).retry(
            maxAttempts: 3,
            backoff: const ConstantBackoff(Duration(milliseconds: 50)),
          );

      await func(42, 'test');
      expect(timestamps.length, equals(3));

      // Check that delays were applied
      final delay1 = timestamps[1].difference(timestamps[0]);
      final delay2 = timestamps[2].difference(timestamps[1]);

      expect(delay1.inMilliseconds, greaterThanOrEqualTo(40));
      expect(delay2.inMilliseconds, greaterThanOrEqualTo(40));
    });
  });
}
