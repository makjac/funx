/// Benchmark for batch decorator
// ignore_for_file: avoid_relative_lib_imports, avoid_print

library;

import 'dart:async';

import 'package:funx/funx.dart';

import '../../lib/harness.dart';

/// Baseline: Function without batching
class BatchBaseline extends FunxBenchmarkBase {
  BatchBaseline() : super('Batch.Baseline');

  late Func1<int, int> _func;

  @override
  Future<void> setup() async {
    _func = Func1((n) async => n * 2);
  }

  @override
  Future<void> run() async {
    await _func(42);
  }
}

/// Batch with immediate flush (size = 1)
class BatchImmediateFlush extends FunxBenchmarkBase {
  BatchImmediateFlush() : super('Batch.ImmediateFlush');

  late Func1<int, int> _batched;

  @override
  Future<void> setup() async {
    final func = Func1<int, int>((n) async => n * 2);
    _batched = func.batch(
      executor: Func1((List<int> items) async {
        // Process batch immediately - return void
      }),
      maxSize: 1, // Immediate flush on every call
      maxWait: const Duration(seconds: 10), // Long wait (won't be triggered)
    );
  }

  @override
  Future<void> run() async {
    await _batched(42); // Executes immediately
  }
}

/// Batch state management overhead (fire and forget)
class BatchStateOverhead extends FunxBenchmarkBase {
  BatchStateOverhead() : super('Batch.StateOverhead');

  late Func1<int, void> _batched;
  int _counter = 0;

  @override
  int get measurementIterations => 5000;

  @override
  Future<void> setup() async {
    final func = Func1<int, void>((n) async {
      // No-op function
    });
    _batched = func.batch(
      executor: Func1((List<int> items) async {
        // Process batch
      }),
      maxSize: 100, // Batch up to 100 items
      maxWait: const Duration(milliseconds: 10),
    );
    _counter = 0;
  }

  @override
  Future<void> run() async {
    // Fire and forget - just measure overhead of adding to batch
    unawaited(_batched(_counter++));

    // Periodically flush by waiting
    if (_counter % 100 == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
  }
}

/// Batch buffer management (small batches)
class BatchSmallBatches extends FunxBenchmarkBase {
  BatchSmallBatches() : super('Batch.SmallBatches');

  late Func1<int, int> _batched;

  @override
  Future<void> setup() async {
    final func = Func1<int, int>((n) async => n * 2);
    _batched = func.batch(
      executor: Func1((List<int> items) async {
        // Process batch - return void
      }),
      maxSize: 5, // Small batches
      maxWait: const Duration(seconds: 10), // Won't trigger
    );
  }

  @override
  Future<void> run() async {
    // This will batch up 5 calls then execute
    await _batched(42);
  }
}

Future<void> main() async {
  print('Batch Benchmark Suite');
  print('=' * 60);
  print('Measuring pure decorator overhead (no wait times)');
  print('');

  final benchmarks = [
    BatchBaseline(),
    BatchImmediateFlush(),
    BatchStateOverhead(),
    BatchSmallBatches(),
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
  print('Performance Analysis:');
  final baseline = results['Batch.Baseline']!;

  for (final entry in results.entries) {
    if (entry.key == 'Batch.Baseline') continue;
    final diff = entry.value - baseline;

    if (diff < 0) {
      print(
        '${entry.key}: ${diff.toStringAsFixed(3)}μs '
        '(${(-diff / baseline * 100).toStringAsFixed(1)}% faster)',
      );
    } else {
      print(
        '${entry.key}: +${diff.toStringAsFixed(3)}μs '
        '(+${(diff / baseline * 100).toStringAsFixed(1)}% overhead)',
      );
    }
  }

  print('\nNote: All measurements are pure decorator overhead.');
  print('- ImmediateFlush: overhead of batch setup + immediate execution');
  print('- StateOverhead: overhead of adding item to batch buffer');
  print('- SmallBatches: overhead averaged over small batch size');
}
