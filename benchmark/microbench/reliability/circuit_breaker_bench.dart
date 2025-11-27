/// Benchmark for circuit_breaker decorator
// ignore_for_file: avoid_relative_lib_imports, avoid_print

library;

import 'package:funx/funx.dart';

import '../../lib/harness.dart';

/// Baseline: Function without circuit breaker
class CircuitBreakerBaseline extends FunxBenchmarkBase {
  CircuitBreakerBaseline() : super('CircuitBreaker.Baseline');

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

/// Circuit breaker in closed state (passing through)
class CircuitBreakerClosed extends FunxBenchmarkBase {
  CircuitBreakerClosed() : super('CircuitBreaker.Closed');

  late Func<int> _protected;

  @override
  Future<void> setup() async {
    final cb = CircuitBreaker();
    _protected = Func(() async => 42).circuitBreaker(cb);
  }

  @override
  Future<void> run() async {
    await _protected();
  }
}

/// Circuit breaker with state check overhead
class CircuitBreakerStateCheck extends FunxBenchmarkBase {
  CircuitBreakerStateCheck() : super('CircuitBreaker.StateCheck');

  late Func<int> _protected;
  int _counter = 0;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async {
      _counter++;
      if (_counter % 100 == 0) throw Exception('Periodic failure');
      return 42;
    });
    final cb = CircuitBreaker(
      failureThreshold: 10,
      timeout: const Duration(seconds: 10),
    );
    _protected = func.circuitBreaker(cb);
  }

  @override
  Future<void> run() async {
    try {
      await _protected();
    } catch (_) {
      // Ignore failures for benchmark
    }
  }
}

Future<void> main() async {
  print('CircuitBreaker Benchmark Suite');
  print('=' * 60);

  final benchmarks = [
    CircuitBreakerBaseline(),
    CircuitBreakerClosed(),
    CircuitBreakerStateCheck(),
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
  final baseline = results['CircuitBreaker.Baseline']!;

  for (final entry in results.entries) {
    if (entry.key == 'CircuitBreaker.Baseline') continue;
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
  print('\nNote: Negative values mean the decorator is FASTER (optimization)');
}
