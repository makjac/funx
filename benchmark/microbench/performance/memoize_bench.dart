/// Benchmark for memoize decorator
// ignore_for_file: avoid_relative_lib_imports, avoid_print, lines_longer_than_80_chars

library;

import 'package:funx/funx.dart';

import '../../lib/harness.dart';

/// Baseline: Function without memoization
class MemoizeBaseline extends FunxBenchmarkBase {
  MemoizeBaseline() : super('Memoize.Baseline');

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

/// Memoize with cache hit
class MemoizeCacheHit extends FunxBenchmarkBase {
  MemoizeCacheHit() : super('Memoize.CacheHit');

  late Func1<int, int> _memoized;

  @override
  Future<void> setup() async {
    final func = Func1<int, int>((n) async => n * 2);
    _memoized = func.memoize(maxSize: 1000);
    // Prime the cache
    await _memoized(42);
  }

  @override
  Future<void> run() async {
    await _memoized(42);
  }
}

/// Memoize with cache miss
class MemoizeCacheMiss extends FunxBenchmarkBase {
  MemoizeCacheMiss() : super('Memoize.CacheMiss');

  late Func1<int, int> _memoized;
  int _counter = 0;

  @override
  Future<void> setup() async {
    final func = Func1<int, int>((n) async => n * 2);
    _memoized = func.memoize(maxSize: 1000);
    _counter = 0;
  }

  @override
  Future<void> run() async {
    await _memoized(_counter++);
  }
}

/// Memoize with LRU eviction
class MemoizeLRUEviction extends FunxBenchmarkBase {
  MemoizeLRUEviction() : super('Memoize.LRU_Eviction');

  late Func1<int, int> _memoized;
  int _counter = 0;

  @override
  Future<void> setup() async {
    final func = Func1<int, int>((n) async => n * 2);
    _memoized = func.memoize(maxSize: 100, evictionPolicy: EvictionPolicy.lru);
    // Fill cache
    for (var i = 0; i < 100; i++) {
      await _memoized(i);
    }
    _counter = 100;
  }

  @override
  Future<void> run() async {
    await _memoized(_counter++);
  }
}

/// Memoize with LFU eviction
class MemoizeLFUEviction extends FunxBenchmarkBase {
  MemoizeLFUEviction() : super('Memoize.LFU_Eviction');

  late Func1<int, int> _memoized;
  int _counter = 0;

  @override
  Future<void> setup() async {
    final func = Func1<int, int>((n) async => n * 2);
    _memoized = func.memoize(maxSize: 100, evictionPolicy: EvictionPolicy.lfu);
    // Fill cache
    for (var i = 0; i < 100; i++) {
      await _memoized(i);
    }
    _counter = 100;
  }

  @override
  Future<void> run() async {
    await _memoized(_counter++);
  }
}

/// Memoize with FIFO eviction
class MemoizeFIFOEviction extends FunxBenchmarkBase {
  MemoizeFIFOEviction() : super('Memoize.FIFO_Eviction');

  late Func1<int, int> _memoized;
  int _counter = 0;

  @override
  Future<void> setup() async {
    final func = Func1<int, int>((n) async => n * 2);
    _memoized = func.memoize(maxSize: 100, evictionPolicy: EvictionPolicy.fifo);
    // Fill cache
    for (var i = 0; i < 100; i++) {
      await _memoized(i);
    }
    _counter = 100;
  }

  @override
  Future<void> run() async {
    await _memoized(_counter++);
  }
}

Future<void> main(List<String> args) async {
  // Check for quick mode flag
  if (args.contains('--quick') || args.contains('-q')) {
    FunxBenchmarkBase.enableQuickMode();
    print('⚡ Quick mode enabled (100 warmup + 1000 iterations)\n');
  }

  print('Memoize Benchmark Suite');
  print('=' * 60);

  final benchmarks = [
    MemoizeBaseline(),
    MemoizeCacheHit(),
    MemoizeCacheMiss(),
    MemoizeLRUEviction(),
    MemoizeLFUEviction(),
    MemoizeFIFOEviction(),
  ];

  final results = <String, double>{};

  for (final benchmark in benchmarks) {
    print('Running ${benchmark.name}...');
    await benchmark.warmup();
    await benchmark.exercise();
    final result = benchmark.getResults();
    results[result.name] = result.mean;
    print('  $result\n');
  }

  // Calculate overhead
  print('\n${'=' * 60}');
  print('Performance Analysis:');
  final baseline = results['Memoize.Baseline']!;

  final cacheHit = results['Memoize.CacheHit']!;
  final hitBenefit = baseline - cacheHit;
  print(
    'Cache Hit: ${cacheHit.toStringAsFixed(3)}μs '
    '(${hitBenefit.toStringAsFixed(3)}μs faster, ${(hitBenefit / baseline * 100).toStringAsFixed(1)}% speedup)',
  );

  final cacheMiss = results['Memoize.CacheMiss']!;
  final missOverhead = cacheMiss - baseline;
  print(
    'Cache Miss: ${cacheMiss.toStringAsFixed(3)}μs '
    '(+${missOverhead.toStringAsFixed(3)}μs overhead, +${(missOverhead / baseline * 100).toStringAsFixed(1)}%)',
  );

  print('\nEviction Policy Overhead:');
  for (final entry in results.entries) {
    if (entry.key.contains('Eviction') || entry.key.contains('TTL')) {
      final overhead = entry.value - baseline;
      print(
        '${entry.key}: +${overhead.toStringAsFixed(3)}μs '
        '(+${(overhead / baseline * 100).toStringAsFixed(1)}%)',
      );
    }
  }
}
