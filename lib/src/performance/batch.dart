import 'dart:async';

import 'package:funx/src/core/func.dart';

/// A function that batches multiple calls together and executes them as a group
///
/// Calls are accumulated until either [maxSize] is reached or [maxWait]
/// duration elapses, then all accumulated calls are executed together.
///
/// Example:
/// ```dart
/// final processBatch = Func1((List<String> items) async {
///   await database.insertAll(items);
/// });
///
/// final batchedInsert = Func1((String item) => item).batch(
///   executor: processBatch,
///   maxSize: 100,
///   maxWait: Duration(seconds: 5),
/// );
///
/// // These calls accumulate:
/// await batchedInsert('item1');
/// await batchedInsert('item2');
/// await batchedInsert('item3');
/// // After maxWait or maxSize reached, all items processed together
/// ```
class BatchExtension<T, R> extends Func1<T, R> {
  /// Creates a batch extension with the given configuration.
  ///
  /// The [executor] processes accumulated items when batch is triggered.
  /// The [maxSize] and [maxWait] control when batches are executed.
  BatchExtension(
    this._inner, {
    required this.executor,
    required this.maxSize,
    required this.maxWait,
  }) : super((_) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Function that processes a batch of accumulated items.
  final Func1<List<T>, void> executor;

  /// Maximum number of items before triggering batch execution.
  final int maxSize;

  /// Maximum time to wait before triggering batch execution.
  final Duration maxWait;

  final List<T> _pendingItems = [];
  final List<Completer<R>> _pendingCompleters = [];
  Timer? _timer;

  Future<void> _executeBatch() async {
    if (_pendingItems.isEmpty) return;

    _timer?.cancel();
    _timer = null;

    final items = List<T>.from(_pendingItems);
    final completers = List<Completer<R>>.from(_pendingCompleters);

    _pendingItems.clear();
    _pendingCompleters.clear();

    try {
      // Execute the batch
      await executor(items);

      // Complete all pending calls with their individual results
      for (var i = 0; i < completers.length; i++) {
        try {
          final result = await _inner(items[i]);
          completers[i].complete(result);
        } catch (error, stackTrace) {
          completers[i].completeError(error, stackTrace);
        }
      }
    } catch (error, stackTrace) {
      // If batch execution fails, fail all pending calls
      for (final completer in completers) {
        completer.completeError(error, stackTrace);
      }
    }
  }

  @override
  Future<R> call(T arg) async {
    final completer = Completer<R>();

    _pendingItems.add(arg);
    _pendingCompleters.add(completer);

    // Start timer if not already running
    _timer ??= Timer(maxWait, _executeBatch);

    // Execute immediately if maxSize reached
    if (_pendingItems.length >= maxSize) {
      await _executeBatch();
    }

    return completer.future;
  }

  /// Flushes any pending items immediately.
  Future<void> flush() => _executeBatch();

  /// Cancels pending batch and clears accumulated items.
  void cancel() {
    _timer?.cancel();
    _timer = null;

    // Complete all pending calls with error
    for (final completer in _pendingCompleters) {
      completer.completeError(StateError('Batch cancelled'));
    }

    _pendingItems.clear();
    _pendingCompleters.clear();
  }
}

/// A function that batches multiple calls with two arguments together.
///
/// Similar to [BatchExtension] but for functions with two parameters.
///
/// Example:
/// ```dart
/// final processBatch = Func1((List<(int, int)> pairs) async {
///   for (final pair in pairs) {
///     await database.insert(pair.$1, pair.$2);
///   }
/// });
///
/// final batchedOp = Func2((int a, int b) => (a, b)).batch(
///   executor: processBatch,
///   maxSize: 50,
///   maxWait: Duration(seconds: 3),
/// );
/// ```
class BatchExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a batch extension for two-argument functions.
  ///
  /// The [executor] processes accumulated argument pairs when triggered.
  /// The [maxSize] and [maxWait] control when batches are executed.
  BatchExtension2(
    this._inner, {
    required this.executor,
    required this.maxSize,
    required this.maxWait,
  }) : super((_, _) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Function that processes a batch of accumulated argument pairs.
  final Func1<List<(T1, T2)>, void> executor;

  /// Maximum number of items before triggering batch execution.
  final int maxSize;

  /// Maximum time to wait before triggering batch execution.
  final Duration maxWait;

  final List<(T1, T2)> _pendingItems = [];
  final List<Completer<R>> _pendingCompleters = [];
  Timer? _timer;

  Future<void> _executeBatch() async {
    if (_pendingItems.isEmpty) return;

    _timer?.cancel();
    _timer = null;

    final items = List<(T1, T2)>.from(_pendingItems);
    final completers = List<Completer<R>>.from(_pendingCompleters);

    _pendingItems.clear();
    _pendingCompleters.clear();

    try {
      // Execute the batch
      await executor(items);

      // Complete all pending calls with their individual results
      for (var i = 0; i < completers.length; i++) {
        try {
          final result = await _inner(items[i].$1, items[i].$2);
          completers[i].complete(result);
        } catch (error, stackTrace) {
          completers[i].completeError(error, stackTrace);
        }
      }
    } catch (error, stackTrace) {
      // If batch execution fails, fail all pending calls
      for (final completer in completers) {
        completer.completeError(error, stackTrace);
      }
    }
  }

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final completer = Completer<R>();

    _pendingItems.add((arg1, arg2));
    _pendingCompleters.add(completer);

    // Start timer if not already running
    _timer ??= Timer(maxWait, _executeBatch);

    // Execute immediately if maxSize reached
    if (_pendingItems.length >= maxSize) {
      await _executeBatch();
    }

    return completer.future;
  }

  /// Flushes any pending items immediately.
  Future<void> flush() => _executeBatch();

  /// Cancels pending batch and clears accumulated items.
  void cancel() {
    _timer?.cancel();
    _timer = null;

    for (final completer in _pendingCompleters) {
      completer.completeError(StateError('Batch cancelled'));
    }

    _pendingItems.clear();
    _pendingCompleters.clear();
  }
}

/// Extension methods on [Func1] for batching functionality.
extension Func1BatchExtension<T, R> on Func1<T, R> {
  /// Creates a batched version of this function that accumulates calls
  /// and executes them together.
  ///
  /// Parameters:
  /// - [executor]: Function that processes the accumulated batch
  /// - [maxSize]: Maximum batch size before execution
  /// - [maxWait]: Maximum wait time before execution
  ///
  /// Example:
  /// ```dart
  /// final insert = Func1((String item) => database.insert(item));
  /// final batched = insert.batch(
  ///   executor: Func1((items) => database.insertAll(items)),
  ///   maxSize: 100,
  ///   maxWait: Duration(seconds: 5),
  /// );
  /// ```
  Func1<T, R> batch({
    required Func1<List<T>, void> executor,
    required int maxSize,
    required Duration maxWait,
  }) => BatchExtension(
    this,
    executor: executor,
    maxSize: maxSize,
    maxWait: maxWait,
  );
}

/// Extension methods on [Func2] for batching functionality.
extension Func2BatchExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Creates a batched version of this function that accumulates calls
  /// and executes them together.
  ///
  /// Parameters:
  /// - [executor]: Function that processes the accumulated batch
  /// - [maxSize]: Maximum batch size before execution
  /// - [maxWait]: Maximum wait time before execution
  ///
  /// Example:
  /// ```dart
  /// final update = Func2((int id, String value) => db.update(id, value));
  /// final batched = update.batch(
  ///   executor: Func1((pairs) => db.updateAll(pairs)),
  ///   maxSize: 50,
  ///   maxWait: Duration(seconds: 3),
  /// );
  /// ```
  Func2<T1, T2, R> batch({
    required Func1<List<(T1, T2)>, void> executor,
    required int maxSize,
    required Duration maxWait,
  }) => BatchExtension2(
    this,
    executor: executor,
    maxSize: maxSize,
    maxWait: maxWait,
  );
}
