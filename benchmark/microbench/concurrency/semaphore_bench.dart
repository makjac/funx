/// Benchmark for semaphore decorator
// ignore_for_file: avoid_relative_lib_imports, avoid_print

library;

import 'package:funx/funx.dart';

import '../../lib/harness.dart';

/// Baseline: Function without semaphore
class SemaphoreBaseline extends FunxBenchmarkBase {
  SemaphoreBaseline() : super('Semaphore.Baseline');

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

/// Semaphore with no contention (max = 10)
class SemaphoreNoContention extends FunxBenchmarkBase {
  SemaphoreNoContention() : super('Semaphore.NoContention');

  late Func<int> _limited;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    _limited = func.semaphore(maxConcurrent: 10);
  }

  @override
  Future<void> run() async {
    await _limited();
  }
}

Future<void> main() async {
  print('Semaphore Benchmark Suite');
  print('=' * 60);

  final benchmarks = [
    SemaphoreBaseline(),
    SemaphoreNoContention(),
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
  final baseline = results['Semaphore.Baseline']!;

  for (final entry in results.entries) {
    if (entry.key == 'Semaphore.Baseline') continue;
    final overhead = entry.value - baseline;
    final percentage = (overhead / baseline) * 100;
    print(
      '${entry.key}: +${overhead.toStringAsFixed(3)}μs '
      '(+${percentage.toStringAsFixed(1)}%)',
    );
  }
}
