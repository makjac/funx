/// Bulkhead mechanism for resource isolation.
library;

import 'dart:async';

import 'package:funx/src/concurrency/semaphore.dart';
import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// A bulkhead for isolating executions in separate resource pools.
///
/// Example:
/// ```dart
/// final bulkhead = Bulkhead(poolSize: 4);
/// final result = await bulkhead.execute(() async => await operation());
/// ```
class Bulkhead {
  /// Creates a bulkhead with the specified pool size.
  ///
  /// Example:
  /// ```dart
  /// final bulkhead = Bulkhead(poolSize: 3, queueSize: 100);
  /// ```
  Bulkhead({
    required this.poolSize,
    required this.queueSize,
  }) {
    for (var i = 0; i < poolSize; i++) {
      _semaphores.add(Semaphore(maxConcurrent: 1));
    }
  }

  /// Number of isolated pools.
  final int poolSize;

  /// Maximum queue size per pool.
  final int queueSize;

  final _semaphores = <Semaphore>[];
  int _nextSemaphore = 0;

  /// Executes a function in an isolated pool.
  ///
  /// Example:
  /// ```dart
  /// final result = await bulkhead.execute(
  ///   () async => await heavyOperation(),
  ///   timeout: Duration(minutes: 5),
  /// );
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

/// Applies bulkhead isolation to a [Func].
///
/// Example:
/// ```dart
/// final isolated = Func(() async => await heavyTask())
///   .bulkhead(poolSize: 4, queueSize: 100);
/// ```
class BulkheadExtension<R> extends Func<R> {
  /// Creates a bulkhead extension for a function.
  ///
  /// Example:
  /// ```dart
  /// final isolated = BulkheadExtension(myFunc, 4, 100, null, null);
  /// ```
  BulkheadExtension(
    this._inner,
    this._poolSize,
    this._queueSize,
    this._timeout,
    this._onIsolationFailure,
  ) : super(_inner.call) {
    _bulkhead = Bulkhead(
      poolSize: _poolSize,
      queueSize: _queueSize,
    );
  }

  final Func<R> _inner;
  final int _poolSize;
  final int _queueSize;
  final Duration? _timeout;
  final ErrorCallback? _onIsolationFailure;

  late final Bulkhead _bulkhead;

  @override
  Future<R> call() async {
    try {
      return await _bulkhead.execute(
        _inner.call,
        timeout: _timeout,
      );
    } catch (error, stackTrace) {
      _onIsolationFailure?.call(error, stackTrace);
      rethrow;
    }
  }

  /// The bulkhead instance.
  ///
  /// Example:
  /// ```dart
  /// print('Pool size: ${isolatedFunc.instance.poolSize}');
  /// ```
  Bulkhead get instance => _bulkhead;
}

/// Applies bulkhead isolation to a [Func1].
///
/// Example:
/// ```dart
/// final isolated = Func1<Task, Result>((task) async => await task.run())
///   .bulkhead(poolSize: 2);
/// ```
class BulkheadExtension1<T, R> extends Func1<T, R> {
  /// Creates a bulkhead extension for a single-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final isolated = BulkheadExtension1(myFunc, 4, 100, null, null);
  /// ```
  BulkheadExtension1(
    this._inner,
    this._poolSize,
    this._queueSize,
    this._timeout,
    this._onIsolationFailure,
  ) : super(_inner.call) {
    _bulkhead = Bulkhead(
      poolSize: _poolSize,
      queueSize: _queueSize,
    );
  }

  final Func1<T, R> _inner;
  final int _poolSize;
  final int _queueSize;
  final Duration? _timeout;
  final ErrorCallback? _onIsolationFailure;

  late final Bulkhead _bulkhead;

  @override
  Future<R> call(T arg) async {
    try {
      return await _bulkhead.execute(
        () => _inner(arg),
        timeout: _timeout,
      );
    } catch (error, stackTrace) {
      _onIsolationFailure?.call(error, stackTrace);
      rethrow;
    }
  }

  /// The bulkhead instance.
  ///
  /// Example:
  /// ```dart
  /// print('Pool size: ${isolatedFunc.instance.poolSize}');
  /// ```
  Bulkhead get instance => _bulkhead;
}

/// Applies bulkhead isolation to a [Func2].
///
/// Example:
/// ```dart
/// final isolated = Func2<String, Data, Result>((id, data) async {
///   return await process(id, data);
/// }).bulkhead(poolSize: 3);
/// ```
class BulkheadExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a bulkhead extension for a two-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final isolated = BulkheadExtension2(myFunc, 4, 100, null, null);
  /// ```
  BulkheadExtension2(
    this._inner,
    this._poolSize,
    this._queueSize,
    this._timeout,
    this._onIsolationFailure,
  ) : super(_inner.call) {
    _bulkhead = Bulkhead(
      poolSize: _poolSize,
      queueSize: _queueSize,
    );
  }

  final Func2<T1, T2, R> _inner;
  final int _poolSize;
  final int _queueSize;
  final Duration? _timeout;
  final ErrorCallback? _onIsolationFailure;

  late final Bulkhead _bulkhead;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    try {
      return await _bulkhead.execute(
        () => _inner(arg1, arg2),
        timeout: _timeout,
      );
    } catch (error, stackTrace) {
      _onIsolationFailure?.call(error, stackTrace);
      rethrow;
    }
  }

  /// The bulkhead instance.
  ///
  /// Example:
  /// ```dart
  /// print('Pool size: ${isolatedFunc.instance.poolSize}');
  /// ```
  Bulkhead get instance => _bulkhead;
}
