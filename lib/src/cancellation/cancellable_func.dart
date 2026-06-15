import 'dart:async';

import 'package:funx/src/cancellation/cancel_token.dart';
import 'package:funx/src/cancellation/cancelable_operation.dart';
import 'package:funx/src/core/func.dart';

/// A [Func] wrapper whose executions can be cancelled.
///
/// [CancellableFunc] extends [Func] so it remains composable with the rest of
/// the decorator chain. Use [operation] when you need explicit control over
/// cancellation, or [call] when you only need a [Future].
///
/// Example:
/// ```dart
/// final work = Func<String>(() async {
///   await Future<void>.delayed(Duration(seconds: 5));
///   return 'done';
/// }).cancellable();
///
/// final operation = work.operation();
/// operation.cancel();
///
/// try {
///   await operation.value;
/// } on CancelException {
///   print('Cancelled');
/// }
/// ```
class CancellableFunc<R> extends Func<R> {
  /// Creates a cancellable wrapper around [inner].
  ///
  /// If [token] is provided, every invocation is registered with the token
  /// and will be cancelled when [CancelToken.cancel] is called.
  CancellableFunc(
    this._inner, {
    CancelToken? token,
  }) : _token = token,
       super(() => throw UnimplementedError());

  final Func<R> _inner;
  final CancelToken? _token;

  CancelableOperation<R>? _lastOperation;

  /// Starts the wrapped function and returns a [CancelableOperation].
  ///
  /// This is the most flexible way to use cancellation: it gives access to
  /// both the result [Future] and the [cancel] method.
  CancelableOperation<R> operation() {
    if (_token?.isCancelled ?? false) {
      final completer = CancelableCompleter<R>();
      scheduleMicrotask(completer.cancel);
      return completer.operation;
    }

    final completer = CancelableCompleter<R>(
      onCancel: () {
        if (_inner case final CancellableFunc<R> innerCancellable) {
          innerCancellable.cancel();
        }
      },
    );

    _token?.register(completer.cancel);
    _lastOperation = completer.operation;

    unawaited(
      _inner().then(
        completer.complete,
        onError: completer.completeError,
      ),
    );

    return completer.operation;
  }

  /// Executes the wrapped function and returns its result future.
  ///
  /// Equivalent to `operation().value`. To cancel the returned future, use
  /// [operation] or call [cancel] on this instance (for the most recent
  /// invocation).
  @override
  Future<R> call() => operation().value;

  /// Cancels the most recent operation started by this wrapper.
  ///
  /// Does nothing if there is no active operation.
  void cancel() => _lastOperation?.cancel();
}
