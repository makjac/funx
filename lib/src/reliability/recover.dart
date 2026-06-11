import 'dart:async';

import 'package:funx/src/core/func.dart';
import 'package:funx/src/reliability/_reliability_engines.dart';

export 'package:funx/src/reliability/_reliability_engines.dart'
    show RecoveryStrategy;

/// Applies error recovery to no-parameter functions.
///
/// Wraps [Func] to execute recovery actions when errors occur. The
/// [strategy] parameter defines recovery behavior including error
/// handling, filtering, and rethrow policy. Automatically invokes
/// recovery on matching errors. Useful for cleanup actions,
/// reconnection logic, logging failures, or switching to degraded
/// modes while preserving error propagation. This pattern ensures
/// proper resource cleanup and state management during failures.
///
/// Example:
/// ```dart
/// final func = Func<String>(() async {
///   return await unreliableService.getData();
/// });
///
/// final withRecovery = func.recover(
///   RecoveryStrategy(
///     onError: (e) async => await service.reconnect(),
///     shouldRecover: (e) => e is ConnectionException,
///   ),
/// );
/// ```
class RecoverExtension<R> extends Func<R> {
  /// Creates recovery wrapper for no-parameter function.
  ///
  /// The [_inner] parameter is function to wrap. The [strategy]
  /// parameter defines recovery behavior executed on errors.
  ///
  /// Example:
  /// ```dart
  /// final withRecovery = RecoverExtension(
  ///   myFunc,
  ///   RecoveryStrategy(onError: (e) async => cleanup()),
  /// );
  /// ```
  RecoverExtension(this._inner, RecoveryStrategy strategy)
    : _engine = RecoverEngine<R>(strategy),
      super(() => throw UnimplementedError());

  final Func<R> _inner;
  final RecoverEngine<R> _engine;

  @override
  Future<R> call() => _engine.run(_inner.call);
}

/// Applies error recovery to one-parameter functions.
///
/// Wraps [Func1] to execute recovery actions when errors occur. The
/// [strategy] parameter defines recovery behavior including error
/// handling, filtering, and rethrow policy. Automatically invokes
/// recovery on matching errors. Useful for cleanup actions,
/// reconnection logic, logging failures, or switching to degraded
/// modes while preserving error propagation. This pattern ensures
/// proper resource cleanup and state management during failures.
///
/// Example:
/// ```dart
/// final fetch = Func1<String, Data>((id) async {
///   return await api.fetch(id);
/// }).recover(
///   RecoveryStrategy(
///     onError: (e) async => await api.reset(),
///   ),
/// );
/// ```
class RecoverExtension1<T, R> extends Func1<T, R> {
  /// Creates recovery wrapper for one-parameter function.
  ///
  /// The [_inner] parameter is function to wrap. The [strategy]
  /// parameter defines recovery behavior executed on errors.
  ///
  /// Example:
  /// ```dart
  /// final withRecovery = RecoverExtension1(
  ///   myFunc,
  ///   RecoveryStrategy(onError: (e) async => cleanup()),
  /// );
  /// ```
  RecoverExtension1(this._inner, RecoveryStrategy strategy)
    : _engine = RecoverEngine<R>(strategy),
      super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;
  final RecoverEngine<R> _engine;

  @override
  Future<R> call(T arg) => _engine.run(() => _inner(arg));
}

/// Applies error recovery to two-parameter functions.
///
/// Wraps [Func2] to execute recovery actions when errors occur. The
/// [strategy] parameter defines recovery behavior including error
/// handling, filtering, and rethrow policy. Automatically invokes
/// recovery on matching errors. Useful for cleanup actions,
/// reconnection logic, logging failures, or switching to degraded
/// modes while preserving error propagation. This pattern ensures
/// proper resource cleanup and state management during failures.
///
/// Example:
/// ```dart
/// final update = Func2<String, Data, void>((id, data) async {
///   await db.update(id, data);
/// }).recover(
///   RecoveryStrategy(
///     onError: (e) async => await db.rollback(),
///   ),
/// );
/// ```
class RecoverExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates recovery wrapper for two-parameter function.
  ///
  /// The [_inner] parameter is function to wrap. The [strategy]
  /// parameter defines recovery behavior executed on errors.
  ///
  /// Example:
  /// ```dart
  /// final withRecovery = RecoverExtension2(
  ///   myFunc,
  ///   RecoveryStrategy(onError: (e) async => cleanup()),
  /// );
  /// ```
  RecoverExtension2(this._inner, RecoveryStrategy strategy)
    : _engine = RecoverEngine<R>(strategy),
      super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;
  final RecoverEngine<R> _engine;

  @override
  Future<R> call(T1 arg1, T2 arg2) => _engine.run(() => _inner(arg1, arg2));
}
