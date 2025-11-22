import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/reliability/recover.dart';
import 'package:test/test.dart';

void main() {
  group('RecoveryStrategy', () {
    test('can be created with required parameters', () {
      final strategy = RecoveryStrategy(
        onError: (error) async {},
      );

      expect(strategy.rethrowAfterRecovery, isTrue);
      expect(strategy.shouldRecover, isNull);
    });

    test('can configure rethrowAfterRecovery', () {
      final strategy = RecoveryStrategy(
        onError: (error) async {},
        rethrowAfterRecovery: false,
      );

      expect(strategy.rethrowAfterRecovery, isFalse);
    });
  });

  group('RecoverExtension', () {
    test('returns result on success', () async {
      var recoveryCalled = false;
      final strategy = RecoveryStrategy(
        onError: (error) async {
          recoveryCalled = true;
        },
      );

      final func = funx.Func<String>(() async => 'success').recover(strategy);

      final result = await func();
      expect(result, equals('success'));
      expect(recoveryCalled, isFalse);
    });

    test('calls recovery action on error', () async {
      var recoveryCalled = false;
      Object? capturedError;

      final strategy = RecoveryStrategy(
        onError: (error) async {
          recoveryCalled = true;
          capturedError = error;
        },
      );

      final func = funx.Func<String>(
        () async => throw Exception('test error'),
      ).recover(strategy);

      await expectLater(func(), throwsA(isA<Exception>()));
      expect(recoveryCalled, isTrue);
      expect(capturedError, isA<Exception>());
    });

    test('rethrows error after recovery by default', () async {
      var recoveryCalled = false;
      final strategy = RecoveryStrategy(
        onError: (error) async {
          recoveryCalled = true;
        },
      );

      final func = funx.Func<String>(
        () async => throw Exception('test error'),
      ).recover(strategy);

      await expectLater(func(), throwsA(isA<Exception>()));
      expect(recoveryCalled, isTrue);
    });

    test('respects shouldRecover predicate', () async {
      var recoveryCalled = false;
      final strategy = RecoveryStrategy(
        onError: (error) async {
          recoveryCalled = true;
        },
        shouldRecover: (error) => error is StateError,
      );

      final func = funx.Func<String>(
        () async => throw const FormatException('error'),
      ).recover(strategy);

      await expectLater(func(), throwsA(isA<FormatException>()));
      expect(recoveryCalled, isFalse);
    });

    test('calls recovery for matching errors', () async {
      var recoveryCalled = false;
      final strategy = RecoveryStrategy(
        onError: (error) async {
          recoveryCalled = true;
        },
        shouldRecover: (error) => error is StateError,
      );

      final func = funx.Func<String>(
        () async => throw StateError('error'),
      ).recover(strategy);

      await expectLater(func(), throwsA(isA<StateError>()));
      expect(recoveryCalled, isTrue);
    });

    test('throws StateError when not rethrowing', () async {
      final strategy = RecoveryStrategy(
        onError: (error) async {},
        rethrowAfterRecovery: false,
      );

      final func = funx.Func<String>(
        () async => throw Exception('error'),
      ).recover(strategy);

      await expectLater(func(), throwsA(isA<StateError>()));
    });

    test('can perform cleanup actions', () async {
      var cleanupPerformed = false;
      final resources = <String>[];

      final strategy = RecoveryStrategy(
        onError: (error) async {
          cleanupPerformed = true;
          resources.clear();
        },
      );

      resources.add('resource1');
      final func = funx.Func<String>(() async {
        throw Exception('error');
      }).recover(strategy);

      await expectLater(func(), throwsA(isA<Exception>()));
      expect(cleanupPerformed, isTrue);
      expect(resources, isEmpty);
    });

    test('can attempt reconnection', () async {
      var connected = false;
      var reconnectAttempted = false;

      final strategy = RecoveryStrategy(
        onError: (error) async {
          reconnectAttempted = true;
          connected = true; // Simulate successful reconnection
        },
      );

      final func = funx.Func<String>(() async {
        if (!connected) throw Exception('Not connected');
        return 'success';
      }).recover(strategy);

      await expectLater(func(), throwsA(isA<Exception>()));
      expect(reconnectAttempted, isTrue);
      expect(connected, isTrue);
    });
  });

  group('RecoverExtension1', () {
    test('calls recovery with single argument function', () async {
      var recoveryCalled = false;
      final strategy = RecoveryStrategy(
        onError: (error) async {
          recoveryCalled = true;
        },
      );

      final func = funx.Func1<int, String>(
        (value) async => throw Exception('error'),
      ).recover(strategy);

      await expectLater(func(42), throwsA(isA<Exception>()));
      expect(recoveryCalled, isTrue);
    });
  });

  group('RecoverExtension2', () {
    test('calls recovery with two argument function', () async {
      var recoveryCalled = false;
      final strategy = RecoveryStrategy(
        onError: (error) async {
          recoveryCalled = true;
        },
      );

      final func = funx.Func2<int, String, String>(
        (n, str) async => throw Exception('error'),
      ).recover(strategy);

      await expectLater(func(42, 'test'), throwsA(isA<Exception>()));
      expect(recoveryCalled, isTrue);
    });
  });
}
