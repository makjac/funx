/// CountdownLatch mechanism for waiting on multiple operations.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// A countdown latch for coordinating multiple operations.
///
/// Example:
/// ```dart
/// final latch = CountdownLatch(count: 3);
/// worker1().then((_) => latch.countDown());
/// worker2().then((_) => latch.countDown());
/// worker3().then((_) => latch.countDown());
/// await latch.await_();
/// ```
class CountdownLatch {
  /// Creates a countdown latch with the specified count.
  CountdownLatch({
    required int count,
    this.onComplete,
  }) : _count = count;

  /// Creates a countdown latch with the specified count.
  ///
  /// Example:
  /// ```dart
  /// final latch = CountdownLatch(count: 5);
  /// ```
  /// Callback executed when count reaches zero.
  final void Function()? onComplete;

  int _count;

  final _waiters = <Completer<void>>[];

  /// Decrements the count.
  ///
  /// Example:
  /// ```dart
  /// latch.countDown();
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

  /// Wait until the count reaches zero.
  ///
  /// Example:
  /// ```dart
  /// final completed = await latch.await_(timeout: Duration(seconds: 10));
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

  /// Current count value.
  ///
  /// Example:
  /// ```dart
  /// print('Remaining: ${latch.count}');
  /// ```
  int get count => _count;

  /// Whether the latch has completed (count reached zero).
  ///
  /// Example:
  /// ```dart
  /// if (latch.isComplete) {
  ///   print('All operations completed');
  /// }
  /// ```
  bool get isComplete => _count == 0;
}

/// Applies countdown latch to a [Func].
///
/// Example:
/// ```dart
/// final latch = CountdownLatch(count: 3);
/// final task = Func(() async => await doWork())
///   .countdownLatch(latch);
/// ```
class CountdownLatchExtension<R> extends Func<R> {
  /// Creates a countdown latch extension for a function.
  ///
  /// Example:
  /// ```dart
  /// final counted = CountdownLatchExtension(myFunc, latch);
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

  /// The countdown latch instance.
  ///
  /// Example:
  /// ```dart
  /// print('Remaining: ${taskFunc.latch.count}');
  /// ```
  CountdownLatch get latch => _latch;
}

/// Applies countdown latch to a [Func1].
///
/// Example:
/// ```dart
/// final latch = CountdownLatch(count: 2);
/// final process = Func1<Data, Result>((data) async => await data.process())
///   .countdownLatch(latch);
/// ```
class CountdownLatchExtension1<T, R> extends Func1<T, R> {
  /// Creates a countdown latch extension for a single-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final counted = CountdownLatchExtension1(myFunc, latch);
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

  /// The countdown latch instance.
  ///
  /// Example:
  /// ```dart
  /// print('Remaining: ${processFunc.latch.count}');
  /// ```
  CountdownLatch get latch => _latch;
}

/// Applies countdown latch to a [Func2].
///
/// Example:
/// ```dart
/// final latch = CountdownLatch(count: 4);
/// final merge = Func2<String, String, String>((a, b) async => a + b)
///   .countdownLatch(latch);
/// ```
class CountdownLatchExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a countdown latch extension for a two-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final counted = CountdownLatchExtension2(myFunc, latch);
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

  /// The countdown latch instance.
  ///
  /// Example:
  /// ```dart
  /// print('Remaining: ${mergeFunc.latch.count}');
  /// ```
  CountdownLatch get latch => _latch;
}
