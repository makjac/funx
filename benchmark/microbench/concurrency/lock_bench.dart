/// Benchmark for lock decorator
// ignore_for_file: avoid_print, avoid_relative_lib_imports

library;

import 'package:funx/funx.dart';

import '../../lib/harness.dart';

/// Baseline: Function without lock
class LockBaseline extends FunxBenchmarkBase {
  LockBaseline() : super('Lock.Baseline');

  late Func<int> _func;

  @override
  Future<void> setup() async {
    _func = Func(() async => 42);
  }

  @override
  Future<void> run() async {
    await _func();
  }
}

/// Lock with no contention
class LockNoContention extends FunxBenchmarkBase {
  LockNoContention() : super('Lock.NoContention');

  late Func<int> _locked;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    _locked = func.lock();
  }

  @override
  Future<void> run() async {
    await _locked();
  }
}

Future<void> main() async {
  print('Lock Benchmark Suite');
  print('=' * 60);

  final benchmarks = [
    LockBaseline(),
    LockNoContention(),
  ];

  final results = <String, double>{};

  for (final benchmark in benchmarks) {
    await benchmark.warmup();
    await benchmark.exercise();
    final result = benchmark.getResults();
    results[result.name] = result.mean;
    print(result);
  }

  // Calculate overhead
  print('\n${'=' * 60}');
  print('Overhead Analysis:');
  final baseline = results['Lock.Baseline']!;

  for (final entry in results.entries) {
    if (entry.key == 'Lock.Baseline') continue;
    final overhead = entry.value - baseline;
    final percentage = (overhead / baseline) * 100;
    print(
      '${entry.key}: +${overhead.toStringAsFixed(3)}μs '
      '(+${percentage.toStringAsFixed(1)}%)',
    );
  }
}
