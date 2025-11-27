/// Benchmark result comparison and analysis tool
// ignore_for_file: avoid_slow_async_io, avoid_print, unreachable_from_main

library;

import 'dart:convert';
import 'dart:io';

/// Compare benchmark results and detect regressions
class BenchmarkComparator {
  BenchmarkComparator({
    required this.baselineFile,
    required this.currentFile,
    this.regressionThreshold = 1.10, // 10% slower = regression
  });

  final String baselineFile;
  final String currentFile;
  final double regressionThreshold;

  Future<ComparisonResult> compare() async {
    final baseline = await _loadResults(baselineFile);
    final current = await _loadResults(currentFile);

    final comparisons = <BenchmarkComparison>[];
    final regressions = <String>[];
    final improvements = <String>[];

    for (final entry in current.entries) {
      final name = entry.key;
      final currentMean = entry.value['mean'] as double;

      if (baseline.containsKey(name)) {
        final baselineMean = baseline[name]!['mean'] as double;
        final ratio = currentMean / baselineMean;
        final percentChange = (ratio - 1) * 100;

        comparisons.add(
          BenchmarkComparison(
            name: name,
            baselineMean: baselineMean,
            currentMean: currentMean,
            ratio: ratio,
            percentChange: percentChange,
          ),
        );

        if (ratio >= regressionThreshold) {
          regressions.add(name);
        } else if (ratio <= 0.9) {
          // 10% faster = improvement
          improvements.add(name);
        }
      }
    }

    return ComparisonResult(
      comparisons: comparisons,
      regressions: regressions,
      improvements: improvements,
    );
  }

  Future<Map<String, Map<String, dynamic>>> _loadResults(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Results file not found: $path');
    }

    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return json.cast<String, Map<String, dynamic>>();
  }
}

/// Comparison result between baseline and current benchmarks
class ComparisonResult {
  ComparisonResult({
    required this.comparisons,
    required this.regressions,
    required this.improvements,
  });

  final List<BenchmarkComparison> comparisons;
  final List<String> regressions;
  final List<String> improvements;

  bool get hasRegressions => regressions.isNotEmpty;
  bool get hasImprovements => improvements.isNotEmpty;

  void printSummary() {
    print('Benchmark Comparison Results');
    print('=' * 80);
    print('\nTotal benchmarks compared: ${comparisons.length}');
    print('Regressions detected: ${regressions.length}');
    print('Improvements detected: ${improvements.length}');

    if (hasRegressions) {
      print('\n⚠️  REGRESSIONS:');
      for (final name in regressions) {
        final comp = comparisons.firstWhere((c) => c.name == name);
        print('  - $name: ${comp.percentChange.toStringAsFixed(1)}% slower');
      }
    }

    if (hasImprovements) {
      print('\n✅ IMPROVEMENTS:');
      for (final name in improvements) {
        final comp = comparisons.firstWhere((c) => c.name == name);
        print('  - $name: ${(-comp.percentChange).toStringAsFixed(1)}% faster');
      }
    }

    print('\nDetailed Comparison:');
    print('-' * 80);
    print(
      '${'Benchmark'.padRight(40)} ${'Baseline'.padLeft(12)} '
      '${'Current'.padLeft(12)} ${'Change'.padLeft(10)}',
    );
    print('-' * 80);

    for (final comp in comparisons) {
      final changeStr =
          '${comp.percentChange >= 0 ? '+' : ''}'
          '${comp.percentChange.toStringAsFixed(1)}%';
      print(
        '${comp.name.padRight(40)} '
        '${comp.baselineMean.toStringAsFixed(3).padLeft(12)}μs '
        '${comp.currentMean.toStringAsFixed(3).padLeft(12)}μs '
        '${changeStr.padLeft(10)}',
      );
    }
  }
}

/// Individual benchmark comparison
class BenchmarkComparison {
  BenchmarkComparison({
    required this.name,
    required this.baselineMean,
    required this.currentMean,
    required this.ratio,
    required this.percentChange,
  });

  final String name;
  final double baselineMean;
  final double currentMean;
  final double ratio;
  final double percentChange;
}

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    print(
      'Usage: dart run benchmark/analysis/compare.dart <baseline.json> <current.json>',
    );
    exit(1);
  }

  final comparator = BenchmarkComparator(
    baselineFile: args[0],
    currentFile: args[1],
  );

  try {
    final result = await comparator.compare();
    result.printSummary();

    // Exit with error code if regressions detected
    if (result.hasRegressions) {
      exit(1);
    }
  } catch (e) {
    print('Error comparing benchmarks: $e');
    exit(1);
  }
}
