import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('RaceExtension1', () {
    test('returns result from first completed function', () async {
      final func =
          funx.Func1<int, String>((n) async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return 'slow: $n';
          }).race(
            competitors: [
              funx.Func1<int, String>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return 'fast: $n';
              }),
            ],
          );

      final result = await func(42);
      expect(result, 'fast: 42');
    });

    test('inner function can win', () async {
      final func =
          funx.Func1<int, String>((n) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return 'inner: $n';
          }).race(
            competitors: [
              funx.Func1<int, String>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 100));
                return 'competitor: $n';
              }),
            ],
          );

      final result = await func(42);
      expect(result, 'inner: 42');
    });

    test('calls onWin when competitor wins', () async {
      var winnerIndex = -1;
      String? winnerResult;

      final func =
          funx.Func1<int, String>((n) async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return 'slow: $n';
          }).race(
            competitors: [
              funx.Func1<int, String>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return 'fast: $n';
              }),
            ],
            onWin: (index, result) {
              winnerIndex = index;
              winnerResult = result;
            },
          );

      await func(42);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(winnerIndex, 0);
      expect(winnerResult, 'fast: 42');
    });

    test('does not call onWin when inner wins', () async {
      var called = false;

      final func =
          funx.Func1<int, String>((n) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return 'inner: $n';
          }).race(
            competitors: [
              funx.Func1<int, String>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 100));
                return 'slow: $n';
              }),
            ],
            onWin: (index, result) {
              called = true;
            },
          );

      await func(42);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(called, false);
    });

    test('calls onLose for losing functions', () async {
      final losers = <int, String>{};

      final func =
          funx.Func1<int, String>((n) async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return 'inner: $n';
          }).race(
            competitors: [
              funx.Func1<int, String>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return 'winner: $n';
              }),
              funx.Func1<int, String>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 50));
                return 'loser1: $n';
              }),
              funx.Func1<int, String>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 80));
                return 'loser2: $n';
              }),
            ],
            onLose: (index, result) {
              losers[index] = result;
            },
          );

      await func(42);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(losers.length, 3);
      expect(losers[0], 'inner: 42');
      expect(losers[2], 'loser1: 42');
      expect(losers[3], 'loser2: 42');
    });

    test('works with multiple competitors', () async {
      final func =
          funx.Func1<int, int>((n) async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return n * 1;
          }).race(
            competitors: [
              funx.Func1<int, int>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 50));
                return n * 2;
              }),
              funx.Func1<int, int>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return n * 3;
              }),
              funx.Func1<int, int>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 30));
                return n * 4;
              }),
            ],
          );

      final result = await func(10);
      expect(result, 30); // Third competitor (n * 3) is fastest
    });

    test('throws error if all functions fail', () async {
      final func =
          funx.Func1<int, String>((n) async {
            throw Exception('Inner failed');
          }).race(
            competitors: [
              funx.Func1<int, String>((n) async {
                throw Exception('Competitor 1 failed');
              }),
              funx.Func1<int, String>((n) async {
                throw Exception('Competitor 2 failed');
              }),
            ],
          );

      expect(
        () => func(42),
        throwsA(isA<Exception>()),
      );
    });

    test('returns first successful result even if some fail', () async {
      final func =
          funx.Func1<int, String>((n) async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            throw Exception('Inner failed');
          }).race(
            competitors: [
              funx.Func1<int, String>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 50));
                throw Exception('Competitor 1 failed');
              }),
              funx.Func1<int, String>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return 'success: $n';
              }),
            ],
          );

      final result = await func(42);
      expect(result, 'success: 42');
    });

    test('works with zero competitors', () async {
      final func = funx.Func1<int, String>((n) async {
        return 'result: $n';
      }).race(competitors: <funx.Func1<int, String>>[]);

      final result = await func(42);
      expect(result, 'result: 42');
    });

    test('works with synchronous inner function', () async {
      final func =
          funx.Func1<int, String>((n) async {
            return 'sync: $n';
          }).race(
            competitors: [
              funx.Func1<int, String>((n) async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return 'async: $n';
              }),
            ],
          );

      final result = await func(42);
      expect(result, 'sync: 42');
    });
  });

  group('RaceExtension2', () {
    test('returns result from first completed function', () async {
      final func =
          funx.Func2<int, int, String>((a, b) async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return 'slow: ${a + b}';
          }).race(
            competitors: [
              funx.Func2<int, int, String>((a, b) async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return 'fast: ${a + b}';
              }),
            ],
          );

      final result = await func(10, 32);
      expect(result, 'fast: 42');
    });

    test('inner function can win', () async {
      final func =
          funx.Func2<int, int, String>((a, b) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return 'inner: ${a + b}';
          }).race(
            competitors: [
              funx.Func2<int, int, String>((a, b) async {
                await Future<void>.delayed(const Duration(milliseconds: 100));
                return 'competitor: ${a + b}';
              }),
            ],
          );

      final result = await func(10, 32);
      expect(result, 'inner: 42');
    });

    test('calls onWin when competitor wins', () async {
      var winnerIndex = -1;
      String? winnerResult;

      final func =
          funx.Func2<int, int, String>((a, b) async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return 'slow: ${a + b}';
          }).race(
            competitors: [
              funx.Func2<int, int, String>((a, b) async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return 'fast: ${a + b}';
              }),
            ],
            onWin: (index, result) {
              winnerIndex = index;
              winnerResult = result;
            },
          );

      await func(10, 32);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(winnerIndex, 0);
      expect(winnerResult, 'fast: 42');
    });

    test('does not call onWin when inner wins', () async {
      var called = false;

      final func =
          funx.Func2<int, int, String>((a, b) async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return 'inner: ${a + b}';
          }).race(
            competitors: [
              funx.Func2<int, int, String>((a, b) async {
                await Future<void>.delayed(const Duration(milliseconds: 100));
                return 'slow: ${a + b}';
              }),
            ],
            onWin: (index, result) {
              called = true;
            },
          );

      await func(10, 32);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(called, false);
    });

    test('calls onLose for losing functions', () async {
      final losers = <int, String>{};

      final func =
          funx.Func2<int, int, String>((a, b) async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return 'inner: ${a + b}';
          }).race(
            competitors: [
              funx.Func2<int, int, String>((a, b) async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return 'winner: ${a + b}';
              }),
              funx.Func2<int, int, String>((a, b) async {
                await Future<void>.delayed(const Duration(milliseconds: 50));
                return 'loser1: ${a + b}';
              }),
            ],
            onLose: (index, result) {
              losers[index] = result;
            },
          );

      await func(10, 32);
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(losers.length, 2);
      expect(losers[0], 'inner: 42');
      expect(losers[2], 'loser1: 42');
    });

    test('works with multiple competitors', () async {
      final func =
          funx.Func2<int, int, int>((a, b) async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return a + b;
          }).race(
            competitors: [
              funx.Func2<int, int, int>((a, b) async {
                await Future<void>.delayed(const Duration(milliseconds: 50));
                return a * b;
              }),
              funx.Func2<int, int, int>((a, b) async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return a - b;
              }),
            ],
          );

      final result = await func(10, 5);
      expect(result, 5); // Fastest is a - b = 10 - 5 = 5
    });

    test('throws error if all functions fail', () async {
      final func =
          funx.Func2<int, int, String>((a, b) async {
            throw Exception('Inner failed');
          }).race(
            competitors: [
              funx.Func2<int, int, String>((a, b) async {
                throw Exception('Competitor failed');
              }),
            ],
          );

      expect(
        () => func(10, 32),
        throwsA(isA<Exception>()),
      );
    });

    test('returns first successful result even if some fail', () async {
      final func =
          funx.Func2<int, int, String>((a, b) async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            throw Exception('Inner failed');
          }).race(
            competitors: [
              funx.Func2<int, int, String>((a, b) async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return 'success: ${a + b}';
              }),
            ],
          );

      final result = await func(10, 32);
      expect(result, 'success: 42');
    });

    test('works with zero competitors', () async {
      final func = funx.Func2<int, int, String>((a, b) async {
        return 'result: ${a + b}';
      }).race(competitors: <funx.Func2<int, int, String>>[]);

      final result = await func(10, 32);
      expect(result, 'result: 42');
    });
  });
}
