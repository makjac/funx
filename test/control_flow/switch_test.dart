import 'package:funx/funx.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('SwitchExtension1', () {
    test('executes correct case based on selector', () async {
      final switched = funx.SwitchExtension1<String, String>(
        selector: (String input) => input.length,
        cases: {
          5: funx.Func1<String, String>((s) async => 'five'),
          4: funx.Func1<String, String>((s) async => 'four'),
          3: funx.Func1<String, String>((s) async => 'three'),
        },
      );

      expect(await switched('hello'), 'five');
      expect(await switched('test'), 'four');
      expect(await switched('abc'), 'three');
    });

    test('uses default case when no match', () async {
      final switched = funx.SwitchExtension1<int, String>(
        selector: (int n) => n % 2,
        cases: {
          0: funx.Func1<int, String>((n) async => 'even'),
        },
        defaultCase: funx.Func1<int, String>((n) async => 'odd'),
      );

      expect(await switched(4), 'even');
      expect(await switched(5), 'odd');
      expect(await switched(100), 'even');
      expect(await switched(99), 'odd');
    });

    test('throws SwitchException when no match and no default', () async {
      final switched = funx.SwitchExtension1<String, String>(
        selector: (String s) => s[0],
        cases: {
          'a': funx.Func1<String, String>((s) async => 'starts with a'),
          'b': funx.Func1<String, String>((s) async => 'starts with b'),
        },
      );

      await expectLater(
        switched('apple'),
        completion('starts with a'),
      );

      expect(
        () => switched('carrot'),
        throwsA(isA<funx.SwitchException>()),
      );
    });

    test('handles null selector value', () async {
      final switched = funx.SwitchExtension1<String?, String>(
        selector: (String? s) => s,
        cases: {
          null: funx.Func1<String?, String>((s) async => 'was null'),
          'test': funx.Func1<String?, String>((s) async => 'was test'),
        },
      );

      expect(await switched(null), 'was null');
      expect(await switched('test'), 'was test');
    });

    test('passes argument to case function', () async {
      final switched = funx.SwitchExtension1<int, int>(
        selector: (int n) => n > 10,
        cases: {
          true: funx.Func1<int, int>((n) async => n * 2),
          false: funx.Func1<int, int>((n) async => n + 10),
        },
      );

      expect(await switched(20), 40); // 20 * 2
      expect(await switched(5), 15); // 5 + 10
    });

    test('works with complex selector logic', () async {
      final switched = funx.SwitchExtension1<Map<String, dynamic>, String>(
        selector: (Map<String, dynamic> data) {
          if (data.containsKey('error')) return 'error';
          if (data.containsKey('success')) return 'success';
          return 'unknown';
        },
        cases: {
          'error': funx.Func1<Map<String, dynamic>, String>(
            (d) async => 'Error: ${d["error"]}',
          ),
          'success': funx.Func1<Map<String, dynamic>, String>(
            (d) async => 'Success: ${d["success"]}',
          ),
        },
        defaultCase: funx.Func1<Map<String, dynamic>, String>(
          (d) async => 'Unknown data',
        ),
      );

      expect(
        await switched({'error': 'Not found'}),
        'Error: Not found',
      );
      expect(
        await switched({'success': 'Done'}),
        'Success: Done',
      );
      expect(
        await switched({'other': 'data'}),
        'Unknown data',
      );
    });
  });

  group('SwitchExtension2', () {
    test('executes correct case based on selector', () async {
      final switched = funx.SwitchExtension2<int, int, int>(
        selector: (int a, int b) => (a + b) % 2,
        cases: {
          0: funx.Func2<int, int, int>((a, b) async => (a + b) * 2),
          1: funx.Func2<int, int, int>((a, b) async => (a + b) * 3),
        },
      );

      expect(await switched(2, 2), 8); // (2+2)*2 = 8
      expect(await switched(2, 3), 15); // (2+3)*3 = 15
    });

    test('uses default case when no match', () async {
      final switched = funx.SwitchExtension2<String, String, String>(
        selector: (String a, String b) => a.length + b.length,
        cases: {
          5: funx.Func2<String, String, String>(
            (a, b) async => 'total 5: $a$b',
          ),
        },
        defaultCase: funx.Func2<String, String, String>(
          (a, b) async => 'other: $a$b',
        ),
      );

      expect(await switched('ab', 'cde'), 'total 5: abcde');
      expect(await switched('a', 'b'), 'other: ab');
    });

    test('throws SwitchException when no match and no default', () async {
      final switched = funx.SwitchExtension2<int, int, String>(
        selector: (int a, int b) => a + b,
        cases: {
          10: funx.Func2<int, int, String>((a, b) async => 'sum is 10'),
        },
      );

      expect(
        () => switched(3, 4),
        throwsA(isA<funx.SwitchException>()),
      );
    });

    test('passes both arguments to case function', () async {
      final switched = funx.SwitchExtension2<int, int, String>(
        selector: (int a, int b) => a.compareTo(b),
        cases: {
          -1: funx.Func2<int, int, String>(
            (a, b) async => '$a < $b',
          ),
          0: funx.Func2<int, int, String>(
            (a, b) async => '$a == $b',
          ),
          1: funx.Func2<int, int, String>(
            (a, b) async => '$a > $b',
          ),
        },
      );

      expect(await switched(5, 10), '5 < 10');
      expect(await switched(10, 10), '10 == 10');
      expect(await switched(15, 10), '15 > 10');
    });
  });

  group('SwitchException', () {
    test('contains selector value', () {
      final exception = funx.SwitchException('test');
      expect(exception.value, 'test');
      expect(exception.toString(), contains('test'));
    });

    test('toString includes value', () {
      final exception = funx.SwitchException(42);
      expect(exception.toString(), contains('42'));
    });

    test('works with null value', () {
      final exception = funx.SwitchException(null);
      expect(exception.value, isNull);
      expect(exception.toString(), contains('null'));
    });
  });

  group('Switch edge cases', () {
    test('selector is called with original argument', () async {
      var selectorCalled = false;
      int? selectorArg;

      final switched = funx.SwitchExtension1<int, int>(
        selector: (int n) {
          selectorCalled = true;
          selectorArg = n;
          return 'key';
        },
        cases: {
          'key': funx.Func1<int, int>((n) async => n * 2),
        },
      );

      await switched(42);

      expect(selectorCalled, true);
      expect(selectorArg, 42);
    });

    test('case function errors propagate', () async {
      final switched = funx.SwitchExtension1<int, int>(
        selector: (int n) => 'error',
        cases: {
          'error': funx.Func1<int, int>(
            (n) async => throw StateError('case error'),
          ),
        },
      );

      expect(() => switched(1), throwsStateError);
    });

    test('works with string selector values', () async {
      final switched = funx.SwitchExtension1<String, String>(
        selector: (String s) => s.length > 5 ? 'long' : 'short',
        cases: {
          'long': funx.Func1<String, String>(
            (s) async => s.toUpperCase(),
          ),
          'short': funx.Func1<String, String>(
            (s) async => s.toLowerCase(),
          ),
        },
      );

      expect(await switched('hello'), 'hello');
      expect(await switched('verylongstring'), 'VERYLONGSTRING');
    });

    test('selector called once per invocation', () async {
      var selectorCallCount = 0;

      final switched = funx.SwitchExtension1<int, int>(
        selector: (int n) {
          selectorCallCount++;
          return n % 2;
        },
        cases: {
          0: funx.Func1<int, int>((n) async => n * 2),
          1: funx.Func1<int, int>((n) async => n * 3),
        },
      );

      await switched(10);
      await switched(11);

      expect(selectorCallCount, 2);
    });
  });
}
