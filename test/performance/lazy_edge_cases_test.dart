import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('LazyExtension edge cases', () {
    test('Func lazy defers execution until first call', () async {
      var initialized = false;
      final func = funx.Func<int>(() async {
        initialized = true;
        return 42;
      }).lazy();

      expect(initialized, isFalse);
      expect(await func(), 42);
      expect(initialized, isTrue);
    });

    test('Func1 lazy defers execution until first call', () async {
      var initialized = false;
      final func = funx.Func1<String, int>((key) async {
        initialized = true;
        return key.length;
      }).lazy();

      expect(initialized, isFalse);
      expect(await func('hello'), 5);
      expect(initialized, isTrue);
    });

    test('Func2 lazy defers execution until first call', () async {
      var initialized = false;
      final func = funx.Func2<int, int, int>((a, b) async {
        initialized = true;
        return a + b;
      }).lazy();

      expect(initialized, isFalse);
      expect(await func(2, 3), 5);
      expect(initialized, isTrue);
    });

    test('Lazy does not cache results', () async {
      var count = 0;
      final func = funx.Func<int>(() async => ++count).lazy();

      expect(await func(), 1);
      expect(await func(), 2);
    });

    test('Multiple concurrent callers before first init share single execution',
        () async {
      var count = 0;
      final func = funx.Func<int>(() async {
        count++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 7;
      }).lazy();

      final results = await Future.wait<int>([func(), func(), func()]);
      expect(results, everyElement(7));
      expect(count, 3);
    });
  });
}
