/// Run all benchmarks and generate reports
// ignore_for_file: avoid_print, avoid_slow_async_io

library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  print('═' * 80);
  print('Funx Benchmark Suite');
  print('═' * 80);
  print('');

  final runAll = args.contains('--all');
  final runMicro = args.contains('--micro') || runAll;
  final runMemory = args.contains('--memory') || runAll;
  final runFlow = args.contains('--flow') || runAll;
  final quickMode = args.contains('--quick') || args.contains('-q');
  final verbose = args.contains('--verbose') || args.contains('-v');

  if (!runMicro && !runMemory && !runFlow) {
    print('Usage: dart run benchmark/run_all.dart [options]');
    print('');
    print('Options:');
    print('  --all       Run all benchmarks');
    print('  --micro     Run microbenchmarks only');
    print('  --memory    Run memory benchmarks only');
    print('  --flow      Run flow benchmarks only');
    print(
      '  --quick, -q Quick mode (100 warmup + 1000 iterations, ~10x faster)',
    );
    print('  --verbose, -v Show detailed output from each benchmark');
    print('');
    print('Examples:');
    print('  dart run benchmark/run_all.dart --all');
    print('  dart run benchmark/run_all.dart --micro --quick  # Fast run');
    print(
      '  dart run benchmark/run_all.dart --micro --quick --verbose  # See progress',
    );
    exit(1);
  }

  if (quickMode) {
    print('⚡ QUICK MODE ENABLED');
    print('  - Warmup: 100 iterations (vs 1000)');
    print('  - Measurement: 1000 iterations (vs 10000)');
    print('  - Speed: ~10x faster, less accurate');
    print('');
  }

  if (!verbose) {
    print('💡 Tip: Use --verbose to see benchmark progress in real-time');
    print('');
  }

  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final resultsDir = 'benchmark/results/$timestamp';

  // Create results directory
  await Directory(resultsDir).create(recursive: true);

  // Create summary file
  final summaryFile = File('$resultsDir/summary.txt');
  final summaryBuffer = StringBuffer()
    ..writeln('═' * 80)
    ..writeln('Funx Benchmark Suite')
    ..writeln('Run at: $timestamp')
    ..writeln('═' * 80)
    ..writeln();

  if (runMicro) {
    await _runSection(
      summaryBuffer,
      'Microbenchmarks',
      [
        // Timing decorators
        'benchmark/microbench/timing/debounce_bench.dart',
        'benchmark/microbench/timing/throttle_bench.dart',
        'benchmark/microbench/timing/timeout_bench.dart',

        // Concurrency primitives
        'benchmark/microbench/concurrency/lock_bench.dart',
        'benchmark/microbench/concurrency/semaphore_bench.dart',

        // Performance optimizations
        'benchmark/microbench/performance/memoize_bench.dart',
        'benchmark/microbench/performance/rate_limit_bench.dart',
        'benchmark/microbench/performance/batch_bench.dart',
        'benchmark/microbench/performance/deduplicate_bench.dart',
        'benchmark/microbench/performance/share_bench.dart',

        // Reliability patterns
        'benchmark/microbench/reliability/retry_bench.dart',
        'benchmark/microbench/reliability/fallback_bench.dart',
        'benchmark/microbench/reliability/circuit_breaker_bench.dart',

        // Error handling
        'benchmark/microbench/error_handling/catch_bench.dart',

        // Validation
        'benchmark/microbench/validation/guard_bench.dart',
      ],
      quickMode: quickMode,
      verbose: verbose,
    );
  }

  if (runMemory) {
    await _runSection(
      summaryBuffer,
      'Memory Benchmarks',
      [
        'benchmark/memory/decorator_overhead.dart',
      ],
      quickMode: quickMode,
      verbose: verbose,
    );
  }

  if (runFlow) {
    await _runSection(
      summaryBuffer,
      'Flow Benchmarks',
      [
        'benchmark/flowbench/search_autocomplete.dart',
        'benchmark/flowbench/api_gateway.dart',
      ],
      quickMode: quickMode,
      verbose: verbose,
    );
  }

  // Write summary to file
  summaryBuffer
    ..writeln()
    ..writeln('═' * 80)
    ..writeln('Benchmark Suite Complete')
    ..writeln('═' * 80);
  await summaryFile.writeAsString(summaryBuffer.toString());

  print('');
  print('═' * 80);
  print('Benchmark Suite Complete');
  print('Results saved to: $resultsDir');
  print('═' * 80);
}

Future<void> _runSection(
  StringBuffer summary,
  String title,
  List<String> benchmarks, {
  bool quickMode = false,
  bool verbose = false,
}) async {
  print('');
  print('─' * 80);
  print(title);
  print('─' * 80);
  print('');

  summary
    ..writeln()
    ..writeln('─' * 80)
    ..writeln(title)
    ..writeln('─' * 80)
    ..writeln();

  for (var i = 0; i < benchmarks.length; i++) {
    final benchmark = benchmarks[i];
    final file = File(benchmark);
    if (!await file.exists()) {
      final msg = '⚠️  Skipping $benchmark (file not found)';
      print(msg);
      summary.writeln(msg);
      continue;
    }

    print('[${i + 1}/${benchmarks.length}] Running: $benchmark');
    if (!verbose) {
      stdout.write('  ⏳ Please wait...');
    }
    summary.writeln('Running: $benchmark');

    final args = ['run', benchmark];
    if (quickMode) {
      args.add('--quick');
    }

    final startTime = DateTime.now();
    final process = await Process.start(
      'dart',
      args,
      runInShell: true,
    );

    // Capture output
    final stdoutLines = <String>[];
    final stderrLines = <String>[];

    if (verbose) {
      // Show output in real-time
      process.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((line) {
            print('  $line');
            stdoutLines.add(line);
          });
      process.stderr
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((line) {
            stderr.writeln('  ⚠️  $line');
            stderrLines.add(line);
          });
    } else {
      // Buffer output silently, show spinner
      var spinnerIndex = 0;
      final spinnerChars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
      Timer? spinnerTimer;

      process.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen(stdoutLines.add);
      process.stderr
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen(stderrLines.add);

      // Show animated spinner
      spinnerTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        stdout.write('\r  ${spinnerChars[spinnerIndex]} Running...');
        spinnerIndex = (spinnerIndex + 1) % spinnerChars.length;
      });

      await process.exitCode;
      spinnerTimer.cancel();
      stdout.write('\r  ✓ Done      \n');
    }

    final exitCode = await process.exitCode;
    final elapsed = DateTime.now().difference(startTime);

    if (exitCode == 0) {
      if (!verbose) {
        // Show summary of results only
        final resultLines = stdoutLines
            .where(
              (line) =>
                  line.contains('μs') || line.contains('Performance Analysis'),
            )
            .toList();

        if (resultLines.isNotEmpty) {
          print('  Results:');
          for (final line in resultLines.take(5)) {
            print('    $line');
          }
          if (resultLines.length > 5) {
            print('    ... (${resultLines.length - 5} more lines)');
          }
        }
      }
      print('  ⏱️  Time: ${elapsed.inSeconds}s');

      summary.writeln(stdoutLines.join('\n'));
      if (stderrLines.isNotEmpty) {
        summary
          ..writeln('Warnings:')
          ..writeln(stderrLines.join('\n'));
      }
    } else {
      final errorMsg = '❌ Failed to run $benchmark (exit code: $exitCode)';
      print(errorMsg);
      if (!verbose && stderrLines.isNotEmpty) {
        print('  Error: ${stderrLines.take(3).join('\n  ')}');
      }
      summary
        ..writeln(errorMsg)
        ..writeln('Error:')
        ..writeln(stderrLines.join('\n'));
    }
    print('');
    summary.writeln();
  }
}
