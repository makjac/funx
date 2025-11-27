/// Benchmark report generator - creates markdown and JSON reports
// ignore_for_file: avoid_relative_lib_imports, avoid_print, avoid_slow_async_io

library;

import 'dart:convert';
import 'dart:io';

import '../lib/harness.dart';

/// Generate comprehensive benchmark reports
class ReportGenerator {
  ReportGenerator({
    required this.results,
    required this.title,
    this.outputDir = 'benchmark/results',
  });

  final List<BenchmarkResult> results;
  final String title;
  final String outputDir;

  /// Generate all report formats
  Future<void> generateAll() async {
    await _ensureOutputDir();
    await generateMarkdown();
    await generateJson();
    print('\nReports generated in: $outputDir/');
  }

  /// Generate markdown report
  Future<void> generateMarkdown() async {
    final buffer = StringBuffer()
      ..writeln('# $title')
      ..writeln()
      ..writeln('**Generated:** ${DateTime.now().toIso8601String()}')
      ..writeln()
      // Summary statistics
      ..writeln('## Summary')
      ..writeln()
      ..writeln('| Metric | Value |')
      ..writeln('|--------|-------|')
      ..writeln('| Total Benchmarks | ${results.length} |');

    if (results.isNotEmpty) {
      final totalIterations = results.fold<int>(
        0,
        (sum, r) => sum + r.iterations,
      );
      buffer.writeln('| Total Iterations | $totalIterations |');

      final avgMean =
          results.fold<double>(0, (sum, r) => sum + r.mean) / results.length;
      buffer.writeln(
        '| Average Mean | ${avgMean.toStringAsFixed(3)}μs |',
      );
    }
    buffer
      ..writeln()
      // Detailed results table
      ..writeln('## Detailed Results')
      ..writeln()
      ..writeln(
        '| Benchmark | Mean (μs) | p50 (μs) | p95 (μs) | p99 (μs) | Std Dev |',
      )
      ..writeln(
        '|-----------|-----------|----------|----------|----------|---------|',
      );

    for (final result in results) {
      buffer.writeln(
        '| ${result.name} '
        '| ${result.mean.toStringAsFixed(3)} '
        '| ${result.p50.toStringAsFixed(3)} '
        '| ${result.p95.toStringAsFixed(3)} '
        '| ${result.p99.toStringAsFixed(3)} '
        '| ${result.stdDev.toStringAsFixed(2)} |',
      );
    }
    buffer.writeln();

    // Overhead analysis (if baseline exists)
    final baseline = results.where((r) => r.name.contains('Baseline')).toList();
    if (baseline.isNotEmpty && results.length > 1) {
      buffer
        ..writeln('## Overhead Analysis')
        ..writeln()
        ..writeln(
          '| Decorator | Overhead (μs) | Overhead (%) | vs Baseline |',
        )
        ..writeln(
          '|-----------|---------------|--------------|-------------|',
        );

      final baselineMean = baseline.first.mean;
      for (final result in results) {
        if (result.name.contains('Baseline')) continue;
        final overhead = result.mean - baselineMean;
        final percentage = (overhead / baselineMean) * 100;
        buffer.writeln(
          '| ${result.name} '
          '| +${overhead.toStringAsFixed(3)} '
          '| +${percentage.toStringAsFixed(1)}% '
          '| ${result.mean.toStringAsFixed(3)}μs |',
        );
      }
      buffer.writeln();
    }

    // Write to file
    final file = File('$outputDir/${_sanitizeFilename(title)}.md');
    await file.writeAsString(buffer.toString());
    print('Markdown report: ${file.path}');
  }

  /// Generate JSON report
  Future<void> generateJson() async {
    final data = {
      'title': title,
      'generated': DateTime.now().toIso8601String(),
      'results': results.map((r) => r.toJson()).toList(),
      'summary': {
        'totalBenchmarks': results.length,
        'totalIterations': results.fold<int>(0, (sum, r) => sum + r.iterations),
        if (results.isNotEmpty)
          'averageMean':
              results.fold<double>(0, (sum, r) => sum + r.mean) /
              results.length,
      },
    };

    final file = File('$outputDir/${_sanitizeFilename(title)}.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );
    print('JSON report: ${file.path}');
  }

  Future<void> _ensureOutputDir() async {
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  String _sanitizeFilename(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}

/// Example usage
Future<void> main() async {
  // Example: generate report from sample data
  final sampleResults = [
    const BenchmarkResult(
      name: 'Example.Baseline',
      iterations: 10000,
      mean: 1.234,
      min: 0.5,
      max: 10,
      p50: 1.2,
      p90: 2.5,
      p95: 3,
      p99: 5,
      stdDev: 0.8,
      measurements: [],
      ci95: 5.5,
    ),
    const BenchmarkResult(
      name: 'Example.Debounce',
      iterations: 10000,
      mean: 25.678,
      min: 20,
      max: 50,
      p50: 25,
      p90: 30,
      p95: 35,
      p99: 45,
      stdDev: 5.2,
      measurements: [],
      ci95: 5.5,
    ),
  ];

  final generator = ReportGenerator(
    results: sampleResults,
    title: 'Funx Microbenchmark Results',
  );

  await generator.generateAll();
}
