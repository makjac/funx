/// Benchmark for retry decorator
// ignore_for_file: avoid_relative_lib_imports, avoid_print

library;

import 'package:funx/funx.dart';

import '../../lib/harness.dart';

/// Baseline: Function without retry
class RetryBaseline extends FunxBenchmarkBase {
  RetryBaseline() : super('Retry.Baseline');

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

/// Retry with no failures (immediate success)
class RetryNoFailures extends FunxBenchmarkBase {
  RetryNoFailures() : super('Retry.NoFailures');

  late Func<int> _retryable;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    _retryable = func.retry(
      maxAttempts: 3,
      backoff: const ConstantBackoff(Duration(milliseconds: 10)),
    );
  }

  @override
  Future<void> run() async {
    await _retryable();
  }
}

/// Retry with constant backoff
class RetryConstantBackoff extends FunxBenchmarkBase {
  RetryConstantBackoff() : super('Retry.ConstantBackoff');

  late Func<int> _retryable;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    _retryable = func.retry(
      maxAttempts: 3,
      backoff: const ConstantBackoff(Duration(milliseconds: 10)),
    );
  }

  @override
  Future<void> run() async {
    await _retryable();
  }
}

/// Retry with linear backoff
class RetryLinearBackoff extends FunxBenchmarkBase {
  RetryLinearBackoff() : super('Retry.LinearBackoff');

  late Func<int> _retryable;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    _retryable = func.retry(
      maxAttempts: 3,
      backoff: const LinearBackoff(
        initialDelay: Duration(milliseconds: 100),
        increment: Duration(milliseconds: 50),
      ),
    );
  }

  @override
  Future<void> run() async {
    await _retryable();
  }
}

/// Retry with exponential backoff
class RetryExponentialBackoff extends FunxBenchmarkBase {
  RetryExponentialBackoff() : super('Retry.ExponentialBackoff');

  late Func<int> _retryable;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    _retryable = func.retry(
      maxAttempts: 3,
      backoff: const ExponentialBackoff(
        initialDelay: Duration(milliseconds: 100),
      ),
    );
  }

  @override
  Future<void> run() async {
    await _retryable();
  }
}

Future<void> main() async {
  print('Retry Benchmark Suite');
  print('=' * 60);

  final benchmarks = [
    RetryBaseline(),
    RetryNoFailures(),
    RetryConstantBackoff(),
    RetryLinearBackoff(),
    RetryExponentialBackoff(),
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
  final baseline = results['Retry.Baseline']!;

  for (final entry in results.entries) {
    if (entry.key == 'Retry.Baseline') continue;
    final diff = entry.value - baseline;
    if (diff < 0) {
      print(
        '${entry.key}: ${diff.toStringAsFixed(3)}μs '
        '(${(-diff / baseline * 100).toStringAsFixed(1)}% faster - good!)',
      );
    } else {
      print(
        '${entry.key}: +${diff.toStringAsFixed(3)}μs '
        '(+${(diff / baseline * 100).toStringAsFixed(1)}% overhead)',
      );
    }
  }
  print('\nNote: These measure overhead when NO retries occur (success path)');
  print('Negative values mean the decorator is FASTER (optimization)');
}
