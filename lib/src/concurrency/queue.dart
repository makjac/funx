/// Queue mechanism for sequential or controlled parallel execution.
library;

import 'dart:async';
import 'dart:collection';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

class _QueuedTask<T, R> {
  _QueuedTask(this.arg, this.fn, this.completer, this.priority);

  final T arg;
  final AsyncFunction1<T, R> fn;
  final Completer<R> completer;
  final int priority;
}

/// Execution queue with configurable concurrency and ordering.
///
/// Manages function execution with controlled parallelism and
/// ordering strategies. Tasks enqueue via [enqueue] and execute
/// according to [concurrency] limit and [mode] ordering (FIFO, LIFO,
/// or priority). The optional [priorityFn] determines task priority
/// in priority mode. The optional [maxQueueSize] limits queue length.
/// The optional [onQueueChange] callback tracks queue size changes.
/// This pattern is essential for rate limiting, ordered processing,
/// or priority-based task execution.
///
/// Example:
/// ```dart
/// final queue = FunctionQueue<Task, Result>(
///   concurrency: 2,
///   mode: QueueMode.priority,
///   priorityFn: (task) => task.priority,
///   maxQueueSize: 100,
///   onQueueChange: (size) => print('Queue: $size'),
/// );
///
/// final result = await queue.enqueue(task, (t) => t.execute());
/// ```
class FunctionQueue<T, R> {
  /// Creates a function execution queue with specified configuration.
  ///
  /// The [concurrency] parameter sets the maximum number of
  /// simultaneous executions. The [mode] parameter determines task
  /// ordering (FIFO, LIFO, or priority). The optional [priorityFn]
  /// calculates task priority for priority mode. The optional
  /// [maxQueueSize] limits queue capacity. The optional
  /// [onQueueChange] callback is invoked when queue size changes.
  ///
  /// Example:
  /// ```dart
  /// final queue = FunctionQueue<int, String>(
  ///   concurrency: 3,
  ///   mode: QueueMode.priority,
  ///   priorityFn: (n) => n,
  ///   maxQueueSize: 50,
  ///   onQueueChange: (size) => logger.info('Queue: $size'),
  /// );
  /// ```
  FunctionQueue({
    required this.concurrency,
    required this.mode,
    this.priorityFn,
    this.maxQueueSize,
    this.onQueueChange,
  });

  /// Maximum number of concurrent task executions.
  ///
  /// Limits how many tasks can execute simultaneously. Remaining
  /// tasks wait in the queue.
  final int concurrency;

  /// Queue ordering strategy.
  ///
  /// Determines task execution order: FIFO (first-in-first-out),
  /// LIFO (last-in-first-out), or priority-based ordering.
  final QueueMode mode;

  /// Optional function to calculate task priority.
  ///
  /// Required for priority mode. Returns higher values for higher
  /// priority tasks. Ignored in FIFO and LIFO modes.
  final PriorityFunction<T>? priorityFn;

  /// Optional maximum queue capacity.
  ///
  /// When set, [enqueue] throws [StateError] if queue is full. When
  /// null, queue has unlimited capacity.
  final int? maxQueueSize;

  /// Optional callback invoked when queue size changes.
  ///
  /// Called after tasks are enqueued or dequeued. Receives the new
  /// queue length.
  final QueueChangeCallback? onQueueChange;

  int _running = 0;
  final _queue = Queue<_QueuedTask<T, R>>();

  /// Enqueues a task for execution.
  ///
  /// Adds the task with [arg] and [fn] to the queue. If concurrency
  /// limit allows, executes immediately. Otherwise, waits in queue
  /// according to [mode] ordering. Priority is calculated via
  /// [priorityFn] if in priority mode. Throws [StateError] if queue
  /// is at [maxQueueSize].
  ///
  /// Returns a [Future] that completes with the task result.
  ///
  /// Throws:
  /// - [StateError] when queue is full
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final result = await queue.enqueue(
  ///     data,
  ///     (d) async => await process(d),
  ///   );
  /// } catch (e) {
  ///   print('Queue full or task failed: $e');
  /// }
  /// ```
  Future<R> enqueue(T arg, AsyncFunction1<T, R> fn) async {
    if (maxQueueSize != null && _queue.length >= maxQueueSize!) {
      throw StateError('Queue full');
    }

    final priority = priorityFn?.call(arg) ?? 0;
    final task = _QueuedTask<T, R>(arg, fn, Completer<R>(), priority);
    _addToQueue(task);
    onQueueChange?.call(_queue.length);

    unawaited(_processQueue());

    return task.completer.future;
  }

  void _addToQueue(_QueuedTask<T, R> task) {
    switch (mode) {
      case QueueMode.fifo:
        _queue.addLast(task);
      case QueueMode.lifo:
        _queue.addFirst(task);
      case QueueMode.priority:
        if (priorityFn != null) {
          final list = _queue.toList();
          var inserted = false;
          for (var i = 0; i < list.length; i++) {
            if (task.priority > list[i].priority) {
              list.insert(i, task);
              inserted = true;
              break;
            }
          }
          if (!inserted) {
            list.add(task);
          }
          _queue
            ..clear()
            ..addAll(list);
        } else {
          _queue.addLast(task);
        }
    }
  }

  Future<void> _processQueue() async {
    while (_running < concurrency && _queue.isNotEmpty) {
      _running++;
      final task = _queue.removeFirst();
      onQueueChange?.call(_queue.length);

      unawaited(_executeTask(task));
    }
  }

  Future<void> _executeTask(_QueuedTask<T, R> task) async {
    try {
      final result = await task.fn(task.arg);
      task.completer.complete(result);
    } catch (error, stackTrace) {
      task.completer.completeError(error, stackTrace);
    } finally {
      _running--;
      unawaited(_processQueue());
    }
  }

  /// Current number of tasks waiting in the queue.
  ///
  /// Returns the count of tasks waiting to execute. Does not include
  /// currently running tasks.
  ///
  /// Example:
  /// ```dart
  /// print('Queued tasks: ${queue.queueLength}');
  /// if (queue.queueLength > 50) {
  ///   print('Queue is getting full');
  /// }
  /// ```
  int get queueLength => _queue.length;

  /// Number of tasks currently executing.
  ///
  /// Returns the count of tasks that are actively running. Maximum
  /// value equals [concurrency].
  ///
  /// Example:
  /// ```dart
  /// print('Running: ${queue.runningTasks}/${queue.concurrency}');
  /// ```
  int get runningTasks => _running;
}

/// Applies queue mechanism to one-parameter functions.
///
/// Wraps a [Func1] to execute through a function queue with
/// controlled concurrency and ordering. Each function call enqueues
/// for execution according to [_mode] strategy. The [_concurrency]
/// limits simultaneous executions. The optional [_priorityFn]
/// calculates priority in priority mode. The [queueLength] and
/// [runningTasks] getters provide queue state. This pattern is
/// essential for rate limiting, ordered processing, or priority-based
/// execution.
///
/// Example:
/// ```dart
/// final process = Func1<Task, Result>((task) async {
///   return await task.execute();
/// }).queue(
///   concurrency: 2,
///   mode: QueueMode.fifo,
///   maxQueueSize: 100,
/// );
/// ```
class QueueExtension1<T, R> extends Func1<T, R> {
  /// Creates a queue extension for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [_mode]
  /// parameter sets ordering strategy. The [_concurrency] parameter
  /// limits simultaneous executions. The optional [_priorityFn]
  /// calculates priority. The optional [_onQueueChange] tracks queue
  /// size. The optional [_maxQueueSize] limits capacity.
  ///
  /// Example:
  /// ```dart
  /// final queued = QueueExtension1(
  ///   myFunc,
  ///   QueueMode.priority,
  ///   2,
  ///   (task) => task.priority,
  ///   (size) => print('Queue: $size'),
  ///   50,
  /// );
  /// ```
  QueueExtension1(
    this._inner,
    this._mode,
    this._concurrency,
    this._priorityFn,
    this._onQueueChange,
    this._maxQueueSize,
  ) : super(_inner.call) {
    _queue = FunctionQueue<T, R>(
      concurrency: _concurrency,
      mode: _mode,
      priorityFn: _priorityFn,
      maxQueueSize: _maxQueueSize,
      onQueueChange: _onQueueChange,
    );
  }

  final Func1<T, R> _inner;
  final QueueMode _mode;
  final int _concurrency;
  final PriorityFunction<T>? _priorityFn;
  final QueueChangeCallback? _onQueueChange;
  final int? _maxQueueSize;

  late final FunctionQueue<T, R> _queue;

  @override
  Future<R> call(T arg) async {
    return _queue.enqueue(arg, _inner.call);
  }

  /// Current queue length.
  ///
  /// Example:
  /// ```dart
  /// print('Queued: ${queuedFunc.queueLength}');
  /// ```
  int get queueLength => _queue.queueLength;

  /// Number of currently running tasks.
  ///
  /// Example:
  /// ```dart
  /// print('Running: ${queuedFunc.runningTasks}');
  /// ```
  int get runningTasks => _queue.runningTasks;
}

/// Applies queue mechanism to two-parameter functions.
///
/// Wraps a [Func2] to execute through a function queue with
/// controlled concurrency and ordering. Each function call enqueues
/// for execution according to [_mode] strategy. The [_concurrency]
/// limits simultaneous executions. The [queueLength] and
/// [runningTasks] getters provide queue state. This pattern is
/// essential for rate limiting, ordered processing, or controlled
/// parallel execution.
///
/// Example:
/// ```dart
/// final merge = Func2<String, String, String>((a, b) async {
///   return await combine(a, b);
/// }).queue(
///   concurrency: 1,
///   mode: QueueMode.fifo,
/// );
/// ```
class QueueExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a queue extension for a two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [_mode]
  /// parameter sets ordering strategy. The [_concurrency] parameter
  /// limits simultaneous executions. The optional [_onQueueChange]
  /// tracks queue size. The optional [_maxQueueSize] limits capacity.
  ///
  /// Example:
  /// ```dart
  /// final queued = QueueExtension2(
  ///   myFunc,
  ///   QueueMode.lifo,
  ///   3,
  ///   (size) => print('Queue: $size'),
  ///   100,
  /// );
  /// ```
  QueueExtension2(
    this._inner,
    this._mode,
    this._concurrency,
    this._onQueueChange,
    this._maxQueueSize,
  ) : super(_inner.call) {
    _queue = FunctionQueue<(T1, T2), R>(
      concurrency: _concurrency,
      mode: _mode,
      maxQueueSize: _maxQueueSize,
      onQueueChange: _onQueueChange,
    );
  }

  final Func2<T1, T2, R> _inner;
  final QueueMode _mode;
  final int _concurrency;
  final QueueChangeCallback? _onQueueChange;
  final int? _maxQueueSize;

  late final FunctionQueue<(T1, T2), R> _queue;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    return _queue.enqueue((arg1, arg2), (args) => _inner(args.$1, args.$2));
  }

  /// Current queue length.
  ///
  /// Example:
  /// ```dart
  /// print('Queued: ${queuedFunc.queueLength}');
  /// ```
  int get queueLength => _queue.queueLength;

  /// Number of currently running tasks.
  ///
  /// Example:
  /// ```dart
  /// print('Running: ${queuedFunc.runningTasks}');
  /// ```
  int get runningTasks => _queue.runningTasks;
}
