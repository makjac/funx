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
  });
}
