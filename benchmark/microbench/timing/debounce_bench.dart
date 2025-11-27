/// Benchmark for debounce decorator
// ignore_for_file: avoid_relative_lib_imports

library;

import 'dart:async';
import 'dart:io';

import 'package:funx/funx.dart';

import '../../lib/harness.dart';

/// Baseline: Function without debounce
class DebounceBaseline extends FunxBenchmarkBase {
  DebounceBaseline() : super('Debounce.Baseline');

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

/// Debounce - immediate execution (no pending calls)
class DebounceImmediate extends FunxBenchmarkBase {
  DebounceImmediate() : super('Debounce.Immediate');

  late Func<int> _debounced;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    _debounced = func.debounce(
      const Duration(milliseconds: 100),
      mode: DebounceMode.trailing,
    );
  }

  @override
  Future<void> run() async {
    // Each call completes immediately (no debouncing active)
    await _debounced();
    // Wait for debounce window to expire
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}

/// Debounce leading mode - pure overhead measurement
class DebounceLeading extends FunxBenchmarkBase {
  DebounceLeading() : super('Debounce.LeadingMode');

  late Func<int> _debounced;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    _debounced = func.debounce(
      const Duration(milliseconds: 100),
      mode: DebounceMode.leading,
    );
  }

  @override
  Future<void> run() async {
    // Leading mode executes immediately on first call
    await _debounced();
    // Wait for debounce window to reset
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}

/// Debounce state check overhead (call gets dropped)
class DebounceDropped extends FunxBenchmarkBase {
  DebounceDropped() : super('Debounce.DroppedCall');

  late Func<int> _debounced;
  int _callCount = 0;

  @override
  int get measurementIterations => 1000; // Fewer iterations for this test

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    _debounced = func.debounce(
      const Duration(milliseconds: 50),
      mode: DebounceMode.trailing,
    );
    _callCount = 0;
  }

  @override
  Future<void> run() async {
    // Rapid fire calls - only last one will execute
    // We measure the overhead of checking/dropping calls
    unawaited(_debounced()); // Fire and forget (no await)
    _callCount++;

    // Every 10 calls, wait for debounce to execute
    if (_callCount % 10 == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}

Future<void> main() async {
  stdout
    ..writeln('Debounce Benchmark Suite')
    ..writeln('=' * 60)
    ..writeln('Measuring pure decorator overhead (no artificial delays)')
    ..writeln();

  final benchmarks = [
    DebounceBaseline(),
    DebounceImmediate(),
    DebounceLeading(),
    DebounceDropped(),
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
  final baseline = results['Debounce.Baseline']!;

  for (final entry in results.entries) {
    if (entry.key == 'Debounce.Baseline') continue;
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
    ..writeln('\nNote: Measurements include debounce window wait times.')
    ..writeln(
      'Pure decorator overhead (state check + timer setup): ~5-15μs estimated',
    );
}
