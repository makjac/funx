import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Batches multiple function calls for efficient grouped execution.
///
/// Accumulates individual calls and processes them together when either
/// the maximum batch size is reached or the maximum wait time elapses.
/// This pattern improves performance by reducing overhead of individual
/// operations, particularly useful for database operations, API calls,
/// or any scenario where bulk processing is more efficient. Each call
/// receives its individual result while benefiting from batch execution.
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
/// await batchedInsert('item1'); // Accumulated
/// await batchedInsert('item2'); // Accumulated
/// await batchedInsert('item3'); // Accumulated
/// // After maxWait or maxSize, all items processed together
/// ```
class BatchExtension<T, R> extends Func1<T, R> {
  /// Creates a batch wrapper for the given function.
  ///
  /// The [_inner] function is called for each item to produce individual
  /// results. The [executor] processes all accumulated items as a batch
  /// when triggered. The [maxSize] parameter sets the maximum number of
  /// items before automatic execution. The [maxWait] parameter sets the
  /// maximum time to wait before execution regardless of batch size.
  ///
  /// Example:
  /// ```dart
  /// final batched = BatchExtension(
  ///   processItem,
  ///   executor: batchProcessor,
  ///   maxSize: 50,
  ///   maxWait: Duration(seconds: 2),
  /// );
  /// ```
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

  /// Immediately executes all pending items in the batch.
  ///
  /// Forces execution of accumulated items without waiting for maxSize
  /// or maxWait conditions. Useful when you need to ensure all pending
  /// operations complete before a critical point in your application.
  ///
  /// Returns a [Future] that completes when batch execution finishes.
  ///
  /// Example:
  /// ```dart
  /// await batchedOperation('item1');
  /// await batchedOperation('item2');
  /// await batchedOperation.flush(); // Process now
  /// ```
  Future<void> flush() => _executeBatch();

  /// Cancels the pending batch and clears all accumulated items.
  ///
  /// Stops the wait timer and completes all pending calls with a
  /// [StateError]. This is useful when you need to abort a batch
  /// operation, such as during application shutdown or when cancelling
  /// a long-running process.
  ///
  /// All pending futures will complete with error.
  ///
  /// Example:
  /// ```dart
  /// await batchedOperation('item1');
  /// batchedOperation.cancel(); // Aborts pending batch
  /// ```
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

/// Batches multiple two-argument function calls for grouped execution.
///
/// Extends batching functionality to functions with two parameters.
/// Accumulates argument pairs and processes them together when batch
/// conditions are met. Each call receives its individual result while
/// benefiting from efficient bulk processing.
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
  /// Creates a batch wrapper for a two-argument function.
  ///
  /// The [_inner] function processes each argument pair to produce
  /// individual results. The [executor] handles batched execution of
  /// all accumulated pairs. The [maxSize] sets maximum items before
  /// automatic execution. The [maxWait] sets maximum wait time.
  ///
  /// Example:
  /// ```dart
  /// final batched = BatchExtension2(
  ///   processArgs,
  ///   executor: batchProcessor,
  ///   maxSize: 30,
  ///   maxWait: Duration(seconds: 1),
  /// );
  /// ```
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

  /// Immediately executes all pending argument pairs in the batch.
  ///
  /// Forces execution of accumulated items without waiting for batch
  /// conditions. Returns a [Future] that completes when execution
  /// finishes.
  ///
  /// Example:
  /// ```dart
  /// await batched(1, 2);
  /// await batched.flush();
  /// ```
  Future<void> flush() => _executeBatch();

  /// Cancels the pending batch and clears accumulated argument pairs.
  ///
  /// Stops the wait timer and completes all pending calls with a
  /// [StateError]. All pending futures will complete with error.
  ///
  /// Example:
  /// ```dart
  /// await batched(1, 2);
  /// batched.cancel();
  /// ```
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

/// Extension methods for adding batch functionality to functions.
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
