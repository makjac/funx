import 'package:funx/src/concurrency/countdown_latch.dart';
import 'package:funx/src/core/func.dart' as funx;
import 'package:test/test.dart';

void main() {
  group('CountdownLatch', () {
    test('waits for N operations to complete', () async {
      final latch = CountdownLatch(count: 3);

      expect(latch.count, equals(3));

      latch.countDown();
      expect(latch.count, equals(2));

      latch.countDown();
      expect(latch.count, equals(1));

      final awaitFuture = latch.await_();

      latch.countDown();
      await awaitFuture;

      expect(latch.count, equals(0));
    });

    test('blocks until count reaches zero', () async {
      final latch = CountdownLatch(count: 2);
      var completed = false;

      final awaitFuture = latch.await_().then((_) {
        completed = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(completed, isFalse);

      latch.countDown();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(completed, isFalse);

      latch.countDown();
      await awaitFuture;
      expect(completed, isTrue);
    });

    test('calls onComplete callback', () async {
      var callbackCalled = false;
      final latch = CountdownLatch(
        count: 2,
        onComplete: () => callbackCalled = true,
      )..countDown();

      expect(callbackCalled, isFalse);

      latch.countDown();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(callbackCalled, isTrue);
    });

    test('isComplete returns correct status', () async {
      final latch = CountdownLatch(count: 2);

      expect(latch.isComplete, isFalse);

      latch.countDown();
      expect(latch.isComplete, isFalse);

      latch.countDown();
      expect(latch.isComplete, isTrue);
    });

    test('await_ returns immediately when already complete', () async {
      final latch = CountdownLatch(count: 1)..countDown();

      expect(latch.isComplete, isTrue);

      final result = await latch.await_();
      expect(result, isTrue);
    });

    test('await_ respects timeout', () async {
      final latch = CountdownLatch(count: 2)..countDown();

      final result = await latch.await_(
        timeout: const Duration(milliseconds: 100),
      );

      expect(result, isFalse); // Should timeout
      expect(latch.count, equals(1));
    });

    test('throws StateError when counting down below zero', () async {
      final latch = CountdownLatch(count: 1)..countDown();

      expect(latch.countDown.call, throwsStateError);
    });

    test('await_ with timeout returns true when completed', () async {
      final latch = CountdownLatch(count: 1);

      final awaitFuture = latch.await_(
        timeout: const Duration(milliseconds: 200),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      latch.countDown();

      final result = await awaitFuture;
      expect(result, isTrue);
    });
  });

  group('CountdownLatchExtension', () {
    test('counts down after execution', () async {
      final latch = CountdownLatch(count: 3);

      final func = funx.Func(() async {
        return 42;
      }).countdownLatch(latch);

      await func();
      expect(latch.count, equals(2));

      await func();
      expect(latch.count, equals(1));

      await func();
      expect(latch.count, equals(0));
    });

    test('provides access to latch instance', () async {
      final latch = CountdownLatch(count: 2);
      final wrapped = funx.Func(() async => 42).countdownLatch(latch);

      expect((wrapped as CountdownLatchExtension).latch, equals(latch));
    });
  });

  group('CountdownLatchExtension1', () {
    test('works with parameters', () async {
      final latch = CountdownLatch(count: 2);

      final func = funx.Func1<int, int>((n) async {
        return n * 2;
      }).countdownLatch(latch);

      await func(5);
      expect(latch.count, equals(1));

      await func(10);
      expect(latch.count, equals(0));
    });

    test('provides access to latch instance', () async {
      final latch = CountdownLatch(count: 2);
      final wrapped = funx.Func1<int, int>(
        (n) async => n * 2,
      ).countdownLatch(latch);

      expect((wrapped as CountdownLatchExtension1).latch, equals(latch));
    });
  });

  group('CountdownLatchExtension2', () {
    test('works with two parameters', () async {
      final latch = CountdownLatch(count: 2);

      final func = funx.Func2<int, int, int>((a, b) async {
        return a + b;
      }).countdownLatch(latch);

      await func(1, 2);
      expect(latch.count, equals(1));

      await func(3, 4);
      expect(latch.count, equals(0));
    });

    test('provides access to latch instance', () async {
      final latch = CountdownLatch(count: 2);
      final wrapped = funx.Func2<int, int, int>(
        (a, b) async => a + b,
      ).countdownLatch(latch);

      expect((wrapped as CountdownLatchExtension2).latch, equals(latch));
    });
  });
}
