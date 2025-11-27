/// Custom benchmark harness with advanced metrics tracking
// ignore_for_file: avoid_print, lines_longer_than_80_chars

library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:benchmark_harness/benchmark_harness.dart';

/// Extended benchmark base with percentile tracking and progress reporting
abstract class FunxBenchmarkBase extends AsyncBenchmarkBase {
  FunxBenchmarkBase(super.name, {this.showProgress = true});

  final List<double> _measurements = [];
  int _iterations = 0;

  /// Whether to show progress bar during execution
  final bool showProgress;

  /// Number of warmup iterations (to warm up JIT compiler)
  /// Override to reduce for faster benchmarking
  int get warmupIterations => _quickMode ? 100 : 1000;

  /// Number of measurement iterations
  /// Override to reduce for faster benchmarking
  int get measurementIterations => _quickMode ? 1000 : 10000;

  /// Quick mode (fewer iterations, faster results, less accurate)
  static bool _quickMode = false;

  /// Enable quick mode for all benchmarks (100 warmup, 1000 iterations)
  static void enableQuickMode() => _quickMode = true;

  /// Disable quick mode (1000 warmup, 10000 iterations)
  static void enableFullMode() => _quickMode = false;

  /// Setup benchmark (can be sync or async)
  @override
  Future<void> setup() async {}

  @override
  Future<void> warmup() async {
    await setup();

    // First warmup pass - let JIT compiler optimize
    final warmupStart = DateTime.now();
    for (var i = 0; i < warmupIterations; i++) {
      await run();

      // Show progress every 100 iterations
      if (showProgress && (i + 1) % 100 == 0) {
        _updateProgress('Warmup', i + 1, warmupIterations);
      }
    }

    if (showProgress) {
      final elapsed = DateTime.now().difference(warmupStart);
      // Clear progress line and print completion message
      print(
        '\r  ✓ Warmup complete (${elapsed.inMilliseconds}ms, $warmupIterations iterations)${' ' * 20}',
      );
    }

    // Force GC to clear any warmup artifacts
    // Note: Dart doesn't expose GC directly, but we can hint at it
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<void> exercise() async {
    _measurements.clear();
    _iterations = 0;

    final measureStart = DateTime.now();
    final updateInterval = measurementIterations >= 10000 ? 500 : 100;

    for (var i = 0; i < measurementIterations; i++) {
      final stopwatch = Stopwatch()..start();
      await run();
      stopwatch.stop();
      _measurements.add(stopwatch.elapsedMicroseconds.toDouble());
      _iterations++;

      // Show progress periodically
      if (showProgress && (i + 1) % updateInterval == 0) {
        _updateProgress('Measuring', i + 1, measurementIterations);
      }
    }

    if (showProgress) {
      final elapsed = DateTime.now().difference(measureStart);
      final rate = (measurementIterations / elapsed.inMilliseconds * 1000)
          .round();
      // Clear progress line and print completion message
      print(
        '\r  ✓ Measurement complete (${elapsed.inMilliseconds}ms, $measurementIterations iterations, ~$rate iter/sec)${' ' * 10}',
      );
    }
  }

  /// Update progress bar
  void _updateProgress(String phase, int current, int total) {
    if (!showProgress) return;

    final percent = (current / total * 100).round();
    const barWidth = 30;
    final filled = (barWidth * current / total).round();
    final bar = '█' * filled + '░' * (barWidth - filled);

    // Use stderr for progress to avoid stdout conflicts
    stderr.write('\r  $phase: [$bar] $percent% ($current/$total)');
  }

  /// Get benchmark results with detailed statistics
  BenchmarkResult getResults() {
    if (_measurements.isEmpty) {
      throw StateError('No measurements taken. Call exercise() first.');
    }

    final sorted = List<double>.from(_measurements)..sort();
    final sum = sorted.reduce((a, b) => a + b);
    final mean = sum / sorted.length;

    // Calculate standard deviation
    final variance =
        sorted.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
        sorted.length;
    final stdDev = math.sqrt(variance);

    // Calculate 95% confidence interval (z = 1.96 for 95% CI)
    final stderr = stdDev / math.sqrt(sorted.length);
    final ci95 = 1.96 * stderr;

    return BenchmarkResult(
      name: name,
      iterations: _iterations,
      mean: mean,
      min: sorted.first,
      max: sorted.last,
      p50: _percentile(sorted, 0.50),
      p90: _percentile(sorted, 0.90),
      p95: _percentile(sorted, 0.95),
      p99: _percentile(sorted, 0.99),
      stdDev: stdDev,
      ci95: ci95,
      measurements: List.unmodifiable(_measurements),
    );
  }

  double _percentile(List<double> sorted, double percentile) {
    final index = (sorted.length * percentile).ceil() - 1;
    return sorted[math.max(0, math.min(index, sorted.length - 1))];
  }

  /// Print detailed results
  void reportDetailed() {
    final results = getResults();
    print(results.toDetailedString());
  }

  @override
  Future<void> report() async {
    final results = getResults();
    print(results);
  }
}

/// Benchmark result with detailed statistics
class BenchmarkResult {
  const BenchmarkResult({
    required this.name,
    required this.iterations,
    required this.mean,
    required this.min,
    required this.max,
    required this.p50,
    required this.p90,
    required this.p95,
    required this.p99,
    required this.stdDev,
    required this.ci95,
    required this.measurements,
  });

  final String name;
  final int iterations;
  final double mean;
  final double min;
  final double max;
  final double p50;
  final double p90;
  final double p95;
  final double p99;
  final double stdDev;
  final double ci95; // 95% confidence interval
  final List<double> measurements;

  /// Calculate overhead compared to baseline
  double overheadMicroseconds(BenchmarkResult baseline) {
    return mean - baseline.mean;
  }

  /// Calculate overhead percentage compared to baseline
  double overheadPercentage(BenchmarkResult baseline) {
    if (baseline.mean == 0) return 0;
    return ((mean - baseline.mean) / baseline.mean) * 100;
  }

  @override
  String toString() {
    return '$name: ${mean.toStringAsFixed(3)}μs (±${ci95.toStringAsFixed(2)}μs CI95)';
  }

  String toDetailedString() {
    final buffer = StringBuffer()
      ..writeln('Benchmark: $name')
      ..writeln('Iterations: $iterations')
      ..writeln('Mean: ${mean.toStringAsFixed(3)}μs')
      ..writeln('CI 95%: ±${ci95.toStringAsFixed(3)}μs')
      ..writeln('Std Dev: ${stdDev.toStringAsFixed(3)}μs')
      ..writeln('Min: ${min.toStringAsFixed(3)}μs')
      ..writeln('Max: ${max.toStringAsFixed(3)}μs')
      ..writeln('p50: ${p50.toStringAsFixed(3)}μs')
      ..writeln('p90: ${p90.toStringAsFixed(3)}μs')
      ..writeln('p95: ${p95.toStringAsFixed(3)}μs')
      ..writeln('p99: ${p99.toStringAsFixed(3)}μs');
    return buffer.toString();
  }

  /// Convert to JSON-serializable map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'iterations': iterations,
      'mean': mean,
      'ci95': ci95,
      'stdDev': stdDev,
      'min': min,
      'max': max,
      'p50': p50,
      'p90': p90,
      'p95': p95,
      'p99': p99,
    };
  }
}

/// Run multiple benchmarks and collect results
class BenchmarkSuite {
  BenchmarkSuite(this.name, {this.showProgress = true});

  final String name;
  final bool showProgress;
  final List<FunxBenchmarkBase> _benchmarks = [];
  final List<BenchmarkResult> _results = [];

  /// Add a benchmark to the suite
  void add(FunxBenchmarkBase benchmark) {
    _benchmarks.add(benchmark);
  }

  /// Run all benchmarks in the suite
  Future<List<BenchmarkResult>> run() async {
    _results.clear();

    print('Running benchmark suite: $name');
    print('=' * 60);

    if (FunxBenchmarkBase._quickMode) {
      print('⚡ Quick mode: 100 warmup + 1000 iterations per benchmark');
    } else {
      print('🎯 Full mode: 1000 warmup + 10000 iterations per benchmark');
    }

    print('Total benchmarks: ${_benchmarks.length}');
    print('');

    final suiteStart = DateTime.now();

    for (var i = 0; i < _benchmarks.length; i++) {
      final benchmark = _benchmarks[i];
      print('[${i + 1}/${_benchmarks.length}] ${benchmark.name}');

      final benchStart = DateTime.now();
      await benchmark.warmup();
      await benchmark.exercise();
      final result = benchmark.getResults();
      _results.add(result);

      final benchElapsed = DateTime.now().difference(benchStart);
      print('  Result: $result');
      print('  Time: ${benchElapsed.inSeconds}s\n');
    }

    final totalElapsed = DateTime.now().difference(suiteStart);
    print('=' * 60);
    print('✓ Suite complete: $name');
    print(
      '  Total time: ${totalElapsed.inMinutes}m ${totalElapsed.inSeconds % 60}s',
    );
    print('  Benchmarks: ${_benchmarks.length}');
    print('');

    return List.unmodifiable(_results);
  }

  /// Get results from last run
  List<BenchmarkResult> get results => List.unmodifiable(_results);
}
