import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart';

void main() {
  group('StampedeProtection', () {
    test('coalesces concurrent loads for the same key', () async {
      var loadCount = 0;
      final protection = StampedeProtection<String, int>();

      Future<int> loader() async {
        loadCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 42;
      }

      final results = await Future.wait([
        protection.load('key', loader),
        protection.load('key', loader),
        protection.load('key', loader),
        protection.load('key', loader),
      ]);

      expect(results, everyElement(42));
      expect(loadCount, 1);
    });

    test('allows separate loads for different keys', () async {
      var loadCount = 0;
      final protection = StampedeProtection<String, int>();

      Future<int> loader(String key) async {
        loadCount++;
        return key.length;
      }

      final results = await Future.wait([
        protection.load('a', () => loader('a')),
        protection.load('bb', () => loader('bb')),
      ]);

      expect(results, [1, 2]);
      expect(loadCount, 2);
    });

    test('retries after error for next caller', () async {
      var loadCount = 0;
      final protection = StampedeProtection<String, int>();

      Future<int> loader() async {
        loadCount++;
        if (loadCount == 1) throw Exception('fail');
        return 42;
      }

      await expectLater(
        protection.load('key', loader),
        throwsA(isA<Exception>()),
      );
      final result = await protection.load('key', loader);
      expect(result, 42);
      expect(loadCount, 2);
    });
  });
}
