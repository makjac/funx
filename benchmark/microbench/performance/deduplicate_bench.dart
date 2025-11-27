import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:funx/funx.dart';

/// Baseline: raw async function call with parameter
class BaselineAsyncBenchmark extends AsyncBenchmarkBase {
  BaselineAsyncBenchmark() : super('Baseline.AsyncCall');

  late Func1<int, int> baseline;

  @override
  Future<void> setup() async {
    baseline = Func1<int, int>((n) async => n * 2);
  }

  @override
  Future<void> run() async {
    await baseline(42);
  }
}

/// Deduplicate with cache hit
class DeduplicateCacheHitBenchmark extends AsyncBenchmarkBase {
  DeduplicateCacheHitBenchmark() : super('Deduplicate.CacheHit');

  late Func1<int, int> deduplicated;

  @override
  Future<void> setup() async {
    final fn = Func1<int, int>((n) async => n * 2);
    deduplicated = fn.deduplicate(window: const Duration(milliseconds: 100));
  }

  @override
  Future<void> run() async {
    await deduplicated(42);
  }
}

void main() async {
  await BaselineAsyncBenchmark().report();
  await DeduplicateCacheHitBenchmark().report();
}
