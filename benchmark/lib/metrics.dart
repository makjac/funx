/// Metrics collection utilities for benchmarks
library;

import 'dart:async';
import 'dart:io';

/// Memory metrics snapshot
class MemoryMetrics {
  const MemoryMetrics({
    required this.rss,
    required this.heapUsage,
    required this.heapCapacity,
    required this.externalUsage,
  });

  /// Resident set size (total memory used by process)
  final int rss;

  /// Current heap usage in bytes
  final int heapUsage;

  /// Current heap capacity in bytes
  final int heapCapacity;

  /// External memory (native allocations) in bytes
  final int externalUsage;

  /// Total memory usage
  int get totalUsage => rss;

  /// Heap utilization percentage
  double get heapUtilization =>
      heapCapacity > 0 ? (heapUsage / heapCapacity) * 100 : 0;

  @override
  String toString() {
    return 'MemoryMetrics(rss: ${_formatBytes(rss)}, '
        'heap: ${_formatBytes(heapUsage)}/${_formatBytes(heapCapacity)} '
        '(${heapUtilization.toStringAsFixed(1)}%), '
        'external: ${_formatBytes(externalUsage)})';
  }

  Map<String, dynamic> toJson() {
    return {
      'rss': rss,
      'heapUsage': heapUsage,
      'heapCapacity': heapCapacity,
      'externalUsage': externalUsage,
      'totalUsage': totalUsage,
      'heapUtilization': heapUtilization,
    };
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

/// Capture current memory metrics
MemoryMetrics captureMemoryMetrics() {
  // Note: ProcessInfo is available in dart:io
  final info = ProcessInfo.currentRss;
  final maxRss = ProcessInfo.maxRss;

  // For more detailed metrics, we'd need to use dart:developer
  // or vm_service, but those require additional setup
  // For now, we'll use approximate values
  return MemoryMetrics(
    rss: info,
    heapUsage: info, // Approximate
    heapCapacity: maxRss,
    externalUsage: 0, // Would need vm_service for accurate value
  );
}

/// Memory overhead measurement
class MemoryOverhead {
  MemoryOverhead(this.name);

  final String name;
  late MemoryMetrics _before;
  late MemoryMetrics _after;

  /// Run a function and measure memory overhead
  Future<MemoryOverheadResult> measure(Future<void> Function() fn) async {
    // Force GC before measurement (not directly available, but requesting it)
    // In production benchmarks, you'd want to add delays for GC to settle
    await Future<void>.delayed(const Duration(milliseconds: 100));

    _before = captureMemoryMetrics();

    await fn();

    // Allow GC to settle
    await Future<void>.delayed(const Duration(milliseconds: 100));

    _after = captureMemoryMetrics();

    return MemoryOverheadResult(
      name: name,
      before: _before,
      after: _after,
      delta: _after.rss - _before.rss,
    );
  }
}

/// Result of memory overhead measurement
class MemoryOverheadResult {
  const MemoryOverheadResult({
    required this.name,
    required this.before,
    required this.after,
    required this.delta,
  });

  final String name;
  final MemoryMetrics before;
  final MemoryMetrics after;
  final int delta;

  @override
  String toString() {
    return '$name: ${MemoryMetrics._formatBytes(delta)} '
        '(${before.totalUsage} -> ${after.totalUsage})';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'before': before.toJson(),
      'after': after.toJson(),
      'delta': delta,
    };
  }
}

/// CPU time measurement
class CpuTimer {
  CpuTimer(this.name);

  final String name;
  final Stopwatch _stopwatch = Stopwatch();
  final List<Duration> _laps = [];

  /// Start the timer
  void start() {
    _stopwatch.start();
  }

  /// Stop the timer
  void stop() {
    _stopwatch.stop();
  }

  /// Record a lap time
  void lap() {
    _laps.add(_stopwatch.elapsed);
  }

  /// Reset the timer
  void reset() {
    _stopwatch.reset();
    _laps.clear();
  }

  /// Get elapsed time
  Duration get elapsed => _stopwatch.elapsed;

  /// Get elapsed time in microseconds
  int get elapsedMicroseconds => _stopwatch.elapsedMicroseconds;

  /// Get elapsed time in milliseconds
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;

  /// Get all lap times
  List<Duration> get laps => List.unmodifiable(_laps);

  @override
  String toString() {
    return '$name: $elapsedMicrosecondsμs';
  }
}

/// Throughput measurement
class ThroughputMeter {
  ThroughputMeter(this.name);

  final String name;
  int _operations = 0;
  final Stopwatch _stopwatch = Stopwatch();

  /// Start measuring
  void start() {
    _operations = 0;
    _stopwatch
      ..reset()
      ..start();
  }

  /// Record an operation
  void record() {
    _operations++;
  }

  /// Record multiple operations
  void recordBatch(int count) {
    _operations += count;
  }

  /// Stop measuring
  void stop() {
    _stopwatch.stop();
  }

  /// Get operations per second
  double get operationsPerSecond {
    if (_stopwatch.elapsedMicroseconds == 0) return 0;
    return (_operations * 1000000) / _stopwatch.elapsedMicroseconds;
  }

  /// Get total operations
  int get totalOperations => _operations;

  /// Get total time
  Duration get totalTime => _stopwatch.elapsed;

  @override
  String toString() {
    return '$name: ${operationsPerSecond.toStringAsFixed(2)} ops/sec '
        '($_operations ops in ${totalTime.inMilliseconds}ms)';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'operations': _operations,
      'durationMs': _stopwatch.elapsedMilliseconds,
      'operationsPerSecond': operationsPerSecond,
    };
  }
}
