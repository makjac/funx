import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:funx/funx.dart';

/// Baseline: raw async function call
class BaselineAsyncBenchmark extends AsyncBenchmarkBase {
  BaselineAsyncBenchmark() : super('Baseline.AsyncCall');

  late Func<int> baseline;

  @override
  Future<void> setup() async {
    baseline = Func<int>(() async => 42);
  }

  @override
  Future<void> run() async {
    await baseline();
  }
}

/// Fallback with successful primary
class FallbackSuccessBenchmark extends AsyncBenchmarkBase {
  FallbackSuccessBenchmark() : super('Fallback.Success');

  late Func<int> withFallback;

  @override
  Future<void> setup() async {
    final fn = Func<int>(() async => 42);
    withFallback = fn.fallback(fallbackValue: 0);
  }

  @override
  Future<void> run() async {
    await withFallback();
  }
}

void main() async {
  await BaselineAsyncBenchmark().report();
  await FallbackSuccessBenchmark().report();
}
