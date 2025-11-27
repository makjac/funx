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

/// Timeout wrapper (no timeout triggered)
class TimeoutBenchmark extends AsyncBenchmarkBase {
  TimeoutBenchmark() : super('Timeout.NoTimeout');

  late Func<int> withTimeout;

  @override
  Future<void> setup() async {
    final fn = Func<int>(() async => 42);
    withTimeout = fn.timeout(const Duration(seconds: 1));
  }

  @override
  Future<void> run() async {
    await withTimeout();
  }
}

void main() async {
  await BaselineAsyncBenchmark().report();
  await TimeoutBenchmark().report();
}
