/// Benchmark for throttle decorator
///
/// Note: Throttle limits call frequency, so we measure realistic throughput
// ignore_for_file: avoid_print, lines_longer_than_80_chars

library;

import 'dart:async';

import 'package:funx/funx.dart';

Future<void> main() async {
  print('Throttle Benchmark Suite');
  print('=' * 60);

  // Baseline: raw function throughput
  print('\nBaseline: Raw function throughput');
  var callCount = 0;
  final baseline = Func<int>(() async {
    callCount++;
    return 42;
  });

  final baselineStart = DateTime.now();
  for (var i = 0; i < 100; i++) {
    await baseline();
  }
  final baselineTime = DateTime.now().difference(baselineStart);
  print('  100 calls: ${baselineTime.inMicroseconds} μs');
  print('  Per call: ${baselineTime.inMicroseconds / 100} μs');
  print('  Actual executions: $callCount');

  // Throttle trailing: limits call rate
  print('\nThrottle Trailing: Rate limiting scenario');
  callCount = 0;
  final throttleTrailing =
      Func<int>(() async {
        callCount++;
        return 42;
      }).throttle(
        const Duration(milliseconds: 10),
        mode: ThrottleMode.trailing,
      );

  final trailingStart = DateTime.now();
  // Try to call 100 times rapidly
  for (var i = 0; i < 100; i++) {
    unawaited(throttleTrailing()); // Don't await
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  await Future<void>.delayed(const Duration(milliseconds: 20)); // Wait for last
  final trailingTime = DateTime.now().difference(trailingStart);
  print('  100 scheduled calls: ${trailingTime.inMicroseconds} μs');
  print('  Actual executions: $callCount');
  print('  Throttled: ${100 - callCount} calls');

  // Throttle leading: first call executes, others throttled
  print('\nThrottle Leading: Burst scenario');
  callCount = 0;
  final throttleLeading =
      Func<int>(() async {
        callCount++;
        return 42;
      }).throttle(
        const Duration(milliseconds: 20),
        mode: ThrottleMode.leading,
      );

  final leadingStart = DateTime.now();
  for (var i = 0; i < 10; i++) {
    await throttleLeading(); // Execute
    await Future<void>.delayed(
      const Duration(milliseconds: 25),
    ); // Wait for window
  }
  final leadingTime = DateTime.now().difference(leadingStart);
  print('  10 calls: ${leadingTime.inMicroseconds} μs');
  print('  Per call: ${leadingTime.inMicroseconds / 10} μs');
  print('  Actual executions: $callCount');

  // Overhead analysis
  print('\n${'=' * 60}');
  print('Overhead Analysis:');
  final baselinePerCall = baselineTime.inMicroseconds / 100;
  final leadingOverhead = (leadingTime.inMicroseconds / 10) - baselinePerCall;
  print('  Baseline per call: ${baselinePerCall.toStringAsFixed(2)} μs');
  print('  Leading overhead: ${leadingOverhead.toStringAsFixed(2)} μs');
  final throttleCount = callCount;
  print(
    '  Throttle effectiveness: ${((100 - throttleCount) / 100 * 100).toStringAsFixed(1)}% reduction',
  );
  print('=' * 60);
}
