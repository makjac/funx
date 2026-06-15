import 'dart:async';

import 'package:funx/src/cancellation/cancel_token.dart';
import 'package:funx/src/cancellation/cancelable_operation.dart';
import 'package:funx/src/core/func.dart';

/// A [Func2] wrapper whose executions can be cancelled.
///
/// See [CancellableFunc] for details; this variant accepts two arguments.
class CancellableFunc2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a cancellable wrapper around [inner].
  CancellableFunc2(
    this._inner, {
    CancelToken? token,
  }) : _token = token,
       super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;
  final CancelToken? _token;

  final Map<(T1, T2), CancelableOperation<R>> _lastOperations = {};

  /// Starts the wrapped function with [arg1] and [arg2] and returns a
  /// [CancelableOperation].
  CancelableOperation<R> operation(T1 arg1, T2 arg2) {
    if (_token?.isCancelled ?? false) {
      final completer = CancelableCompleter<R>();
      scheduleMicrotask(completer.cancel);
      return completer.operation;
    }

    final key = (arg1, arg2);
    final completer = CancelableCompleter<R>(
      onCancel: () {
        if (_inner case final CancellableFunc2<T1, T2, R> innerCancellable) {
          innerCancellable.cancel(arg1, arg2);
        }
      },
    );

    _token?.register(completer.cancel);
    _lastOperations[key] = completer.operation;

    unawaited(
      _inner(arg1, arg2).then(
        completer.complete,
        onError: completer.completeError,
      ),
    );

    return completer.operation;
  }

  /// Executes the wrapped function with [arg1] and [arg2] and returns its
  /// result future.
  @override
  Future<R> call(T1 arg1, T2 arg2) => operation(arg1, arg2).value;

  /// Cancels the most recent operation started for ([arg1], [arg2]).
  void cancel(T1 arg1, T2 arg2) => _lastOperations[(arg1, arg2)]?.cancel();
}
