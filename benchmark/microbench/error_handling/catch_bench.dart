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

/// Catch with no exception
class CatchNoExceptionBenchmark extends AsyncBenchmarkBase {
  CatchNoExceptionBenchmark() : super('Catch.NoException');

  late Func<int> withCatch;

  @override
  Future<void> setup() async {
    final fn = Func<int>(() async => 42);
    withCatch = fn.catchError(
      handlers: {Exception: (e) async => 0},
    );
  }

  @override
  Future<void> run() async {
    await withCatch();
  }
}

void main() async {
  await BaselineAsyncBenchmark().report();
  await CatchNoExceptionBenchmark().report();
}
