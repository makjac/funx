/// Memory overhead benchmarks for decorators benchmarks
// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_print, non_constant_identifier_names, avoid_relative_lib_imports benchmarks

library;

import 'package:funx/funx.dart';

import '../lib/metrics.dart';

Future<void> main() async {
  print('Memory Overhead Benchmarks');
  print('=' * 60);

  await benchmarkDecoratorOverhead();
  await benchmarkCacheGrowth();
}

/// Measure memory overhead of individual decorators
Future<void> benchmarkDecoratorOverhead() async {
  print('\n## Decorator Instance Overhead\n');

  final measurements = <String, int>{};

  // Baseline: plain function
  final before = captureMemoryMetrics();
  final functions = List.generate(1000, (_) => Func(() async => 42));
  await Future<void>.delayed(const Duration(milliseconds: 200));
  final after = captureMemoryMetrics();
  final baseline = (after.rss - before.rss) ~/ 1000;
  measurements['Baseline (Func)'] = baseline;
  print('Baseline (Func): ~${baseline}B per instance');

  // Clear
  functions.clear();
  await Future<void>.delayed(const Duration(milliseconds: 200));

  // Test each decorator
  await _measureDecorator('Debounce', () {
    return List.generate(
      1000,
      (_) => Func(() async => 42).debounce(const Duration(milliseconds: 100)),
    );
  }, measurements);

  await _measureDecorator('Throttle', () {
    return List.generate(
      1000,
      (_) => Func(() async => 42).throttle(const Duration(milliseconds: 100)),
    );
  }, measurements);

  await _measureDecorator('Lock', () {
    return List.generate(1000, (_) => Func(() async => 42).lock());
  }, measurements);

  await _measureDecorator('Semaphore', () {
    return List.generate(
      1000,
      (_) => Func(() async => 42).semaphore(maxConcurrent: 5),
    );
  }, measurements);

  await _measureDecorator('Memoize', () {
    return List.generate(
      1000,
      (_) => Func1<int, int>((n) async => n * 2).memoize(maxSize: 100),
    );
  }, measurements);

  await _measureDecorator('Retry', () {
    return List.generate(
      1000,
      (_) => Func(() async => 42).retry(maxAttempts: 3),
    );
  }, measurements);

  await _measureDecorator('CircuitBreaker', () {
    final cb = CircuitBreaker();
    return List.generate(
      1000,
      (_) => Func(() async => 42).circuitBreaker(cb),
    );
  }, measurements);

  // Summary
  print('\n## Summary\n');
  final sorted = measurements.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));

  for (final entry in sorted) {
    final overhead = entry.value - baseline;
    print(
      '${entry.key.padRight(25)}: ~${entry.value.toString().padLeft(6)}B '
      '(+${overhead.toString().padLeft(5)}B overhead)',
    );
  }
}

Future<void> _measureDecorator(
  String name,
  List<dynamic> Function() creator,
  Map<String, int> results,
) async {
  final before = captureMemoryMetrics();
  final instances = creator();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  final after = captureMemoryMetrics();
  final perInstance = (after.rss - before.rss) ~/ 1000;
  results[name] = perInstance;
  print('$name: ~${perInstance}B per instance');

  // Clear
  instances.clear();
  await Future<void>.delayed(const Duration(milliseconds: 200));
}

/// Measure memory growth for cache-based decorators
Future<void> benchmarkCacheGrowth() async {
  print('\n## Cache Growth (Memoize)\n');

  final sizes = [10, 100, 1000, 10000];
  final results = <int, int>{};

  for (final size in sizes) {
    final before = captureMemoryMetrics();

    final memoized = Func1<int, int>((n) async => n * 2).memoize(
      maxSize: size,
    );

    // Fill cache
    for (var i = 0; i < size; i++) {
      await memoized(i);
    }

    await Future<void>.delayed(const Duration(milliseconds: 200));
    final after = captureMemoryMetrics();

    final growth = after.rss - before.rss;
    results[size] = growth;

    final perEntry = size > 0 ? growth ~/ size : 0;
    print(
      'Cache size $size: ${_formatBytes(growth)} '
      '(~${perEntry}B per entry)',
    );

    // Clear for next test
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  print('\n## Cache Growth Analysis\n');
  if (results.length >= 2) {
    final sizes_list = results.keys.toList()..sort();
    for (var i = 1; i < sizes_list.length; i++) {
      final prevSize = sizes_list[i - 1];
      final currSize = sizes_list[i];
      final growth = results[currSize]! - results[prevSize]!;
      final entries = currSize - prevSize;
      final perEntry = entries > 0 ? growth ~/ entries : 0;
      print(
        '$prevSize → $currSize entries: '
        '${_formatBytes(growth)} (~${perEntry}B per entry)',
      );
    }
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}
