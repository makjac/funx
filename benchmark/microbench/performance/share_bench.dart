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

/// Share result across multiple callers
class ShareBenchmark extends AsyncBenchmarkBase {
  ShareBenchmark() : super('Share.SharedResult');

  late Func<int> shared;

  @override
  Future<void> setup() async {
    final fn = Func<int>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return 42;
    });
    shared = fn.share();
  }

  @override
  Future<void> run() async {
    await shared();
  }
}

void main() async {
  await BaselineAsyncBenchmark().report();
  await ShareBenchmark().report();
}
