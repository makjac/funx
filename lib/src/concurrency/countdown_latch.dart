/// CountdownLatch mechanism for waiting on multiple operations.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Synchronization mechanism for waiting on multiple operations.
///
/// Blocks execution until a specified number of operations complete.
/// Initializes with a [count] value that decrements via [countDown]
/// calls. When count reaches zero, all waiting parties are released
/// and the optional [onComplete] callback executes. Unlike barriers,
/// countdown latches are single-use and do not reset automatically.
/// This pattern is essential for coordinating startup sequences,
/// parallel initialization, or waiting for multiple async operations
/// to complete before proceeding.
///
/// Example:
/// ```dart
/// final latch = CountdownLatch(
///   count: 3,
///   onComplete: () => print('All workers finished'),
/// );
///
/// worker1().then((_) => latch.countDown());
/// worker2().then((_) => latch.countDown());
/// worker3().then((_) => latch.countDown());
///
/// await latch.await_();
/// print('Proceeding with all workers complete');
/// ```
class CountdownLatch {
  /// Creates a countdown latch with specified initial count.
  ///
  /// The [count] parameter sets the number of [countDown] calls
  /// required before releasing waiters. Must be a positive integer.
  /// The optional [onComplete] callback executes when the count
  /// reaches zero, before releasing waiters. The latch is single-use
  /// and does not reset after completion.
  ///
  /// Example:
  /// ```dart
  /// final latch = CountdownLatch(
  ///   count: 5,
  ///   onComplete: () => logger.info('All tasks complete'),
  /// );
  /// ```
  CountdownLatch({
    required int count,
    this.onComplete,
  }) : _count = count;

  /// Optional callback executed when count reaches zero.
  ///
  /// Invoked after the last [countDown] call but before releasing
  /// waiters. Use this for cleanup, logging, or signaling completion.
  final void Function()? onComplete;

  int _count;

  final _waiters = <Completer<void>>[];

  /// Decrements the latch count by one.
  ///
  /// Reduces the internal count. When count reaches zero, executes
  /// [onComplete] callback (if set) and releases all waiting parties.
  /// Subsequent calls after reaching zero throw [StateError].
  ///
  /// Throws:
  /// - [StateError] if count is already zero
  ///
  /// Example:
  /// ```dart
  /// await task();
  /// latch.countDown();
  /// print('Task completed, count: ${latch.count}');
  /// ```
  void countDown() {
    if (_count <= 0) {
      throw StateError('CountdownLatch already at zero');
    }

    _count--;

    if (_count == 0) {
      onComplete?.call();

      // Release all waiters
      for (final completer in _waiters) {
        completer.complete();
      }
      _waiters.clear();
    }
  }

  /// Waits until the count reaches zero.
  ///
  /// Blocks execution until all required [countDown] calls complete.
  /// Returns immediately if count is already zero. The optional
  /// [timeout] parameter limits the maximum wait duration. Returns
  /// true if latch completed, false if timeout expired.
  ///
  /// Returns true when count reaches zero, false on timeout.
  ///
  /// Example:
  /// ```dart
  /// final completed = await latch.await_(
  ///   timeout: Duration(seconds: 10),
  /// );
  /// if (completed) {
  ///   print('All operations finished');
  /// } else {
  ///   print('Timeout waiting for operations');
  /// }
  /// ```
  Future<bool> await_({Duration? timeout}) async {
    if (_count == 0) {
      return true;
    }

    final completer = Completer<void>();
    _waiters.add(completer);

    if (timeout != null) {
      try {
        await completer.future.timeout(timeout);
        return true;
      } on TimeoutException {
        _waiters.remove(completer);
        return false;
      }
    } else {
      await completer.future;
      return true;
    }
  }

  /// Current remaining count value.
  ///
  /// Returns the number of [countDown] calls remaining before the
  /// latch releases waiters. Zero indicates completion.
  ///
  /// Example:
  /// ```dart
  /// print('Remaining operations: ${latch.count}');
  /// if (latch.count == 1) {
  ///   print('One operation left');
  /// }
  /// ```
  int get count => _count;

  /// Whether the latch has completed.
  ///
  /// Returns true when count reaches zero. Once complete, the latch
  /// cannot be reused.
  ///
  /// Example:
  /// ```dart
  /// if (latch.isComplete) {
  ///   print('All operations completed');
  /// }
  /// ```
  bool get isComplete => _count == 0;
}

/// Applies countdown latch to no-parameter functions.
///
/// Wraps a [Func] to automatically decrement a countdown latch after
/// execution. The function executes normally, then calls
/// [CountdownLatch.countDown] on the provided [_latch] before returning. This
/// ensures the latch tracks function completion. The [latch] getter provides
/// access to the underlying latch for monitoring. This pattern is essential for
///  coordinating parallel operations where each must signal completion.
///
/// Example:
/// ```dart
/// final latch = CountdownLatch(count: 3);
/// final task1 = Func(() async => await work1()).countdownLatch(latch);
/// final task2 = Func(() async => await work2()).countdownLatch(latch);
/// final task3 = Func(() async => await work3()).countdownLatch(latch);
///
/// await Future.wait([task1(), task2(), task3()]);
/// await latch.await_();
/// ```
class CountdownLatchExtension<R> extends Func<R> {
  /// Creates a countdown latch extension for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [_latch]
  /// parameter is the countdown latch to decrement after execution.
  /// The function executes normally, then calls [CountdownLatch.countDown]
  /// before returning the result.
  ///
  /// Example:
  /// ```dart
  /// final latch = CountdownLatch(count: 2);
  /// final counted = CountdownLatchExtension(
  ///   Func(() async => await compute()),
  ///   latch,
  /// );
  /// ```
  CountdownLatchExtension(
    this._inner,
    this._latch,
  ) : super(_inner.call);

  final Func<R> _inner;
  final CountdownLatch _latch;

  @override
  Future<R> call() async {
    final result = await _inner();
    _latch.countDown();
    return result;
  }

  /// The underlying countdown latch instance.
  ///
  /// Provides access to the latch for checking completion status or
  /// remaining count.
  ///
  /// Example:
  /// ```dart
  /// print('Remaining: ${taskFunc.latch.count}');
  /// if (taskFunc.latch.isComplete) {
  ///   print('All tasks finished');
  /// }
  /// ```
  CountdownLatch get latch => _latch;
}

/// Applies countdown latch to one-parameter functions.
///
/// Wraps a [Func1] to automatically decrement a countdown latch after
/// execution. The function executes normally with its parameter, then
/// calls [CountdownLatch.countDown] on the provided [_latch] before returning.
/// This ensures the latch tracks function completion. The [latch] getter
/// provides access to the underlying latch for monitoring. This
/// pattern is essential for coordinating parallel operations where
/// each must signal completion.
///
/// Example:
/// ```dart
/// final latch = CountdownLatch(count: 4);
/// final process = Func1<Data, Result>((data) async {
///   return await data.process();
/// }).countdownLatch(latch);
///
/// await Future.wait(items.map((item) => process(item)));
/// await latch.await_();
/// ```
class CountdownLatchExtension1<T, R> extends Func1<T, R> {
  /// Creates a countdown latch extension for one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [_latch]
  /// parameter is the countdown latch to decrement after execution.
  /// The function executes normally with its parameter, then calls
  /// [CountdownLatch.countDown] before returning the result.
  ///
  /// Example:
  /// ```dart
  /// final latch = CountdownLatch(count: 3);
  /// final counted = CountdownLatchExtension1(
  ///   Func1<int, String>((n) async => 'Result $n'),
  ///   latch,
  /// );
  /// ```
  CountdownLatchExtension1(
    this._inner,
    this._latch,
  ) : super(_inner.call);

  final Func1<T, R> _inner;
  final CountdownLatch _latch;

  @override
  Future<R> call(T arg) async {
    final result = await _inner(arg);
    _latch.countDown();
    return result;
  }

  /// The underlying countdown latch instance.
  ///
  /// Provides access to the latch for checking completion status or
  /// remaining count.
  ///
  /// Example:
  /// ```dart
  /// print('Remaining: ${processFunc.latch.count}');
  /// if (processFunc.latch.isComplete) {
  ///   print('All processes finished');
  /// }
  /// ```
  CountdownLatch get latch => _latch;
}

/// Applies countdown latch to two-parameter functions.
///
/// Wraps a [Func2] to automatically decrement a countdown latch after
/// execution. The function executes normally with its parameters,
/// then calls [CountdownLatch.countDown] on the provided [_latch] before
/// returning. This ensures the latch tracks function completion. The [latch]
/// getter provides access to the underlying latch for monitoring.
/// This pattern is essential for coordinating parallel operations
/// where each must signal completion.
///
/// Example:
/// ```dart
/// final latch = CountdownLatch(count: 2);
/// final merge = Func2<String, String, String>((a, b) async {
///   return await combine(a, b);
/// }).countdownLatch(latch);
///
/// await Future.wait([merge('x', 'y'), merge('p', 'q')]);
/// await latch.await_();
/// ```
class CountdownLatchExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a countdown latch extension for two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [_latch]
  /// parameter is the countdown latch to decrement after execution.
  /// The function executes normally with its parameters, then calls
  /// [CountdownLatch.countDown] before returning the result.
  ///
  /// Example:
  /// ```dart
  /// final latch = CountdownLatch(count: 2);
  /// final counted = CountdownLatchExtension2(
  ///   Func2<int, int, int>((a, b) async => a + b),
  ///   latch,
  /// );
  /// ```
  CountdownLatchExtension2(
    this._inner,
    this._latch,
  ) : super(_inner.call);

  final Func2<T1, T2, R> _inner;
  final CountdownLatch _latch;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final result = await _inner(arg1, arg2);
    _latch.countDown();
    return result;
  }

  /// The underlying countdown latch instance.
  ///
  /// Provides access to the latch for checking completion status or
  /// remaining count.
  ///
  /// Example:
  /// ```dart
  /// print('Remaining: ${mergeFunc.latch.count}');
  /// if (mergeFunc.latch.isComplete) {
  ///   print('All merges finished');
  /// }
  /// ```
  CountdownLatch get latch => _latch;
}
