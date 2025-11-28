import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart';

void main() {
  group('README Examples - Testing Section', () {
    test('Basic Testing - debounce delays execution', () async {
      var count = 0;
      final fn = Func<int>(
        () async => ++count,
      ).debounce(const Duration(milliseconds: 100));

      unawaited(fn());
      unawaited(fn());
      final future = fn();

      await Future<void>.delayed(const Duration(milliseconds: 150));
      final result = await future;

      expect(result, 1); // only last call executed
      expect(count, 1);
    });

    test('Testing Retry Logic - retry with backoff', () async {
      var attempts = 0;

      final fn =
          Func<String>(() async {
            attempts++;
            if (attempts < 3) throw Exception('Fail');
            return 'Success';
          }).retry(
            maxAttempts: 3,
            backoff: const ConstantBackoff(Duration(milliseconds: 50)),
          );

      final result = await fn();

      expect(result, 'Success');
      expect(attempts, 3);
    });

    test('Testing Composition - composed mechanisms', () async {
      var executions = 0;

      final fn = Func<String>(() async {
        executions++;
        return 'result';
      }).memoize().retry(maxAttempts: 2);

      await fn();
      await fn();

      expect(executions, 1); // memoized, executed once
    });
  });
}
