/// Benchmark for throttle decorator
// ignore_for_file: avoid_relative_lib_imports, prefer_const_constructors

library;

import 'dart:io';

import 'package:funx/funx.dart';

import '../../lib/harness.dart';

/// Baseline: Function without throttle
class ThrottleBaseline extends FunxBenchmarkBase {
  ThrottleBaseline() : super('Throttle.Baseline');

  late Func<int> _func;

  @override
  Future<void> setup() async {
    _func = Func<int>(() async => 42);
  }

  @override
  Future<void> run() async {
    await _func();
  }
}

/// Throttle - first call execution (no throttling active)
class ThrottleFirstCall extends FunxBenchmarkBase {
  ThrottleFirstCall() : super('Throttle.FirstCall');

  late ThrottleExtension<int> _throttled;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    _throttled =
        func.throttle(
              Duration(milliseconds: 100), // Window duration
              mode: ThrottleMode.leading,
            )
            as ThrottleExtension<int>;
  }

  @override
  Future<void> run() async {
    // Reset before each call - measures pure overhead of first call
    _throttled.reset();
    await _throttled(); // First call in window - executes immediately
  }
}

/// Throttle with window expiry check
class ThrottleWindowCheck extends FunxBenchmarkBase {
  ThrottleWindowCheck() : super('Throttle.WindowCheck');

  late ThrottleExtension<int> _throttled;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    _throttled =
        func.throttle(
              Duration(milliseconds: 100),
              mode: ThrottleMode.leading,
            )
            as ThrottleExtension<int>;
  }

  @override
  Future<void> run() async {
    // Call once
    await _throttled();

    // Reset to allow next call (measures reset overhead)
    _throttled.reset();
  }
}

/// Throttle state check overhead (call gets dropped)
class ThrottleDropped extends FunxBenchmarkBase {
  ThrottleDropped() : super('Throttle.DroppedCall');

  late ThrottleExtension<int> _throttled;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    _throttled =
        func.throttle(
              Duration(milliseconds: 100),
              mode: ThrottleMode.leading,
            )
            as ThrottleExtension<int>;
  }

  @override
  Future<void> run() async {
    // Execute once to start throttle window, then measure dropped call overhead
    await _throttled(); // First call executes

    try {
      await _throttled(); // Second call - will throw (throttled)
    } catch (e) {
      // Expected: StateError('Function is throttled')
      // Measures state checking + exception overhead
    }

    // Reset for next iteration
    _throttled.reset();
  }
}

Future<void> main() async {
  stdout
    ..writeln('Throttle Benchmark Suite')
    ..writeln('=' * 60)
    ..writeln('Measuring pure decorator overhead (no artificial delays)')
    ..writeln();

  final benchmarks = [
    ThrottleBaseline(),
    ThrottleFirstCall(),
    ThrottleWindowCheck(),
    ThrottleDropped(),
  ];

  final results = <String, double>{};

  for (final benchmark in benchmarks) {
    await benchmark.warmup();
    await benchmark.exercise();
    final result = benchmark.getResults();
    results[result.name] = result.mean;
    stdout.writeln(result);
  }

  // Analysis
  stdout
    ..writeln('\n${'=' * 60}')
    ..writeln('Performance Analysis:');
  final baseline = results['Throttle.Baseline']!;

  for (final entry in results.entries) {
    if (entry.key == 'Throttle.Baseline') continue;
    final diff = entry.value - baseline;

    if (diff < 0) {
      stdout.writeln(
        '${entry.key}: ${diff.toStringAsFixed(3)}μs '
        '(${(-diff / baseline * 100).toStringAsFixed(1)}% faster)',
      );
    } else {
      stdout.writeln(
        '${entry.key}: +${diff.toStringAsFixed(3)}μs '
        '(+${(diff / baseline * 100).toStringAsFixed(1)}% overhead)',
      );
    }
  }

  stdout
    ..writeln('\nNote: Measurements are PURE decorator overhead.')
    ..writeln(
      'No artificial delays - throttle windows are avoided via reset().',
    )
    ..writeln(
      'Pure overhead (state check + timestamp comparison): measured directly.',
    );
}
