/// Flow benchmark: Search autocomplete scenario
// ignore_for_file: avoid_print, avoid_relative_lib_imports, unawaited_futures, lines_longer_than_80_chars

library;

import 'package:funx/funx.dart';

import '../lib/fixtures.dart';
import '../lib/metrics.dart';

Future<void> main() async {
  print('Flow Benchmark: Search Autocomplete');
  print('=' * 60);

  await benchmarkRapidInput();
  await benchmarkBurstInput();
}

/// Benchmark rapid user input with debounce
Future<void> benchmarkRapidInput() async {
  print('\n## Rapid Input (1000 calls, debounced to ~14 executions)\n');

  final searchApi = Func1<String, List<String>>((query) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return ['result1', 'result2', 'result3'];
  });

  final debounced = searchApi.debounce(const Duration(milliseconds: 300));

  final meter = ThroughputMeter('Search')..start();

  var executionCount = 0;

  // Simulate 1000 rapid inputs over 5 seconds
  final inputs = generateStrings(1000);
  for (var i = 0; i < inputs.length; i++) {
    debounced(inputs[i])
        .then((_) {
          executionCount++;
        })
        .catchError((_) {
          // Debounced calls may be canceled
        });
    meter.record();

    if (i % 100 == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  // Wait for debounce to settle
  await Future<void>.delayed(const Duration(seconds: 1));
  meter.stop();

  print('Total inputs: ${meter.totalOperations}');
  print('Actual API calls: $executionCount');
  print(
    'Reduction: ${((1 - executionCount / meter.totalOperations) * 100).toStringAsFixed(1)}%',
  );
  print('Duration: ${meter.totalTime.inMilliseconds}ms');
}

/// Benchmark burst input with memoization
Future<void> benchmarkBurstInput() async {
  print('\n## Burst Input with Memoization\n');

  final searchApi = Func1<String, List<String>>((query) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return ['result_$query'];
  });

  final memoized = searchApi.memoize(maxSize: 100);

  final meter = ThroughputMeter('Memoized Search')..start();

  var cacheHits = 0;
  var cacheMisses = 0;

  // Simulate repeated searches (many duplicates)
  final queries = List.generate(
    500,
    (i) => generateStrings(1, length: 5).first,
  );

  final timer = CpuTimer('Search')..start();

  for (final query in queries) {
    final before = DateTime.now();
    await memoized(query);
    final duration = DateTime.now().difference(before);

    meter.record();

    // Heuristic: cache hits are much faster
    if (duration.inMicroseconds < 1000) {
      cacheHits++;
    } else {
      cacheMisses++;
    }
  }

  timer.stop();
  meter.stop();

  print('Total searches: ${meter.totalOperations}');
  print('Cache hits: $cacheHits');
  print('Cache misses: $cacheMisses');
  print(
    'Hit rate: ${(cacheHits / meter.totalOperations * 100).toStringAsFixed(1)}%',
  );
  print('Duration: ${timer.elapsedMilliseconds}ms');
  print(meter);
}
