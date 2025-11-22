import 'dart:async';

import 'package:funx/funx.dart';
import 'package:test/test.dart' hide Func1, Func2;

void main() {
  group('WarmUpExtension - onInit trigger', () {
    test('executes immediately when created', () async {
      var callCount = 0;
      final func = Func(() async {
        callCount++;
        return 42;
      }).warmUp(trigger: WarmUpTrigger.onInit);

      // Give time for warm-up to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(callCount, equals(1)); // Already called during warmUp

      final result = await func();
      expect(result, equals(42));
      // Should return cached result, not call again
      expect(callCount, equals(1));
    });

    test('keeps cache fresh with periodic refresh', () async {
      var callCount = 0;
      final func =
          Func(() async {
                return ++callCount;
              }).warmUp(
                trigger: WarmUpTrigger.onInit,
                keepFresh: const Duration(milliseconds: 100),
              )
              as WarmUpExtension<int>;

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final initialCount = callCount;

      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(callCount, greaterThan(initialCount)); // Refreshed

      func.dispose();
    });

    test('dispose() stops periodic refresh', () async {
      var callCount = 0;
      final func =
          Func(() async {
                return ++callCount;
              }).warmUp(
                trigger: WarmUpTrigger.onInit,
                keepFresh: const Duration(milliseconds: 100),
              )
              as WarmUpExtension<int>;

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final countBeforeDispose = callCount;

      func.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(callCount, equals(countBeforeDispose)); // No more refreshes
    });
  });

  group('WarmUpExtension - onFirstCall trigger', () {
    test('executes on first call, not on creation', () async {
      var callCount = 0;
      final func = Func(() async {
        callCount++;
        return 42;
      }).warmUp(trigger: WarmUpTrigger.onFirstCall);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(callCount, equals(0)); // Not called yet

      await func();
      expect(callCount, equals(1)); // Called on first call
    });
  });

  group('WarmUpExtension - manual trigger', () {
    test('does not execute until manually warmed up', () async {
      var callCount = 0;
      final func =
          Func(() async {
                callCount++;
                return 42;
              }).warmUp(trigger: WarmUpTrigger.manual)
              as WarmUpExtension<int>;

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(callCount, equals(0)); // Not called yet

      await func();
      expect(callCount, equals(1)); // Called on actual call only
    });
  });

  group('WarmUpExtension1', () {
    test('warmUpWith() pre-executes with specific argument', () async {
      var callCount = 0;
      final func =
          Func1((int x) async {
                callCount++;
                return x * 2;
              }).warmUp(trigger: WarmUpTrigger.manual)
              as WarmUpExtension1<int, int>;

      unawaited(func.warmUpWith(5));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(callCount, equals(1)); // Warmed up with arg 5

      final result = await func(5);
      expect(result, equals(10));
      // Should return cached result for arg 5
      expect(callCount, equals(1));
    });

    test('warmUpWith() can be called multiple times', () async {
      var callCount = 0;
      final func =
          Func1((int x) async {
                callCount++;
                return x * 2;
              }).warmUp(trigger: WarmUpTrigger.manual)
              as WarmUpExtension1<int, int>;

      unawaited(func.warmUpWith(5));
      unawaited(func.warmUpWith(10));
      unawaited(func.warmUpWith(15));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(callCount, equals(3));
    });

    test('onFirstCall warms up with first argument', () async {
      var callCount = 0;
      final calledWith = <int>[];

      final func = Func1((int x) async {
        callCount++;
        calledWith.add(x);
        return x * 2;
      }).warmUp(trigger: WarmUpTrigger.onFirstCall);

      await func(7);

      expect(callCount, equals(1));
      expect(calledWith, equals([7]));
    });
  });

  group('WarmUpExtension2', () {
    test('warmUpWith() pre-executes with specific arguments', () async {
      var callCount = 0;
      final func =
          Func2((int a, int b) async {
                callCount++;
                return a + b;
              }).warmUp(trigger: WarmUpTrigger.manual)
              as WarmUpExtension2<int, int, int>;

      unawaited(func.warmUpWith(3, 4));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(callCount, equals(1));

      final result = await func(3, 4);
      expect(result, equals(7));
      // Should return cached result
      expect(callCount, equals(1));
    });

    test('keeps cache fresh for specific arguments', () async {
      var callCount = 0;
      final func =
          Func2((int a, int b) async {
                callCount++;
                return a + b;
              }).warmUp(
                trigger: WarmUpTrigger.manual,
                keepFresh: const Duration(milliseconds: 100),
              )
              as WarmUpExtension2<int, int, int>;

      unawaited(func.warmUpWith(3, 4));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final initialCount = callCount;

      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(callCount, greaterThan(initialCount)); // Refreshed

      func.dispose();
    });
  });
}
