import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('AllExtension1', () {
    test('executes all functions and collects results', () async {
      final func =
          funx.Func1<int, String>((n) async {
            return 'inner: $n';
          }).all(
            functions: [
              funx.Func1<int, String>((n) async => 'func1: $n'),
              funx.Func1<int, String>((n) async => 'func2: $n'),
            ],
          );

      final results = await func(42);
      expect(results.length, 3);
      expect(results[0], 'inner: 42');
      expect(results[1], 'func1: 42');
      expect(results[2], 'func2: 42');
    });

    test('executes functions in parallel', () async {
      final timestamps = <int, DateTime>{};

      final func =
          funx.Func1<int, String>((n) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            timestamps[0] = DateTime.now();
            return 'inner: $n';
          }).all(
            functions: [
              funx.Func1<int, String>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 50));
                timestamps[1] = DateTime.now();
                return 'func1: $n';
              }),
              funx.Func1<int, String>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 50));
                timestamps[2] = DateTime.now();
                return 'func2: $n';
              }),
            ],
          );

      final start = DateTime.now();
      await func(42);
      final duration = DateTime.now().difference(start);

      // All should complete in ~50ms, not 150ms (if parallel)
      expect(duration.inMilliseconds, lessThan(100));

      // All timestamps should be close together
      final diff1 = timestamps[1]!
          .difference(timestamps[0]!)
          .inMilliseconds
          .abs();
      final diff2 = timestamps[2]!
          .difference(timestamps[0]!)
          .inMilliseconds
          .abs();
      expect(diff1, lessThan(20));
      expect(diff2, lessThan(20));
    });

    test('calls onComplete for each function', () async {
      final completed = <int, String>{};

      final func =
          funx.Func1<int, String>((n) async {
            return 'inner: $n';
          }).all(
            functions: [
              funx.Func1<int, String>((n) async => 'func1: $n'),
              funx.Func1<int, String>((n) async => 'func2: $n'),
            ],
            onComplete: (index, result) {
              completed[index] = result;
            },
          );

      await func(42);

      expect(completed.length, 3);
      expect(completed[0], 'inner: 42');
      expect(completed[1], 'func1: 42');
      expect(completed[2], 'func2: 42');
    });

    test('fails fast on first error when failFast=true', () async {
      final func =
          funx.Func1<int, String>((n) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            throw Exception('Inner failed');
          }).all(
            functions: [
              funx.Func1<int, String>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 50));
                return 'func1: $n';
              }),
            ],
            failFast: true,
          );

      expect(
        () => func(42),
        throwsA(isA<Exception>()),
      );
    });

    test('collects all results when failFast=false and no errors', () async {
      final func =
          funx.Func1<int, String>((n) async {
            return 'inner: $n';
          }).all(
            functions: [
              funx.Func1<int, String>((n) async => 'func1: $n'),
              funx.Func1<int, String>((n) async => 'func2: $n'),
            ],
            failFast: false,
          );

      final results = await func(42);
      expect(results.length, 3);
      expect(results[0], 'inner: 42');
      expect(results[1], 'func1: 42');
      expect(results[2], 'func2: 42');
    });

    test('works with single function (inner only)', () async {
      final func = funx.Func1<int, String>((n) async {
        return 'inner: $n';
      }).all(functions: <funx.Func1<int, String>>[]);

      final results = await func(42);
      expect(results.length, 1);
      expect(results[0], 'inner: 42');
    });

    test('preserves result order', () async {
      final func =
          funx.Func1<int, int>((n) async {
            await Future<void>.delayed(const Duration(milliseconds: 30));
            return n * 1;
          }).all(
            functions: [
              funx.Func1<int, int>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return n * 2;
              }),
              funx.Func1<int, int>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 20));
                return n * 3;
              }),
            ],
          );

      final results = await func(10);
      expect(results[0], 10); // Slowest but first
      expect(results[1], 20); // Fastest but second
      expect(results[2], 30); // Medium but third
    });

    test('works with different result types via transformation', () async {
      final func =
          funx.Func1<int, int>((n) async {
            return n;
          }).all(
            functions: [
              funx.Func1<int, int>((n) async => n * 2),
              funx.Func1<int, int>((n) async => n * 3),
            ],
          );

      final results = await func(10);
      expect(results, [10, 20, 30]);
    });

    test('handles empty functions list', () async {
      final func = funx.Func1<int, String>((n) async {
        return 'result: $n';
      }).all(functions: <funx.Func1<int, String>>[]);

      final results = await func(42);
      expect(results, ['result: 42']);
    });

    test('propagates all errors when failFast=false and all fail', () async {
      final func =
          funx.Func1<int, String>((n) async {
            throw Exception('Inner failed');
          }).all(
            functions: [
              funx.Func1<int, String>((n) async {
                throw Exception('Func1 failed');
              }),
            ],
            failFast: false,
          );

      expect(
        () => func(42),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AllExtension2', () {
    test('executes all functions and collects results', () async {
      final func =
          funx.Func2<int, int, String>((a, b) async {
            return 'inner: ${a + b}';
          }).all(
            functions: [
              funx.Func2<int, int, String>((a, b) async => 'func1: ${a + b}'),
              funx.Func2<int, int, String>((a, b) async => 'func2: ${a + b}'),
            ],
          );

      final results = await func(10, 32);
      expect(results.length, 3);
      expect(results[0], 'inner: 42');
      expect(results[1], 'func1: 42');
      expect(results[2], 'func2: 42');
    });

    test('executes functions in parallel', () async {
      final timestamps = <int, DateTime>{};

      final func =
          funx.Func2<int, int, String>((a, b) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            timestamps[0] = DateTime.now();
            return 'inner: ${a + b}';
          }).all(
            functions: [
              funx.Func2<int, int, String>((a, b) async {
                await Future<void>.delayed(const Duration(milliseconds: 50));
                timestamps[1] = DateTime.now();
                return 'func1: ${a + b}';
              }),
            ],
          );

      final start = DateTime.now();
      await func(10, 32);
      final duration = DateTime.now().difference(start);

      expect(duration.inMilliseconds, lessThan(80));
    });

    test('calls onComplete for each function', () async {
      final completed = <int, String>{};

      final func =
          funx.Func2<int, int, String>((a, b) async {
            return 'inner: ${a + b}';
          }).all(
            functions: [
              funx.Func2<int, int, String>((a, b) async => 'func1: ${a + b}'),
            ],
            onComplete: (index, result) {
              completed[index] = result;
            },
          );

      await func(10, 32);

      expect(completed.length, 2);
      expect(completed[0], 'inner: 42');
      expect(completed[1], 'func1: 42');
    });

    test('fails fast on first error when failFast=true', () async {
      final func =
          funx.Func2<int, int, String>((a, b) async {
            throw Exception('Inner failed');
          }).all(
            functions: [
              funx.Func2<int, int, String>((a, b) async => 'func1: ${a + b}'),
            ],
            failFast: true,
          );

      expect(
        () => func(10, 32),
        throwsA(isA<Exception>()),
      );
    });

    test('collects all results when failFast=false', () async {
      final func =
          funx.Func2<int, int, String>((a, b) async {
            return 'inner: ${a + b}';
          }).all(
            functions: [
              funx.Func2<int, int, String>((a, b) async => 'func1: ${a + b}'),
            ],
            failFast: false,
          );

      final results = await func(10, 32);
      expect(results.length, 2);
      expect(results[0], 'inner: 42');
      expect(results[1], 'func1: 42');
    });

    test('preserves result order', () async {
      final func =
          funx.Func2<int, int, int>((a, b) async {
            await Future<void>.delayed(const Duration(milliseconds: 30));
            return a + b;
          }).all(
            functions: [
              funx.Func2<int, int, int>((a, b) async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return a * b;
              }),
            ],
          );

      final results = await func(10, 5);
      expect(results[0], 15); // Slower but first
      expect(results[1], 50); // Faster but second
    });

    test('works with empty functions list', () async {
      final func = funx.Func2<int, int, String>((a, b) async {
        return 'result: ${a + b}';
      }).all(functions: <funx.Func2<int, int, String>>[]);

      final results = await func(10, 32);
      expect(results, ['result: 42']);
    });

    test('propagates errors when failFast=false and all fail', () async {
      final func =
          funx.Func2<int, int, String>((a, b) async {
            throw Exception('Inner failed');
          }).all(
            functions: [
              funx.Func2<int, int, String>((a, b) async {
                throw Exception('Func1 failed');
              }),
            ],
            failFast: false,
          );

      expect(
        () => func(10, 32),
        throwsA(isA<Exception>()),
      );
    });
  });
}
