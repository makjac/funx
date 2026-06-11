/// Bulkhead mechanism for resource isolation.
library;

import 'dart:async';

import 'package:funx/src/concurrency/_concurrency_engines.dart';
import 'package:funx/src/concurrency/semaphore.dart';
import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// Resource isolation mechanism using separate execution pools.
///
/// Isolates executions into separate resource pools to prevent
/// cascading failures and resource exhaustion. Maintains [poolSize]
/// number of independent execution pools, each with its own
/// [queueSize] limit. Uses round-robin selection to distribute
/// executions across pools. When one pool becomes saturated, other
/// pools remain operational. This pattern is essential for fault
/// isolation, preventing one slow or failing operation from
/// exhausting all resources and affecting unrelated operations.
///
/// Example:
/// ```dart
/// final bulkhead = Bulkhead(poolSize: 4, queueSize: 100);
///
/// final result = await bulkhead.execute(
///   () async => await databaseQuery(),
///   timeout: Duration(seconds: 30),
/// );
/// ```
class Bulkhead {
  /// Creates a bulkhead with specified pool and queue sizes.
  ///
  /// The [poolSize] parameter sets the number of independent execution
  /// pools. The [queueSize] parameter sets the maximum queue size per
  /// pool. Each pool operates independently with its own semaphore,
  /// allowing [poolSize] concurrent executions across all pools.
  /// Executions are distributed using round-robin selection.
  ///
  /// Example:
  /// ```dart
  /// final bulkhead = Bulkhead(
  ///   poolSize: 3,
  ///   queueSize: 100,
  /// );
  /// ```
  Bulkhead({
    required this.poolSize,
    required this.queueSize,
  }) {
    if (poolSize <= 0) {
      throw ArgumentError.value(poolSize, 'poolSize', 'must be positive');
    }
    if (queueSize <= 0) {
      throw ArgumentError.value(queueSize, 'queueSize', 'must be positive');
    }

    for (var i = 0; i < poolSize; i++) {
      _semaphores.add(
        Semaphore(maxConcurrent: 1, maxQueueSize: queueSize),
      );
    }
  }

  /// Number of independent execution pools.
  ///
  /// Each pool can handle one concurrent execution. Total system
  /// capacity equals [poolSize]. This value remains constant.
  final int poolSize;

  /// Maximum queue size per individual pool.
  ///
  /// When a pool's queue exceeds this size, new executions fail.
  /// Each pool maintains its own independent queue.
  final int queueSize;

  final _semaphores = <Semaphore>[];
  int _nextSemaphore = 0;

  /// Executes a function in an isolated resource pool.
  ///
  /// Selects an execution pool using round-robin distribution and
  /// executes the provided [fn] function within that pool. The
  /// optional [timeout] parameter limits the maximum wait time to
  /// acquire pool access. Blocks until a pool slot becomes available
  /// or timeout expires. Each pool processes one execution at a time.
  ///
  /// Returns the result of executing [fn].
  ///
  /// Throws:
  /// - [TimeoutException] when timeout expires before pool access
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final result = await bulkhead.execute(
  ///     () async => await apiCall(),
  ///     timeout: Duration(seconds: 5),
  ///   );
  /// } catch (e) {
  ///   print('Execution failed: $e');
  /// }
  /// ```
  Future<R> execute<R>(AsyncFunction<R> fn, {Duration? timeout}) async {
    final semaphore = _selectSemaphore();
    await semaphore.acquire(timeout: timeout);
    try {
      return await fn();
    } finally {
      semaphore.release();
    }
  }

  Semaphore _selectSemaphore() {
    // Round-robin selection
    final semaphore = _semaphores[_nextSemaphore];
    _nextSemaphore = (_nextSemaphore + 1) % poolSize;
    return semaphore;
  }
}

/// Applies bulkhead isolation to no-parameter functions.
///
/// Wraps a [Func] to execute within isolated resource pools,
/// preventing cascading failures. The function automatically executes
/// in a pool selected by round-robin distribution. The [poolSize]
/// and [queueSize] configure the bulkhead capacity. The optional
/// [timeout] limits pool access wait time. The optional
/// [onIsolationFailure] callback handles pool access or execution
/// failures. The [instance] getter provides access to the underlying
/// bulkhead. This pattern is essential for isolating critical
/// operations and preventing resource exhaustion.
///
/// Example:
/// ```dart
/// final isolated = Func(() async => await apiCall())
///   .bulkhead(
///     poolSize: 4,
///     queueSize: 100,
///     timeout: Duration(seconds: 30),
///     onIsolationFailure: (e, s) => logger.error('Isolated', e),
///   );
/// ```
class BulkheadExtension<R> extends Func<R> {
  /// Creates a bulkhead extension for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [poolSize]
  /// and [queueSize] parameters configure the bulkhead resource
  /// pools. The optional [timeout] sets the maximum wait time for
  /// pool access. The optional [onIsolationFailure] callback is
  /// invoked when pool access fails or execution throws an exception.
  ///
  /// Example:
  /// ```dart
  /// final isolated = BulkheadExtension(
  ///   myFunc,
  ///   4,
  ///   100,
  ///   Duration(seconds: 10),
  ///   (e, s) => logger.error('Failed', e),
  /// );
  /// ```
  BulkheadExtension(
    this._inner,
    int poolSize,
    int queueSize,
    Duration? timeout,
    ErrorCallback? onIsolationFailure,
  ) : _engine = BulkheadEngine<R>(
        poolSize: poolSize,
        queueSize: queueSize,
        timeout: timeout,
        onIsolationFailure: onIsolationFailure,
      ),
      super(_inner.call);

  final Func<R> _inner;
  final BulkheadEngine<R> _engine;

  @override
  Future<R> call() => _engine.run(_inner.call);

  /// The bulkhead instance.
  ///
  /// Example:
  /// ```dart
  /// print('Pool size: ${isolatedFunc.instance.poolSize}');
  /// ```
  Bulkhead get instance => _engine.instance;
}

/// Applies bulkhead isolation to one-parameter functions.
///
/// Wraps a [Func1] to execute within isolated resource pools,
/// preventing cascading failures. The function automatically executes
/// in a pool selected by round-robin distribution. The [poolSize]
/// and [queueSize] configure the bulkhead capacity. The optional
/// [timeout] limits pool access wait time. The optional
/// [onIsolationFailure] callback handles pool access or execution
/// failures. The [instance] getter provides access to the underlying
/// bulkhead. This pattern is essential for isolating critical
/// operations and preventing resource exhaustion.
///
/// Example:
/// ```dart
/// final isolated = Func1<Task, Result>((task) async {
///   return await task.run();
/// }).bulkhead(
///   poolSize: 2,
///   queueSize: 50,
/// );
/// ```
class BulkheadExtension1<T, R> extends Func1<T, R> {
  /// Creates a bulkhead extension for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [poolSize]
  /// and [queueSize] parameters configure the bulkhead resource
  /// pools. The optional [timeout] sets the maximum wait time for
  /// pool access. The optional [onIsolationFailure] callback is
  /// invoked when pool access fails or execution throws an exception.
  ///
  /// Example:
  /// ```dart
  /// final isolated = BulkheadExtension1(
  ///   myFunc,
  ///   4,
  ///   100,
  ///   Duration(seconds: 10),
  ///   (e, s) => logger.error('Failed', e),
  /// );
  /// ```
  BulkheadExtension1(
    this._inner,
    int poolSize,
    int queueSize,
    Duration? timeout,
    ErrorCallback? onIsolationFailure,
  ) : _engine = BulkheadEngine<R>(
        poolSize: poolSize,
        queueSize: queueSize,
        timeout: timeout,
        onIsolationFailure: onIsolationFailure,
      ),
      super(_inner.call);

  final Func1<T, R> _inner;
  final BulkheadEngine<R> _engine;

  @override
  Future<R> call(T arg) => _engine.run(() => _inner(arg));

  /// The bulkhead instance.
  ///
  /// Example:
  /// ```dart
  /// print('Pool size: ${isolatedFunc.instance.poolSize}');
  /// ```
  Bulkhead get instance => _engine.instance;
}

/// Applies bulkhead isolation to two-parameter functions.
///
/// Wraps a [Func2] to execute within isolated resource pools,
/// preventing cascading failures. The function automatically executes
/// in a pool selected by round-robin distribution. The [poolSize]
/// and [queueSize] configure the bulkhead capacity. The optional
/// [timeout] limits pool access wait time. The optional
/// [onIsolationFailure] callback handles pool access or execution
/// failures. The [instance] getter provides access to the underlying
/// bulkhead. This pattern is essential for isolating critical
/// operations and preventing resource exhaustion.
///
/// Example:
/// ```dart
/// final isolated = Func2<String, Data, void>((id, data) async {
///   await db.update(id, data);
/// }).bulkhead(
///   poolSize: 2,
///   queueSize: 50,
/// );
/// ```
class BulkheadExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a bulkhead extension for a two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [poolSize]
  /// and [queueSize] parameters configure the bulkhead resource
  /// pools. The optional [timeout] sets the maximum wait time for
  /// pool access. The optional [onIsolationFailure] callback is
  /// invoked when pool access fails or execution throws an exception.
  ///
  /// Example:
  /// ```dart
  /// final isolated = BulkheadExtension2(
  ///   myFunc,
  ///   4,
  ///   100,
  ///   Duration(seconds: 10),
  ///   (e, s) => logger.error('Failed', e),
  /// );
  /// ```
  BulkheadExtension2(
    this._inner,
    int poolSize,
    int queueSize,
    Duration? timeout,
    ErrorCallback? onIsolationFailure,
  ) : _engine = BulkheadEngine<R>(
        poolSize: poolSize,
        queueSize: queueSize,
        timeout: timeout,
        onIsolationFailure: onIsolationFailure,
      ),
      super(_inner.call);

  final Func2<T1, T2, R> _inner;
  final BulkheadEngine<R> _engine;

  @override
  Future<R> call(T1 arg1, T2 arg2) =>
      _engine.run(() => _inner(arg1, arg2));

  /// The bulkhead instance.
  ///
  /// Example:
  /// ```dart
  /// print('Pool size: ${isolatedFunc.instance.poolSize}');
  /// ```
  Bulkhead get instance => _engine.instance;
}
