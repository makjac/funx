/// Barrier mechanism for multi-party synchronization.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/core/types.dart';

/// Synchronization barrier for coordinating multiple parties.
///
/// Blocks execution until a specified number of [parties] arrive at
/// the barrier point. When all parties arrive, an optional
/// [barrierAction] is executed before releasing all waiters. The
/// [cyclic] flag determines whether the barrier resets automatically
/// for reuse. The optional [timeout] and [onTimeout] provide timeout
/// handling when parties fail to arrive. This pattern is essential
/// for coordinating concurrent operations that must synchronize at
/// specific points, such as parallel algorithms or multi-stage
/// workflows.
///
/// Example:
/// ```dart
/// final barrier = Barrier(
///   parties: 3,
///   cyclic: true,
///   barrierAction: () => print('All arrived!'),
///   timeout: Duration(seconds: 10),
/// );
///
/// await Future.wait([
///   worker1().then((_) => barrier.await_()),
///   worker2().then((_) => barrier.await_()),
///   worker3().then((_) => barrier.await_()),
/// ]);
/// ```
class Barrier {
  /// Creates a synchronization barrier with specified configuration.
  ///
  /// The [parties] parameter sets the number of waiters required
  /// before the barrier releases. The optional [cyclic] flag (defaults
  /// to false) determines whether the barrier resets automatically
  /// after release, allowing reuse. The optional [barrierAction]
  /// callback executes when all parties arrive, before releasing
  /// waiters. The optional [timeout] sets the maximum wait duration,
  /// and [onTimeout] is called when timeout occurs.
  ///
  /// Example:
  /// ```dart
  /// final barrier = Barrier(
  ///   parties: 5,
  ///   cyclic: true,
  ///   barrierAction: () => logger.info('Phase complete'),
  ///   timeout: Duration(seconds: 30),
  ///   onTimeout: () => logger.warn('Barrier timeout'),
  /// );
  /// ```
  Barrier({
    required this.parties,
    this.cyclic = false,
    this.barrierAction,
    this.timeout,
    this.onTimeout,
  });

  /// Number of parties required to release the barrier.
  ///
  /// All parties must call [await_] before the barrier releases.
  /// This value remains constant throughout the barrier's lifetime.
  final int parties;

  /// Whether the barrier resets automatically after release.
  ///
  /// When true, the barrier resets to its initial state after all
  /// parties arrive, allowing it to be reused. When false, the
  /// barrier becomes broken after first release and cannot be reused
  /// without calling [reset].
  final bool cyclic;

  /// Optional action executed when all parties arrive.
  ///
  /// Called after all parties reach the barrier but before releasing
  /// waiters. Executes only once per barrier trip. Use this for
  /// synchronization checkpoints or phase transitions.
  final BarrierAction? barrierAction;

  /// Optional maximum wait duration at the barrier.
  ///
  /// When set, parties waiting longer than this duration will receive
  /// a [TimeoutException]. When null, parties wait indefinitely.
  final Duration? timeout;

  /// Optional callback invoked when timeout occurs.
  ///
  /// Called after timeout expires but before throwing
  /// [TimeoutException]. Use this for logging or cleanup operations.
  final TimeoutCallback? onTimeout;

  int _arrived = 0;
  final _waiters = <Completer<void>>[];
  bool _broken = false;

  /// Waits at the barrier until all parties arrive.
  ///
  /// Blocks execution until [parties] number of waiters call this
  /// method. When the last party arrives, [barrierAction] is executed
  /// (if set) and all waiters are released simultaneously. If [cyclic]
  /// is true, the barrier resets automatically for reuse. If [timeout]
  /// is set and expires, throws [TimeoutException] and marks the
  /// barrier as broken.
  ///
  /// Throws:
  /// - [StateError] if the barrier is already broken
  /// - [TimeoutException] if timeout expires before all parties arrive
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await barrier.await_();
  ///   print('All parties synchronized');
  /// } catch (e) {
  ///   if (e is TimeoutException) {
  ///     print('Barrier timeout');
  ///   }
  /// }
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

  /// Resets the barrier to its initial state.
  ///
  /// Clears all waiting parties, resets the arrived count to zero,
  /// and marks the barrier as not broken. Use this to manually reset
  /// a non-cyclic barrier or to recover from a broken state.
  ///
  /// Example:
  /// ```dart
  /// if (barrier.isBroken) {
  ///   barrier.reset();
  ///   print('Barrier reset and ready for reuse');
  /// }
  /// ```
  void reset() {
    _arrived = 0;
    _broken = false;
    _waiters.clear();
  }

  /// Number of parties currently waiting at the barrier.
  ///
  /// Returns the count of parties that have called [await_] but are
  /// still blocked, waiting for all parties to arrive. Resets to zero
  /// after barrier release or [reset] call.
  ///
  /// Example:
  /// ```dart
  /// print('Waiting: ${barrier.arrivedCount}/${barrier.parties}');
  /// if (barrier.arrivedCount == barrier.parties - 1) {
  ///   print('One more party needed');
  /// }
  /// ```
  int get arrivedCount => _arrived;

  /// Whether the barrier is in a broken state.
  ///
  /// Returns true if the barrier has been broken by timeout or manual
  /// release. A broken barrier rejects all [await_] calls with
  /// [StateError]. Non-cyclic barriers become broken after first
  /// release. Call [reset] to recover from broken state.
  ///
  /// Example:
  /// ```dart
  /// if (barrier.isBroken) {
  ///   print('Barrier is broken, resetting...');
  ///   barrier.reset();
  /// }
  /// ```
  bool get isBroken => _broken;
}

/// Applies barrier synchronization to no-parameter functions.
///
/// Wraps a [Func] to automatically wait at a barrier after execution.
/// The wrapped function executes normally, then waits at the provided
/// [_barrier] before returning. This ensures all wrapped functions
/// synchronize at the barrier point after completing their work. The
/// [instance] getter provides access to the barrier for monitoring.
/// This pattern is essential for coordinating parallel tasks that must
/// synchronize at specific checkpoints.
///
/// Example:
/// ```dart
/// final barrier = Barrier(parties: 3);
/// final worker1 = Func(() async => await task1()).barrier(barrier);
/// final worker2 = Func(() async => await task2()).barrier(barrier);
/// final worker3 = Func(() async => await task3()).barrier(barrier);
///
/// await Future.wait([worker1(), worker2(), worker3()]);
/// print('All workers synchronized');
/// ```
class BarrierExtension<R> extends Func<R> {
  /// Creates a barrier extension for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [_barrier]
  /// parameter is the barrier where the function will wait after
  /// execution. The function executes normally, then calls
  /// [Barrier.await_] before returning.
  ///
  /// Example:
  /// ```dart
  /// final barrier = Barrier(parties: 2);
  /// final synced = BarrierExtension(
  ///   Func(() async => await compute()),
  ///   barrier,
  /// );
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

  /// The barrier instance used for synchronization.
  ///
  /// Provides access to the underlying barrier for monitoring state,
  /// checking arrived count, or manually resetting.
  ///
  /// Example:
  /// ```dart
  /// print('Progress: ${workerFunc.instance.arrivedCount}');
  /// if (workerFunc.instance.isBroken) {
  ///   workerFunc.instance.reset();
  /// }
  /// ```
  Barrier get instance => _barrier;
}

/// Applies barrier synchronization to one-parameter functions.
///
/// Wraps a [Func1] to automatically wait at a barrier after
/// execution. The wrapped function executes normally with its
/// parameter, then waits at the provided [_barrier] before returning.
/// This ensures all wrapped functions synchronize at the barrier
/// point after completing their work. The [instance] getter provides
/// access to the barrier for monitoring. This pattern is essential
/// for coordinating parallel tasks that must synchronize at specific
/// checkpoints.
///
/// Example:
/// ```dart
/// final barrier = Barrier(parties: 4);
/// final process = Func1<int, String>((n) async {
///   return await compute(n);
/// }).barrier(barrier);
///
/// await Future.wait([
///   process(1), process(2), process(3), process(4),
/// ]);
/// ```
class BarrierExtension1<T, R> extends Func1<T, R> {
  /// Creates a barrier extension for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [_barrier]
  /// parameter is the barrier where the function will wait after
  /// execution. The function executes normally with its parameter,
  /// then calls [Barrier.await_] before returning.
  ///
  /// Example:
  /// ```dart
  /// final barrier = Barrier(parties: 3);
  /// final synced = BarrierExtension1(
  ///   Func1<int, String>((n) async => 'Result $n'),
  ///   barrier,
  /// );
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

  /// The barrier instance used for synchronization.
  ///
  /// Provides access to the underlying barrier for monitoring state,
  /// checking arrived count, or manually resetting.
  ///
  /// Example:
  /// ```dart
  /// print('Progress: ${processFunc.instance.arrivedCount}');
  /// if (processFunc.instance.isBroken) {
  ///   processFunc.instance.reset();
  /// }
  /// ```
  Barrier get instance => _barrier;
}

/// Applies barrier synchronization to two-parameter functions.ter functions.
///
/// Wraps a [Func2] to automatically wait at a barrier after
/// execution. The wrapped function executes normally with its
/// parameters, then waits at the provided [_barrier] before
/// returning. This ensures all wrapped functions synchronize at the
/// barrier point after completing their work. The [instance] getter
/// provides access to the barrier for monitoring. This pattern is
/// essential for coordinating parallel tasks that must synchronize
/// at specific checkpoints.
///
/// Example:
/// ```dart
/// final barrier = Barrier(parties: 2);
/// final combine = Func2<int, int, int>((a, b) async {
///   return await compute(a, b);
/// }).barrier(barrier);
///
/// await Future.wait([combine(1, 2), combine(3, 4)]);
/// ```
class BarrierExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a barrier extension for a two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [_barrier]
  /// parameter is the barrier where the function will wait after
  /// execution. The function executes normally with its parameters,
  /// then calls [Barrier.await_] before returning.
  ///
  /// Example:
  /// ```dart
  /// final barrier = Barrier(parties: 2);
  /// final synced = BarrierExtension2(
  ///   Func2<int, int, int>((a, b) async => a + b),
  ///   barrier,
  /// );
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

  /// The barrier instance used for synchronization.
  ///
  /// Provides access to the underlying barrier for monitoring state,
  /// checking arrived count, or manually resetting.
  ///
  /// Example:
  /// ```dart
  /// print('Progress: ${combineFunc.instance.arrivedCount}');
  /// if (combineFunc.instance.isBroken) {
  ///   combineFunc.instance.reset();
  /// }
  /// ```
  Barrier get instance => _barrier;
}
