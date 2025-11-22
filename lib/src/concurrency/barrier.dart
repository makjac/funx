/// Barrier mechanism for multi-party synchronization.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// A synchronization barrier for coordinating multiple parties.
///
/// Example:
/// ```dart
/// final barrier = Barrier(
///   parties: 3,
///   barrierAction: () => print('All arrived!'),
/// );
///
/// await barrier.await_();
/// ```
class Barrier {
  /// Creates a barrier with the specified number of parties.
  ///
  /// Example:
  /// ```dart
  /// final barrier = Barrier(parties: 5, cyclic: true);
  /// ```
  Barrier({
    required this.parties,
    this.cyclic = false,
    this.barrierAction,
    this.timeout,
    this.onTimeout,
  });

  /// Number of parties that must call await before barrier is released.
  final int parties;

  /// Whether the barrier resets after each release.
  final bool cyclic;

  /// Action to execute when all parties arrive.
  final BarrierAction? barrierAction;

  /// Timeout for waiting at barrier.
  final Duration? timeout;

  /// Callback when timeout occurs.
  final TimeoutCallback? onTimeout;

  int _arrived = 0;
  final _waiters = <Completer<void>>[];
  bool _broken = false;

  /// Wait at the barrier until all parties arrive.
  ///
  /// Example:
  /// ```dart
  /// await barrier.await_();
  /// ```
  Future<void> await_() async {
    if (_broken) {
      throw StateError('Barrier is broken');
    }

    _arrived++;

    if (_arrived == parties) {
      // All parties arrived
      await barrierAction?.call();

      // Release all waiters
      for (final completer in _waiters) {
        completer.complete();
      }
      _waiters.clear();

      // Reset if cyclic
      if (cyclic) {
        _arrived = 0;
      } else {
        _broken = true;
      }
    } else {
      // Wait for others
      final completer = Completer<void>();
      _waiters.add(completer);

      if (timeout != null) {
        try {
          await completer.future.timeout(timeout!);
        } on TimeoutException {
          _broken = true;
          onTimeout?.call();

          // Cancel all waiters
          for (final w in _waiters) {
            if (!w.isCompleted) {
              w.completeError(TimeoutException('Barrier timeout'));
            }
          }
          _waiters.clear();
          _arrived = 0;

          rethrow;
        }
      } else {
        await completer.future;
      }
    }
  }

  /// Reset the barrier to its initial state.
  ///
  /// Example:
  /// ```dart
  /// barrier.reset();
  /// ```
  void reset() {
    _arrived = 0;
    _broken = false;
    _waiters.clear();
  }

  /// Number of parties that have arrived at the barrier.
  ///
  /// Example:
  /// ```dart
  /// print('Arrived: ${barrier.arrivedCount}/${barrier.parties}');
  /// ```
  int get arrivedCount => _arrived;

  /// Whether the barrier is broken due to timeout or error.
  ///
  /// Example:
  /// ```dart
  /// if (barrier.isBroken) {
  ///   barrier.reset();
  /// }
  /// ```
  bool get isBroken => _broken;
}

/// Applies barrier synchronization to a [Func].
///
/// Example:
/// ```dart
/// final barrier = Barrier(parties: 3);
/// final worker = Func(() async => await doWork())
///   .barrier(barrier);
/// ```
class BarrierExtension<R> extends Func<R> {
  /// Creates a barrier extension for a function.
  ///
  /// Example:
  /// ```dart
  /// final synced = BarrierExtension(myFunc, barrier);
  /// ```
  BarrierExtension(
    this._inner,
    this._barrier,
  ) : super(_inner.call);

  final Func<R> _inner;
  final Barrier _barrier;

  @override
  Future<R> call() async {
    final result = await _inner();
    await _barrier.await_();
    return result;
  }

  /// The barrier instance.
  ///
  /// Example:
  /// ```dart
  /// print('Arrived: ${workerFunc.instance.arrivedCount}');
  /// ```
  Barrier get instance => _barrier;
}

/// Applies barrier synchronization to a [Func1].
///
/// Example:
/// ```dart
/// final barrier = Barrier(parties: 2);
/// final process = Func1<int, String>((n) async => 'Result $n')
///   .barrier(barrier);
/// ```
class BarrierExtension1<T, R> extends Func1<T, R> {
  /// Creates a barrier extension for a single-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final synced = BarrierExtension1(myFunc, barrier);
  /// ```
  BarrierExtension1(
    this._inner,
    this._barrier,
  ) : super(_inner.call);

  final Func1<T, R> _inner;
  final Barrier _barrier;

  @override
  Future<R> call(T arg) async {
    final result = await _inner(arg);
    await _barrier.await_();
    return result;
  }

  /// The barrier instance.
  ///
  /// Example:
  /// ```dart
  /// print('Arrived: ${processFunc.instance.arrivedCount}');
  /// ```
  Barrier get instance => _barrier;
}

/// Applies barrier synchronization to a [Func2].
///
/// Example:
/// ```dart
/// final barrier = Barrier(parties: 4);
/// final combine = Func2<int, int, int>((a, b) async => a + b)
///   .barrier(barrier);
/// ```
class BarrierExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a barrier extension for a two-parameter function.
  ///
  /// Example:
  /// ```dart
  /// final synced = BarrierExtension2(myFunc, barrier);
  /// ```
  BarrierExtension2(
    this._inner,
    this._barrier,
  ) : super(_inner.call);

  final Func2<T1, T2, R> _inner;
  final Barrier _barrier;

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    final result = await _inner(arg1, arg2);
    await _barrier.await_();
    return result;
  }

  /// The barrier instance.
  ///
  /// Example:
  /// ```dart
  /// print('Arrived: ${combineFunc.instance.arrivedCount}');
  /// ```
  Barrier get instance => _barrier;
}
