/// Integration tests for Validation + Error Handling pattern combinations.
library;

import 'package:funx/funx.dart' hide Func1, Func2;
import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('Validation + Error handling combinations', () {
    test('guard + catch - should catch guard violations', () async {
      final func =
          funx.Func1<int, String>((n) async {
                return 'result-$n';
              })
              .guard(
                preCondition: (n) => n > 0,
                preConditionMessage: 'Must be positive',
              )
              .catchError(
                handlers: {
                  GuardException: (e) async => 'caught',
                },
              );

      final result = await func(-1);
      expect(result, equals('caught'));
    });

    test('validate + fallback - should fallback on validation error', () async {
      final func =
          funx.Func1<String, String>((email) async {
                return 'Sent to $email';
              })
              .validate(
                validators: [
                  (email) => email.contains('@') ? null : 'Invalid email',
                ],
              )
              .fallback(fallbackValue: 'validation failed');

      final result = await func('invalid-email');
      expect(result, equals('validation failed'));
    });

    test('guard + retry - should retry on guard violations', () async {
      var counter = 0;
      final func =
          Func<String>(() async {
                counter++;
                return 'result';
              })
              .retry(maxAttempts: 5)
              .guard(
                preCondition: () => counter >= 2,
              );

      // Guard check happens before retry, so we need the counter to be ready
      // This test shows guard works but retry won't help with guard failures
      // because guard checks happen outside the retry logic
      expect(() async => func(), throwsA(isA<GuardException>()));
    });

    test(
      'validate + default - should use default on validation failure',
      () async {
        final func =
            funx.Func1<int, int>((n) async {
                  return n * 2;
                })
                .validate(
                  validators: [
                    (n) => n >= 0 ? null : 'Must be non-negative',
                  ],
                )
                .defaultValue(defaultValue: 0);

        final result = await func(-5);
        expect(result, equals(0));
      },
    );

    test('guard + fallback - fallback on guard failure', () async {
      final func =
          funx.Func1<int, int>((n) async {
                return n * 2;
              })
              .guard(
                preCondition: (n) => n > 0,
                preConditionMessage: 'Must be positive',
              )
              .fallback(fallbackValue: -1);

      final result = await func(-5);
      expect(result, equals(-1));
    });

    test('validate + catch - catch validation exceptions', () async {
      final func =
          funx.Func1<String, String>((email) async {
                return 'Sent to $email';
              })
              .validate(
                validators: [
                  (email) => email.contains('@') ? null : 'Invalid email',
                ],
              )
              .catchError(
                handlers: {
                  ValidationException: (e) async => 'caught validation error',
                },
              );

      final result = await func('invalid');
      expect(result, equals('caught validation error'));
    });

    test('guard + default - default on guard violation', () async {
      final func =
          funx.Func1<int, String>((n) async {
                return 'value: $n';
              })
              .guard(
                preCondition: (n) => n >= 0,
              )
              .defaultValue(defaultValue: 'default');

      final result = await func(-1);
      expect(result, equals('default'));
    });

    test('validate + retry - retry on validation before execution', () async {
      var validationPasses = 0;
      final func =
          funx.Func1<int, int>((n) async {
                return n * 2;
              })
              .validate(
                validators: [
                  (n) {
                    validationPasses++;
                    return validationPasses >= 2 ? null : 'Not ready';
                  },
                ],
              )
              .retry(maxAttempts: 3);

      final result = await func(5);
      expect(result, equals(10));
      expect(validationPasses, greaterThanOrEqualTo(2));
    });

    test('guard pre and post conditions with catch', () async {
      final func =
          funx.Func1<int, int>((n) async {
                return n * 2;
              })
              .guard(
                preCondition: (n) => n > 0,
                postCondition: (result) => result > 0,
              )
              .catchError(
                handlers: {
                  GuardException: (e) async => -1,
                },
              );

      // Valid input
      final result1 = await func(5);
      expect(result1, equals(10));

      // Invalid input
      final result2 = await func(-5);
      expect(result2, equals(-1));
    });

    test('validate multiple fields with fallback', () async {
      final func =
          funx.Func2<String, int, String>((email, age) async {
                return 'User: $email, Age: $age';
              })
              .validate(
                validators: [
                  (email, age) => email.contains('@') ? null : 'Invalid email',
                  (email, age) => age >= 0 ? null : 'Invalid age',
                ],
              )
              .fallback(fallbackValue: 'Invalid user data');

      // Valid
      final result1 = await func('test@example.com', 25);
      expect(result1, contains('User:'));

      // Invalid email
      final result2 = await func('invalid', 25);
      expect(result2, equals('Invalid user data'));

      // Invalid age
      final result3 = await func('test@example.com', -5);
      expect(result3, equals('Invalid user data'));
    });
  });
}
