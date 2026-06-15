import 'dart:async';

import 'package:funx/src/cancellation/cancel_token.dart';
import 'package:funx/src/cancellation/cancelable_operation.dart';
import 'package:funx/src/core/func.dart';

/// A [Func1] wrapper whose executions can be cancelled.
///
/// See [CancellableFunc] for details; this variant accepts one argument.
class CancellableFunc1<T, R> extends Func1<T, R> {
  /// Creates a cancellable wrapper around [inner].
  CancellableFunc1(
    this._inner, {
    CancelToken? token,
  }) : _token = token,
       super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;
  final CancelToken? _token;

  final Map<T, CancelableOperation<R>> _lastOperations = {};

  /// Starts the wrapped function with [arg] and returns a
  /// [CancelableOperation].
  CancelableOperation<R> operation(T arg) {
    if (_token?.isCancelled ?? false) {
      final completer = CancelableCompleter<R>();
      scheduleMicrotask(completer.cancel);
      return completer.operation;
    }

    final completer = CancelableCompleter<R>(
      onCancel: () {
        if (_inner case final CancellableFunc1<T, R> innerCancellable) {
          innerCancellable.cancel(arg);
        }
      },
    );

    _token?.register(completer.cancel);
    _lastOperations[arg] = completer.operation;

    unawaited(
      _inner(arg).then(
        completer.complete,
        onError: completer.completeError,
      ),
    );

    return completer.operation;
  }

  /// Executes the wrapped function with [arg] and returns its result future.
  @override
  Future<R> call(T arg) => operation(arg).value;

  /// Cancels the most recent operation started for [arg].
  void cancel(T arg) => _lastOperations[arg]?.cancel();
}
