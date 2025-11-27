/// Benchmark for rate_limit decorator
// ignore_for_file: avoid_relative_lib_imports, avoid_print

library;

import 'package:funx/funx.dart';

import '../../lib/harness.dart';

/// Baseline: Function without rate limiting
class RateLimitBaseline extends FunxBenchmarkBase {
  RateLimitBaseline() : super('RateLimit.Baseline');

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

/// Rate limit with token bucket (well under limit - pure overhead)
class RateLimitTokenBucketUnderLimit extends FunxBenchmarkBase {
  RateLimitTokenBucketUnderLimit() : super('RateLimit.TokenBucket');

  late Func<int> _rateLimited;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    // Very high limit to ensure we never wait
    _rateLimited = func.rateLimit(
      maxCalls: 100000,
      window: const Duration(seconds: 1),
      strategy: RateLimitStrategy.tokenBucket,
    );
  }

  @override
  Future<void> run() async {
    await _rateLimited();
  }
}

/// Rate limit with leaky bucket (well under limit - pure overhead)
class RateLimitLeakyBucketUnderLimit extends FunxBenchmarkBase {
  RateLimitLeakyBucketUnderLimit() : super('RateLimit.LeakyBucket');

  late Func<int> _rateLimited;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    // Very high limit to ensure we never wait
    _rateLimited = func.rateLimit(
      maxCalls: 100000,
      window: const Duration(seconds: 1),
      strategy: RateLimitStrategy.leakyBucket,
    );
  }

  @override
  Future<void> run() async {
    await _rateLimited();
  }
}

/// Rate limit with fixed window (well under limit - pure overhead)
class RateLimitFixedWindowUnderLimit extends FunxBenchmarkBase {
  RateLimitFixedWindowUnderLimit() : super('RateLimit.FixedWindow');

  late Func<int> _rateLimited;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    // Very high limit to ensure we never wait
    _rateLimited = func.rateLimit(
      maxCalls: 100000,
      window: const Duration(seconds: 1),
      strategy: RateLimitStrategy.fixedWindow,
    );
  }

  @override
  Future<void> run() async {
    await _rateLimited();
  }
}

/// Rate limit with sliding window (well under limit - pure overhead)
class RateLimitSlidingWindowUnderLimit extends FunxBenchmarkBase {
  RateLimitSlidingWindowUnderLimit() : super('RateLimit.SlidingWindow');

  late Func<int> _rateLimited;

  @override
  Future<void> setup() async {
    final func = Func<int>(() async => 42);
    // Very high limit to ensure we never wait
    _rateLimited = func.rateLimit(
      maxCalls: 100000,
      window: const Duration(seconds: 1),
      strategy: RateLimitStrategy.slidingWindow,
    );
  }

  @override
  Future<void> run() async {
    await _rateLimited();
  }
}

Future<void> main() async {
  print('RateLimit Benchmark Suite');
  print('=' * 60);
  print('Measuring pure decorator overhead (well under limit)');
  print('');

  final benchmarks = [
    RateLimitBaseline(),
    RateLimitTokenBucketUnderLimit(),
    RateLimitLeakyBucketUnderLimit(),
    RateLimitFixedWindowUnderLimit(),
    RateLimitSlidingWindowUnderLimit(),
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
  final baseline = results['RateLimit.Baseline']!;

  for (final entry in results.entries) {
    if (entry.key == 'RateLimit.Baseline') continue;
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

  print('\nNote: All measurements are under rate limit (no waiting).');
  print('This represents pure decorator overhead for token/window checks.');
}
