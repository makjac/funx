import 'package:funx/funx.dart' as funx;
import 'package:test/test.dart';

// Test helpers for tracking extension behavior
final logs = <String>[];

// Custom decorator example from README
extension RequestIdDecorator<R> on funx.Func<R> {
  funx.Func<R> withRequestId() {
    return funx.Func<R>(() async {
      final requestId = _generateId();
      logs.add('[Request $requestId] Starting');

      try {
        final result = await call();
        logs.add('[Request $requestId] Success');
        return result;
      } catch (e) {
        logs.add('[Request $requestId] Error: $e');
        rethrow;
      }
    });
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

// Pattern for Custom Decorators example from README
extension CustomDecorator<R> on funx.Func<R> {
  funx.Func<R> customBehavior() {
    return funx.Func<R>(() async {
      // 1. Pre-processing
      logs.add('pre-processing');

      // 2. Execute original function
      try {
        final result = await call();

        // 3. Post-processing
        logs.add('post-processing: $result');
        return result;
      } catch (e) {
        // 4. Error handling
        logs.add('error-handling: $e');
        rethrow;
      } finally {
        // 5. Cleanup
        logs.add('cleanup');
      }
    });
  }
}

// Synchronous Decorators example from README
extension CustomSyncDecorator<R> on funx.FuncSync<R> {
  funx.FuncSync<R> withLogging() {
    return funx.FuncSync<R>(() {
      logs.add('Executing function');
      final result = call();
      logs.add('Result: $result');
      return result;
    });
  }
}

void main() {
  setUp(logs.clear);

  group('README Examples - Custom Extensions', () {
    test('RequestIdDecorator example works', () async {
      // Simulate api.fetch()
      var callCount = 0;
      final apiCall = funx.Func<String>(() async {
        callCount++;
        if (callCount == 1) throw Exception('Network error');
        return 'API response';
      }).withRequestId().retry(maxAttempts: 3);

      final result = await apiCall();

      expect(result, equals('API response'));
      expect(callCount, equals(2)); // First failed, second succeeded
      expect(
        logs.length,
        greaterThanOrEqualTo(2),
      ); // At least Starting and Success
      expect(logs.any((log) => log.contains('Starting')), isTrue);
      expect(logs.any((log) => log.contains('Success')), isTrue);
    });

    test('Pattern for Custom Decorators - pre/post processing', () async {
      // Test successful execution
      final successFunc = funx.Func<String>(() async {
        logs.add('executing');
        return 'result';
      }).customBehavior();

      final result = await successFunc();

      expect(result, equals('result'));
      expect(
        logs,
        equals([
          'pre-processing',
          'executing',
          'post-processing: result',
          'cleanup',
        ]),
      );
    });

    test('Pattern for Custom Decorators - error handling', () async {
      final errorFunc = funx.Func<String>(() async {
        logs.add('executing');
        throw Exception('fail');
      }).customBehavior();

      try {
        await errorFunc();
        fail('Should have thrown');
      } catch (e) {
        expect(e.toString(), contains('fail'));
      }

      expect(
        logs,
        equals([
          'pre-processing',
          'executing',
          'error-handling: Exception: fail',
          'cleanup',
        ]),
      );
    });

    test('Synchronous Decorators example works', () {
      final calculate = funx.FuncSync<int>(() {
        return 42;
      }).withLogging();

      final result = calculate();

      expect(result, equals(42));
      expect(
        logs,
        equals([
          'Executing function',
          'Result: 42',
        ]),
      );
    });
  });
}
