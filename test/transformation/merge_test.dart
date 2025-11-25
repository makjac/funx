import 'package:funx/src/core/func.dart' as funx;
import 'package:funx/src/transformation/merge.dart';
import 'package:test/test.dart';

void main() {
  group('MergeExtension1', () {
    test('merges results from multiple sources', () async {
      final source1 = funx.Func1<int, int>((n) async => n + 1);
      final source2 = funx.Func1<int, int>((n) async => n * 2);
      final source3 = funx.Func1<int, int>((n) async => n * n);

      final merged = MergeExtension1<int, List<int>>(
        [source1, source2, source3],
        combiner: (results) => results.cast<int>(),
      );

      expect(await merged(5), [6, 10, 25]);
    });

    test('executes sources in parallel', () async {
      final startTimes = <int>[];

      final source1 = funx.Func1<int, int>((n) async {
        startTimes.add(DateTime.now().millisecondsSinceEpoch);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return n + 1;
      });

      final source2 = funx.Func1<int, int>((n) async {
        startTimes.add(DateTime.now().millisecondsSinceEpoch);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return n + 2;
      });

      final merged = MergeExtension1<int, List<int>>(
        [source1, source2],
        combiner: (results) => results.cast<int>(),
      );

      await merged(10);

      // Both should start at roughly the same time (parallel execution)
      expect((startTimes[1] - startTimes[0]).abs(), lessThan(10));
    });

    test('combines different result types', () async {
      final source1 = funx.Func1<String, int>((s) async => s.length);
      final source2 = funx.Func1<String, String>((s) async => s.toUpperCase());
      final source3 = funx.Func1<String, bool>((s) async => s.isNotEmpty);

      final merged = MergeExtension1<String, Map<String, dynamic>>(
        [source1, source2, source3],
        combiner: (results) => {
          'length': results[0],
          'upper': results[1],
          'notEmpty': results[2],
        },
      );

      final result = await merged('hello');
      expect(result['length'], 5);
      expect(result['upper'], 'HELLO');
      expect(result['notEmpty'], true);
    });

    test('handles empty sources list', () async {
      final merged = MergeExtension1<int, List<int>>(
        [],
        combiner: (results) => results.cast<int>(),
      );

      expect(await merged(42), isEmpty);
    });

    test('handles single source', () async {
      final source = funx.Func1<int, int>((n) async => n * 2);

      final merged = MergeExtension1<int, int>(
        [source],
        combiner: (results) => results[0] as int,
      );

      expect(await merged(21), 42);
    });

    test('propagates error from any source', () async {
      final source1 = funx.Func1<int, int>((n) async => n + 1);
      final source2 = funx.Func1<int, int>(
        (n) async => throw StateError('source2 error'),
      );

      final merged = MergeExtension1<int, List<int>>(
        [source1, source2],
        combiner: (results) => results.cast<int>(),
      );

      expect(() => merged(5), throwsStateError);
    });

    test('combiner can aggregate results', () async {
      final source1 = funx.Func1<int, int>((n) async => n);
      final source2 = funx.Func1<int, int>((n) async => n * 2);
      final source3 = funx.Func1<int, int>((n) async => n * 3);

      final merged = MergeExtension1<int, int>(
        [source1, source2, source3],
        combiner: (results) => results.cast<int>().reduce((a, b) => a + b),
      );

      expect(await merged(10), 60); // 10 + 20 + 30
    });
  });

  group('MergeExtension2', () {
    test('merges results from two-argument sources', () async {
      final source1 = funx.Func2<int, int, int>((a, b) async => a + b);
      final source2 = funx.Func2<int, int, int>((a, b) async => a * b);
      final source3 = funx.Func2<int, int, int>((a, b) async => a - b);

      final merged = MergeExtension2<int, int, List<int>>(
        [source1, source2, source3],
        combiner: (results) => results.cast<int>(),
      );

      expect(await merged(10, 5), [15, 50, 5]);
    });

    test('executes sources in parallel', () async {
      final startTimes = <int>[];

      final source1 = funx.Func2<int, int, int>((a, b) async {
        startTimes.add(DateTime.now().millisecondsSinceEpoch);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return a + b;
      });

      final source2 = funx.Func2<int, int, int>((a, b) async {
        startTimes.add(DateTime.now().millisecondsSinceEpoch);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return a * b;
      });

      final merged = MergeExtension2<int, int, List<int>>(
        [source1, source2],
        combiner: (results) => results.cast<int>(),
      );

      await merged(5, 3);

      expect((startTimes[1] - startTimes[0]).abs(), lessThan(10));
    });

    test('combines to single value', () async {
      final source1 = funx.Func2<int, int, int>((a, b) async => a);
      final source2 = funx.Func2<int, int, int>((a, b) async => b);

      final merged = MergeExtension2<int, int, int>(
        [source1, source2],
        combiner: (results) {
          final values = results.cast<int>();
          return values[0] + values[1];
        },
      );

      expect(await merged(10, 20), 30);
    });

    test('handles different return types', () async {
      final source1 = funx.Func2<int, int, String>((a, b) async => '$a+$b');
      final source2 = funx.Func2<int, int, int>((a, b) async => a + b);
      final source3 = funx.Func2<int, int, bool>((a, b) async => a > b);

      final merged = MergeExtension2<int, int, Map<String, dynamic>>(
        [source1, source2, source3],
        combiner: (results) => {
          'expr': results[0],
          'sum': results[1],
          'greater': results[2],
        },
      );

      final result = await merged(10, 5);
      expect(result['expr'], '10+5');
      expect(result['sum'], 15);
      expect(result['greater'], true);
    });

    test('propagates error from any source', () async {
      final source1 = funx.Func2<int, int, int>((a, b) async => a + b);
      final source2 = funx.Func2<int, int, int>(
        (a, b) async => throw ArgumentError('test'),
      );

      final merged = MergeExtension2<int, int, List<int>>(
        [source1, source2],
        combiner: (results) => results.cast<int>(),
      );

      expect(() => merged(1, 2), throwsArgumentError);
    });

    test('handles empty sources list', () async {
      final merged = MergeExtension2<int, int, List<int>>(
        [],
        combiner: (results) => results.cast<int>(),
      );

      expect(await merged(1, 2), isEmpty);
    });
  });

  group('Merge edge cases', () {
    test('combiner receives results in order', () async {
      final source1 = funx.Func1<int, String>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return 'first';
      });
      final source2 = funx.Func1<int, String>((n) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 'second';
      });

      final merged = MergeExtension1<int, List<String>>(
        [source1, source2],
        combiner: (results) => results.cast<String>(),
      );

      // Results should maintain order despite different completion times
      expect(await merged(1), ['first', 'second']);
    });

    test('error in combiner propagates', () async {
      final source = funx.Func1<int, int>((n) async => n);

      final merged = MergeExtension1<int, int>(
        [source],
        combiner: (results) => throw StateError('combiner error'),
      );

      expect(() => merged(42), throwsStateError);
    });

    test('works with large number of sources', () async {
      final sources = List.generate(
        100,
        (i) => funx.Func1<int, int>((n) async => n + i),
      );

      final merged = MergeExtension1<int, int>(
        sources,
        combiner: (results) => results.cast<int>().reduce((a, b) => a + b),
      );

      // Sum of 0..99 = 4950
      expect(await merged(0), 4950);
    });
  });
}
