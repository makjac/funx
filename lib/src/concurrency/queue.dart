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

/// A function execution queue with configurable concurrency.
///
/// Example:
/// ```dart
/// final queue = FunctionQueue<Task, Result>(
///   concurrency: 2,
///   mode: QueueMode.fifo,
/// );
///
/// final result = await queue.enqueue(task, (t) => t.execute());
/// ```
class FunctionQueue<T, R> {
  /// Creates a function queue.
  ///
  /// Example:
  /// ```dart
  /// final queue = FunctionQueue<int, String>(
  ///   concurrency: 3,
  ///   mode: QueueMode.priority,
  ///   priorityFn: (n) => n,
  /// );
  /// ```
  FunctionQueue({
    required this.concurrency,
    required this.mode,
    this.priorityFn,
    this.maxQueueSize,
    this.onQueueChange,
  });

  /// Maximum number of concurrent executions.
  final int concurrency;

  /// Queue ordering mode.
  final QueueMode mode;

  /// Priority function for priority mode.
  final PriorityFunction<T>? priorityFn;

  /// Maximum queue size (null for unlimited).
  final int? maxQueueSize;

  /// Callback when queue size changes.
  final QueueChangeCallback? onQueueChange;

  int _running = 0;
  final _queue = Queue<_QueuedTask<T, R>>();

  /// Enqueues a task for execution.
  ///
  /// Example:
  /// ```dart
  /// final result = await queue.enqueue(data, (d) => process(d));
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

  /// Current queue length.
  ///
  /// Example:
  /// ```dart
  /// print('Queued: ${queue.queueLength}');
  /// ```
  int get queueLength => _queue.length;

  /// Number of currently running tasks.
  ///
  /// Example:
  /// ```dart
  /// print('Running: ${queue.runningTasks}');
  /// ```
  int get runningTasks => _running;
}

/// Applies queue mechanism to a [Func1].
///
/// Example:
/// ```dart
/// final process = Func1<Task, Result>((task) async => await task.execute())
///   .queue(concurrency: 2, mode: QueueMode.fifo);
/// ```
class QueueExtension1<T, R> extends Func1<T, R> {
  /// Creates a queue extension for a single-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final queued = QueueExtension1(
  ///   myFunc,
  ///   QueueMode.fifo,
  ///   1,
  ///   null,
  ///   null,
  ///   null,
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

/// Applies queue mechanism to a [Func2].
///
/// Example:
/// ```dart
/// final merge = Func2<String, String, String>((a, b) async => a + b)
///   .queue(concurrency: 1);
/// ```
class QueueExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a queue extension for a two-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final queued = QueueExtension2(
  ///   myFunc,
  ///   QueueMode.fifo,
  ///   1,
  ///   null,
  ///   null,
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
