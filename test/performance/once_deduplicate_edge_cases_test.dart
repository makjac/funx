import 'package:funx/funx.dart' hide Func1, Func2;
import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('Once edge cases', () {
    test('Once caches error and does not re-execute', () async {
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        throw Exception('fail');
      }).once();

      await expectLater(func(), throwsA(isA<Exception>()));
      await expectLater(func(), throwsA(isA<Exception>()));
      expect(count, 1);
    });

    test('Once caches success and returns same value', () async {
      var count = 0;
      final func = funx.Func<int>(() async => ++count).once();

      expect(await func(), 1);
      expect(await func(), 1);
      expect(count, 1);
    });

    test('Once reset after success allows re-execution', () async {
      var count = 0;
      final func =
          funx.Func<int>(() async => ++count).once() as OnceExtension<int>;

      expect(await func(), 1);
      func.reset();
      expect(await func(), 2);
      expect(count, 2);
    });
  });

  group('Deduplicate edge cases', () {
    test('Deduplicate per argument', () async {
      final counts = <String, int>{};
      final func = funx.Func1<String, int>((key) async {
        counts[key] = (counts[key] ?? 0) + 1;
        return key.length;
      }).deduplicate(window: const Duration(seconds: 1));

      expect(await func('a'), 1);
      expect(await func('a'), 1);
      expect(await func('b'), 1);
      expect(counts['a'], 1);
      expect(counts['b'], 1);
    });

    test('Deduplicate reset per argument', () async {
      var count = 0;
      final func =
          funx.Func1<String, int>((key) async {
                count++;
                return key.length;
              }).deduplicate(window: const Duration(seconds: 1))
              as DeduplicateExtension1<String, int>;

      await func('a');
      func.resetArg('a');
      await func('a');
      expect(count, 2);
    });

    test('Deduplicate with errors does not block subsequent calls', () async {
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        throw Exception('fail');
      }).deduplicate(window: const Duration(milliseconds: 50));

      await expectLater(func(), throwsA(isA<Exception>()));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await expectLater(func(), throwsA(isA<Exception>()));
      expect(count, 2);
    });
  });
}
