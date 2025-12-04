/// Priority queue mechanism for priority-based execution ordering.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// Priority-ordered execution queue with starvation prevention.
///
/// Manages function execution with priority-based ordering for
/// optimal resource utilization. Items enqueue with priorities
/// determined by [Func1PriorityQueueExtension.priorityQueue]'s
/// `priorityFn`. The `maxQueueSize` limits queue capacity.
/// The `maxConcurrent` controls parallel executions. The
/// `starvationPrevention` enables fairness mechanism to boost
/// priorities of long-waiting items. The `onQueueFull` policy
/// determines overflow behavior. This pattern is essential for SLA
/// enforcement, critical vs background task prioritization, and
/// importance-based processing.
///
/// Returns a [Future] of type [R] from executed function. Higher
/// priority items execute first unless starvation prevention
/// intervenes.
///
/// Throws:
/// - [StateError] when queue is full and policy is error
/// - [ArgumentError] when configuration is invalid
///
/// Example:
/// ```dart
/// final processTask = Func1<Task, Result>((task) async {
///   return await task.execute();
/// }).priorityQueue(
///   priorityFn: (task) => task.priority,
///   maxQueueSize: 100,
///   maxConcurrent: 5,
///   starvationPrevention: true,
///   onQueueFull: QueueFullPolicy.dropLowestPriority,
/// );
/// ```
class PriorityQueueExtension<T, R> extends Func1<T, R> {
  /// Creates a priority queue extension for a one-parameter function.
  ///
  /// Wraps [_inner] function with priority queue mechanism using
  /// [_priorityFn] to calculate item priorities. The [_maxQueueSize]
  /// limits queue capacity. The [_maxConcurrent] controls parallel
  /// executions. The [_starvationPrevention] enables fairness.
  /// The [_onQueueFull] policy handles overflow. Callbacks track
  /// dropped items and starvation prevention events.
  ///
  /// Example:
  /// ```dart
  /// final queued = PriorityQueueExtension(
  ///   processor,
  ///   priorityFn: (task) => task.priority,
  ///   maxQueueSize: 100,
  ///   maxConcurrent: 5,
  ///   starvationPrevention: true,
  ///   onQueueFull: QueueFullPolicy.dropLowestPriority,
  /// );
  /// ```
  PriorityQueueExtension(
    this._inner, {
    required PriorityExtractor<T> priorityFn,
    int maxQueueSize = 1000,
    int maxConcurrent = 1,
    bool starvationPrevention = true,
    QueueFullPolicy onQueueFull = QueueFullPolicy.error,
    ItemDroppedCallback<T>? onItemDropped,
    StarvationPreventionCallback<T>? onStarvationPrevention,
  }) : _priorityFn = priorityFn,
       _maxQueueSize = maxQueueSize,
       _maxConcurrent = maxConcurrent,
       _starvationPrevention = starvationPrevention,
       _onQueueFull = onQueueFull,
       _onItemDropped = onItemDropped,
       _onStarvationPrevention = onStarvationPrevention,
       super((_) => throw UnimplementedError()) {
    _validateConfiguration();
  }

  final Func1<T, R> _inner;
  final PriorityExtractor<T> _priorityFn;
  final int _maxQueueSize;
  final int _maxConcurrent;
  final bool _starvationPrevention;
  final QueueFullPolicy _onQueueFull;
  final ItemDroppedCallback<T>? _onItemDropped;
  final StarvationPreventionCallback<T>? _onStarvationPrevention;

  final List<_PriorityItem<T, R>> _queue = [];
  int _activeCount = 0;

  void _validateConfiguration() {
    if (_maxQueueSize <= 0) {
      throw ArgumentError('maxQueueSize must be positive');
    }
    if (_maxConcurrent <= 0) {
      throw ArgumentError('maxConcurrent must be positive');
    }
  }

  @override
  Future<R> call(T arg) async {
    final priority = _priorityFn(arg);
    final item = _PriorityItem<T, R>(
      arg,
      priority,
      DateTime.now(),
      Completer<R>(),
    );

    // Handle queue full scenarios
    if (_queue.length >= _maxQueueSize) {
      await _handleQueueFull(item);
    } else {
      _addToQueue(item);
    }

    unawaited(_processQueue());

    return item.completer.future;
  }

  Future<void> _handleQueueFull(_PriorityItem<T, R> item) async {
    switch (_onQueueFull) {
      case QueueFullPolicy.dropLowestPriority:
        // Find lowest priority item
        if (_queue.isEmpty) {
          _addToQueue(item);
          return;
        }

        _sortQueue(); // Ensure queue is sorted
        final lowestPriorityItem = _queue.last;

        if (item.priority > lowestPriorityItem.priority) {
          // Drop lowest priority item and add new one
          final dropped = _queue.removeLast();
          _onItemDropped?.call(dropped.arg);
          dropped.completer.completeError(
            StateError('Dropped due to lower priority'),
          );
          _addToQueue(item);
        } else {
          // Drop new item
          _onItemDropped?.call(item.arg);
          item.completer.completeError(
            StateError('Dropped due to lower priority'),
          );
        }

      case QueueFullPolicy.dropNew:
        _onItemDropped?.call(item.arg);
        item.completer.completeError(
          StateError('Queue full - new item dropped'),
        );

      case QueueFullPolicy.error:
        item.completer.completeError(
          StateError('Queue full'),
        );

      case QueueFullPolicy.waitForSpace:
        // Wait for space by polling
        while (_queue.length >= _maxQueueSize) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        _addToQueue(item);
    }
  }

  void _addToQueue(_PriorityItem<T, R> item) {
    _queue.add(item);
    _sortQueue();
  }

  void _sortQueue() {
    // Sort by priority (highest first)
    _queue.sort((a, b) => b.priority.compareTo(a.priority));

    if (_starvationPrevention) {
      _preventStarvation();
    }
  }

  void _preventStarvation() {
    if (_queue.isEmpty) return;

    final now = DateTime.now();
    const waitThreshold = Duration(seconds: 5);

    // Boost priority of items waiting too long
    for (var i = 0; i < _queue.length; i++) {
      final item = _queue[i];
      final waitTime = now.difference(item.enqueuedAt);

      if (waitTime > waitThreshold && !item.priorityBoosted) {
        // Boost priority by adding wait time in seconds
        final boost = waitTime.inSeconds.toDouble();
        item
          ..priority = item.priority + boost
          ..priorityBoosted = true;
        _onStarvationPrevention?.call(item.arg);
      }
    }

    // Re-sort after boosting
    if (_queue.any((item) => item.priorityBoosted)) {
      _queue.sort((a, b) => b.priority.compareTo(a.priority));
    }
  }

  Future<void> _processQueue() async {
    while (_activeCount < _maxConcurrent && _queue.isNotEmpty) {
      _activeCount++;
      final item = _queue.removeAt(0); // Take highest priority

      unawaited(_executeItem(item));
    }
  }

  Future<void> _executeItem(_PriorityItem<T, R> item) async {
    try {
      final result = await _inner(item.arg);
      item.completer.complete(result);
    } catch (error, stackTrace) {
      item.completer.completeError(error, stackTrace);
    } finally {
      _activeCount--;
      unawaited(_processQueue());
    }
  }

  /// Current number of items waiting in the queue.
  ///
  /// Returns the count of items waiting to execute. Does not include
  /// currently executing items.
  ///
  /// Example:
  /// ```dart
  /// print('Queued: ${priorityQueue.queueLength}');
  /// ```
  int get queueLength => _queue.length;

  /// Number of items currently executing.
  ///
  /// Returns the count of items that are actively running. Maximum
  /// value equals [_maxConcurrent].
  ///
  /// Example:
  /// ```dart
  /// print('Active: ${priorityQueue.activeCount}');
  /// ```
  int get activeCount => _activeCount;
}

/// Priority queue item with metadata.
class _PriorityItem<T, R> {
  _PriorityItem(
    this.arg,
    this.priority,
    this.enqueuedAt,
    this.completer,
  );

  final T arg;
  num priority;
  final DateTime enqueuedAt;
  final Completer<R> completer;
  bool priorityBoosted = false;
}

/// Applies priority queue mechanism to one-parameter functions.
///
/// Extension providing factory method to wrap [Func1] with priority
/// queue execution control. Creates [PriorityQueueExtension] with
/// specified configuration for priority-based ordering.
///
/// Example:
/// ```dart
/// final processor = Func1<Task, Result>((task) async {
///   return await task.execute();
/// }).priorityQueue(
///   priorityFn: (task) => task.priority,
///   maxQueueSize: 100,
///   maxConcurrent: 5,
/// );
/// ```
extension Func1PriorityQueueExtension<T, R> on Func1<T, R> {
  /// Wraps function with priority queue mechanism.
  ///
  /// Creates priority queue wrapper with [priorityFn] to calculate
  /// item priorities. The [maxQueueSize] limits queue capacity.
  /// The [maxConcurrent] controls parallel executions. The
  /// [starvationPrevention] enables fairness mechanism. The
  /// [onQueueFull] policy handles overflow. Callbacks track dropped
  /// items and starvation prevention events.
  ///
  /// Returns wrapped function with priority queue control.
  ///
  /// Example:
  /// ```dart
  /// final queued = processor.priorityQueue(
  ///   priorityFn: (task) => task.priority,
  ///   maxQueueSize: 100,
  ///   maxConcurrent: 5,
  ///   starvationPrevention: true,
  ///   onQueueFull: QueueFullPolicy.dropLowestPriority,
  /// );
  /// ```
  Func1<T, R> priorityQueue({
    required PriorityExtractor<T> priorityFn,
    int maxQueueSize = 1000,
    int maxConcurrent = 1,
    bool starvationPrevention = true,
    QueueFullPolicy onQueueFull = QueueFullPolicy.error,
    ItemDroppedCallback<T>? onItemDropped,
    StarvationPreventionCallback<T>? onStarvationPrevention,
  }) {
    return PriorityQueueExtension<T, R>(
      this,
      priorityFn: priorityFn,
      maxQueueSize: maxQueueSize,
      maxConcurrent: maxConcurrent,
      starvationPrevention: starvationPrevention,
      onQueueFull: onQueueFull,
      onItemDropped: onItemDropped,
      onStarvationPrevention: onStarvationPrevention,
    );
  }
}

/// Applies priority queue mechanism to two-parameter functions.
///
/// Manages function execution with priority-based ordering for
/// two-parameter functions. Items enqueue with priorities
/// determined by [Func2PriorityQueueExtension.priorityQueue]'s
/// `priorityFn` applied to tuple of arguments. The `maxQueueSize`
/// limits queue capacity. The `maxConcurrent` controls parallel
/// executions. The `starvationPrevention` enables fairness
/// mechanism. The `onQueueFull` policy determines overflow behavior.
///
/// Example:
/// ```dart
/// final processor = Func2<String, int, Result>((id, priority) async {
///   return await process(id, priority);
/// }).priorityQueue(
///   priorityFn: (args) => args.$2, // Use second argument as priority
///   maxQueueSize: 100,
///   maxConcurrent: 5,
/// );
/// ```
class PriorityQueueExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a priority queue extension for a two-parameter function.
  ///
  /// Wraps [_inner] function with priority queue mechanism using
  /// [_priorityFn] to calculate priorities from argument tuple.
  /// The [_maxQueueSize] limits queue capacity. The [_maxConcurrent]
  /// controls parallel executions. The [_starvationPrevention]
  /// enables fairness. The [_onQueueFull] policy handles overflow.
  ///
  /// Example:
  /// ```dart
  /// final queued = PriorityQueueExtension2(
  ///   processor,
  ///   priorityFn: (args) => args.$2,
  ///   maxQueueSize: 100,
  ///   maxConcurrent: 5,
  /// );
  /// ```
  PriorityQueueExtension2(
    this._inner, {
    required PriorityExtractor<(T1, T2)> priorityFn,
    int maxQueueSize = 1000,
    int maxConcurrent = 1,
    bool starvationPrevention = true,
    QueueFullPolicy onQueueFull = QueueFullPolicy.error,
    ItemDroppedCallback<(T1, T2)>? onItemDropped,
    StarvationPreventionCallback<(T1, T2)>? onStarvationPrevention,
  }) : _priorityFn = priorityFn,
       _maxQueueSize = maxQueueSize,
       _maxConcurrent = maxConcurrent,
       _starvationPrevention = starvationPrevention,
       _onQueueFull = onQueueFull,
       _onItemDropped = onItemDropped,
       _onStarvationPrevention = onStarvationPrevention,
       super((_, _) => throw UnimplementedError()) {
    _validateConfiguration();
  }

  final Func2<T1, T2, R> _inner;
  final PriorityExtractor<(T1, T2)> _priorityFn;
  final int _maxQueueSize;
  final int _maxConcurrent;
  final bool _starvationPrevention;
  final QueueFullPolicy _onQueueFull;
  final ItemDroppedCallback<(T1, T2)>? _onItemDropped;
  final StarvationPreventionCallback<(T1, T2)>? _onStarvationPrevention;

  final List<_PriorityItem2<T1, T2, R>> _queue = [];
  int _activeCount = 0;

  void _validateConfiguration() {
    if (_maxQueueSize <= 0) {
      throw ArgumentError('maxQueueSize must be positive');
    }
    if (_maxConcurrent <= 0) {
      throw ArgumentError('maxConcurrent must be positive');
    }
  }

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final args = (arg1, arg2);
    final priority = _priorityFn(args);
    final item = _PriorityItem2<T1, T2, R>(
      arg1,
      arg2,
      priority,
      DateTime.now(),
      Completer<R>(),
    );

    // Handle queue full scenarios
    if (_queue.length >= _maxQueueSize) {
      await _handleQueueFull(item);
    } else {
      _addToQueue(item);
    }

    unawaited(_processQueue());

    return item.completer.future;
  }

  Future<void> _handleQueueFull(_PriorityItem2<T1, T2, R> item) async {
    switch (_onQueueFull) {
      case QueueFullPolicy.dropLowestPriority:
        if (_queue.isEmpty) {
          _addToQueue(item);
          return;
        }

        _sortQueue();
        final lowestPriorityItem = _queue.last;

        if (item.priority > lowestPriorityItem.priority) {
          final dropped = _queue.removeLast();
          _onItemDropped?.call((dropped.arg1, dropped.arg2));
          dropped.completer.completeError(
            StateError('Dropped due to lower priority'),
          );
          _addToQueue(item);
        } else {
          _onItemDropped?.call((item.arg1, item.arg2));
          item.completer.completeError(
            StateError('Dropped due to lower priority'),
          );
        }

      case QueueFullPolicy.dropNew:
        _onItemDropped?.call((item.arg1, item.arg2));
        item.completer.completeError(
          StateError('Queue full - new item dropped'),
        );

      case QueueFullPolicy.error:
        item.completer.completeError(
          StateError('Queue full'),
        );

      case QueueFullPolicy.waitForSpace:
        while (_queue.length >= _maxQueueSize) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        _addToQueue(item);
    }
  }

  void _addToQueue(_PriorityItem2<T1, T2, R> item) {
    _queue.add(item);
    _sortQueue();
  }

  void _sortQueue() {
    _queue.sort((a, b) => b.priority.compareTo(a.priority));

    if (_starvationPrevention) {
      _preventStarvation();
    }
  }

  void _preventStarvation() {
    if (_queue.isEmpty) return;

    final now = DateTime.now();
    const waitThreshold = Duration(seconds: 5);

    for (var i = 0; i < _queue.length; i++) {
      final item = _queue[i];
      final waitTime = now.difference(item.enqueuedAt);

      if (waitTime > waitThreshold && !item.priorityBoosted) {
        final boost = waitTime.inSeconds.toDouble();
        item
          ..priority = item.priority + boost
          ..priorityBoosted = true;
        _onStarvationPrevention?.call((item.arg1, item.arg2));
      }
    }

    if (_queue.any((item) => item.priorityBoosted)) {
      _queue.sort((a, b) => b.priority.compareTo(a.priority));
    }
  }

  Future<void> _processQueue() async {
    while (_activeCount < _maxConcurrent && _queue.isNotEmpty) {
      _activeCount++;
      final item = _queue.removeAt(0);

      unawaited(_executeItem(item));
    }
  }

  Future<void> _executeItem(_PriorityItem2<T1, T2, R> item) async {
    try {
      final result = await _inner(item.arg1, item.arg2);
      item.completer.complete(result);
    } catch (error, stackTrace) {
      item.completer.completeError(error, stackTrace);
    } finally {
      _activeCount--;
      unawaited(_processQueue());
    }
  }

  /// Current number of items waiting in the queue.
  int get queueLength => _queue.length;

  /// Number of items currently executing.
  int get activeCount => _activeCount;
}

/// Priority queue item for two-parameter functions.
class _PriorityItem2<T1, T2, R> {
  _PriorityItem2(
    this.arg1,
    this.arg2,
    this.priority,
    this.enqueuedAt,
    this.completer,
  );

  final T1 arg1;
  final T2 arg2;
  num priority;
  final DateTime enqueuedAt;
  final Completer<R> completer;
  bool priorityBoosted = false;
}

/// Applies priority queue mechanism to two-parameter functions.
///
/// Extension providing factory method to wrap [Func2] with priority
/// queue execution control. Creates [PriorityQueueExtension2] with
/// specified configuration for priority-based ordering.
///
/// Example:
/// ```dart
/// final processor = Func2<String, int, Result>((id, priority) async {
///   return await process(id, priority);
/// }).priorityQueue(
///   priorityFn: (args) => args.$2,
///   maxQueueSize: 100,
/// );
/// ```
extension Func2PriorityQueueExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Wraps function with priority queue mechanism.
  ///
  /// Creates priority queue wrapper with [priorityFn] to calculate
  /// priorities from argument tuple. The [maxQueueSize] limits queue
  /// capacity. The [maxConcurrent] controls parallel executions.
  /// The [starvationPrevention] enables fairness mechanism. The
  /// [onQueueFull] policy handles overflow.
  ///
  /// Returns wrapped function with priority queue control.
  ///
  /// Example:
  /// ```dart
  /// final queued = processor.priorityQueue(
  ///   priorityFn: (args) => args.$2,
  ///   maxQueueSize: 100,
  ///   maxConcurrent: 5,
  /// );
  /// ```
  Func2<T1, T2, R> priorityQueue({
    required PriorityExtractor<(T1, T2)> priorityFn,
    int maxQueueSize = 1000,
    int maxConcurrent = 1,
    bool starvationPrevention = true,
    QueueFullPolicy onQueueFull = QueueFullPolicy.error,
    ItemDroppedCallback<(T1, T2)>? onItemDropped,
    StarvationPreventionCallback<(T1, T2)>? onStarvationPrevention,
  }) {
    return PriorityQueueExtension2<T1, T2, R>(
      this,
      priorityFn: priorityFn,
      maxQueueSize: maxQueueSize,
      maxConcurrent: maxConcurrent,
      starvationPrevention: starvationPrevention,
      onQueueFull: onQueueFull,
      onItemDropped: onItemDropped,
      onStarvationPrevention: onStarvationPrevention,
    );
  }
}
