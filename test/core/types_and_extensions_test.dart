import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart';

void main() {
  group('Enum values', () {
    test('DebounceMode has expected values', () {
      expect(DebounceMode.values, contains(DebounceMode.leading));
      expect(DebounceMode.values, contains(DebounceMode.trailing));
    });

    test('ThrottleMode has expected values', () {
      expect(ThrottleMode.values, contains(ThrottleMode.leading));
      expect(ThrottleMode.values, contains(ThrottleMode.trailing));
    });

    test('QueueMode has expected values', () {
      expect(QueueMode.values, contains(QueueMode.fifo));
      expect(QueueMode.values, contains(QueueMode.lifo));
    });

    test('ScheduleMode has expected values', () {
      expect(ScheduleMode.values, contains(ScheduleMode.once));
      expect(ScheduleMode.values, contains(ScheduleMode.recurring));
      expect(ScheduleMode.values, contains(ScheduleMode.custom));
    });

    test('MissedExecutionPolicy has expected values', () {
      expect(
        MissedExecutionPolicy.values,
        contains(MissedExecutionPolicy.executeImmediately),
      );
      expect(
        MissedExecutionPolicy.values,
        contains(MissedExecutionPolicy.skip),
      );
      expect(
        MissedExecutionPolicy.values,
        contains(MissedExecutionPolicy.catchUp),
      );
      expect(
        MissedExecutionPolicy.values,
        contains(MissedExecutionPolicy.reschedule),
      );
    });

    test('BackpressureStrategy has expected values', () {
      expect(BackpressureStrategy.values, contains(BackpressureStrategy.drop));
      expect(
        BackpressureStrategy.values,
        contains(BackpressureStrategy.dropOldest),
      );
      expect(
        BackpressureStrategy.values,
        contains(BackpressureStrategy.buffer),
      );
      expect(
        BackpressureStrategy.values,
        contains(BackpressureStrategy.sample),
      );
      expect(
        BackpressureStrategy.values,
        contains(BackpressureStrategy.throttle),
      );
      expect(BackpressureStrategy.values, contains(BackpressureStrategy.error));
    });

    test('CompressionAlgorithm has expected values', () {
      expect(CompressionAlgorithm.values, contains(CompressionAlgorithm.zlib));
      expect(CompressionAlgorithm.values, contains(CompressionAlgorithm.gzip));
    });

    test('EvictionPolicy has expected values', () {
      expect(EvictionPolicy.values, contains(EvictionPolicy.lru));
      expect(EvictionPolicy.values, contains(EvictionPolicy.lfu));
      expect(EvictionPolicy.values, contains(EvictionPolicy.fifo));
    });

    test('RateLimitStrategy has expected values', () {
      expect(RateLimitStrategy.values, contains(RateLimitStrategy.tokenBucket));
      expect(RateLimitStrategy.values, contains(RateLimitStrategy.leakyBucket));
      expect(RateLimitStrategy.values, contains(RateLimitStrategy.fixedWindow));
      expect(
        RateLimitStrategy.values,
        contains(RateLimitStrategy.slidingWindow),
      );
    });
  });

  group('Plain function extensions', () {
    test('0-arg retry extension', () async {
      var count = 0;
      Future<String> fn() async {
        count++;
        if (count == 1) throw Exception('fail');
        return 'ok';
      }

      final result = await fn.retry(maxAttempts: 2)();
      expect(result, 'ok');
    });

    test('1-arg timeout extension', () async {
      Future<int> fn(String key) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return key.length;
      }

      await expectLater(
        fn.timeout(const Duration(milliseconds: 10))('hello'),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('2-arg fallback extension', () async {
      Future<int> fn(int a, int b) async => throw Exception('fail');
      final result = await fn.fallback(fallbackValue: 0)(3, 4);
      expect(result, 0);
    });
  });

  group('Future extensions', () {
    test('withTimeout throws on slow future', () async {
      final future = Future<int>.delayed(
        const Duration(seconds: 1),
        () => 42,
      );
      await expectLater(
        future.withTimeout(const Duration(milliseconds: 10)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('withTimeout returns fast future', () async {
      final future = Future<int>.value(42);
      expect(await future.withTimeout(const Duration(seconds: 1)), 42);
    });

    test('withFallback returns value on success', () async {
      final future = Future<int>.value(7);
      expect(await future.withFallback(fallbackValue: 0), 7);
    });

    test('withFallback returns fallback on error', () async {
      final future = Future<int>.error(Exception('fail'));
      expect(await future.withFallback(fallbackValue: 0), 0);
    });
  });
}
