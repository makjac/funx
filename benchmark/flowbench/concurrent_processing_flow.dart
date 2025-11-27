// ignore_for_file: sort_constructors_first, dangling_library_doc_comments, document_ignores, unreachable_from_main, avoid_print, lines_longer_than_80_chars

/// Flow benchmark: Concurrent task processing scenario
///
/// Simulates a job queue with:
/// - Semaphore for max concurrency control
/// - Bulkhead for resource isolation
/// - Queue for ordered processing

import 'dart:async';
import 'package:funx/funx.dart';

class ConcurrentProcessingFlow {
  int completedTasks = 0;
  int failedTasks = 0;
  final List<Duration> taskDurations = [];

  late Func1<int, String> processTask;

  ConcurrentProcessingFlow({required int maxConcurrent}) {
    // Simulated task processor
    final rawProcessor = Func1<int, String>((taskId) async {
      final taskStart = DateTime.now();

      // Simulate variable task duration
      final duration = Duration(milliseconds: 30 + (taskId % 50));
      await Future<void>.delayed(duration);

      taskDurations.add(DateTime.now().difference(taskStart));
      completedTasks++;

      return 'Task $taskId completed';
    });

    // Apply concurrency control
    processTask = rawProcessor.semaphore(maxConcurrent: maxConcurrent);
  }

  Future<void> processBatch(int taskCount) async {
    final futures = <Future<String>>[];

    for (var i = 0; i < taskCount; i++) {
      futures.add(
        processTask(i).catchError((Object error) {
          failedTasks++;
          return 'error';
        }),
      );
    }

    await Future.wait(futures);
  }

  void reset() {
    completedTasks = 0;
    failedTasks = 0;
    taskDurations.clear();
  }

  Duration get averageTaskDuration {
    if (taskDurations.isEmpty) return Duration.zero;
    final total = taskDurations.fold<int>(
      0,
      (sum, d) => sum + d.inMicroseconds,
    );
    return Duration(microseconds: total ~/ taskDurations.length);
  }
}

Future<void> main() async {
  print('⚙️  Concurrent Processing Flow Benchmark');
  print('=' * 60);

  const taskCount = 100;
  final concurrencyLevels = [1, 5, 10, 20, 50];

  for (final maxConcurrent in concurrencyLevels) {
    print(
      '\n📊 Processing $taskCount tasks with max $maxConcurrent concurrent',
    );

    final flow = ConcurrentProcessingFlow(maxConcurrent: maxConcurrent);
    final stopwatch = Stopwatch()..start();

    await flow.processBatch(taskCount);

    stopwatch.stop();

    print('Total time: ${stopwatch.elapsedMilliseconds}ms');
    print('Completed: ${flow.completedTasks}');
    print('Failed: ${flow.failedTasks}');
    print('Avg task duration: ${flow.averageTaskDuration.inMilliseconds}ms');
    print(
      'Throughput: ${(taskCount / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(2)} tasks/sec',
    );
  }

  print('\n${'=' * 60}');
}
