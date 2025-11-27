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

/// Guard with passing condition
class GuardPassBenchmark extends AsyncBenchmarkBase {
  GuardPassBenchmark() : super('Guard.Pass');

  late Func1<int, int> guarded;

  @override
  Future<void> setup() async {
    final fn = Func1<int, int>((n) async => n * 2);
    guarded = fn.guard(preCondition: (n) => n > 0);
  }

  @override
  Future<void> run() async {
    await guarded(42);
  }
}

void main() async {
  await BaselineAsyncBenchmark().report();
  await GuardPassBenchmark().report();
}
