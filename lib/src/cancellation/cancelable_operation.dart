import 'dart:async';

import 'package:funx/src/cancellation/cancel_exception.dart';

/// An async operation that can be cancelled before it completes.
///
/// [CancelableOperation] exposes the underlying [Future] via [value] and a
/// [cancel] method that completes [value] with a [CancelException].
///
/// Instances are created through [CancelableCompleter.operation].
///
/// Example:
/// ```dart
/// final completer = CancelableCompleter<String>();
/// final operation = completer.operation;
///
/// operation.cancel();
///
/// try {
///   await operation.value;
/// } on CancelException {
///   print('Cancelled');
/// }
/// ```
class CancelableOperation<R> {
  /// Creates an operation tied to the given [completer].
  CancelableOperation._(this._completer);

  final CancelableCompleter<R> _completer;

  /// The future that completes with the operation result or a
  /// [CancelException] if cancelled.
  Future<R> get value => _completer._completer.future;

  /// Whether this operation has been cancelled.
  bool get isCanceled => _completer._isCanceled;

  /// Whether this operation has completed, either successfully, with an error,
  /// or by cancellation.
  bool get isCompleted => _completer._isCompleted;

  /// Cancels this operation.
  ///
  /// If the operation has not yet completed, it completes [value] with a
  /// [CancelException] and invokes the optional callback provided to the
  /// [CancelableCompleter]. Subsequent calls are ignored.
  void cancel() => _completer.cancel();
}

/// A completer for building [CancelableOperation] instances.
///
/// [CancelableCompleter] behaves like a regular [Completer] but supports
/// cancellation. When [cancel] is called, the operation completes with a
/// [CancelException] and the optional [onCancel] callback is invoked.
///
/// Example:
/// ```dart
/// final completer = CancelableCompleter<String>();
///
/// completer.complete('hello');
///
/// final result = await completer.operation.value; // 'hello'
/// ```
class CancelableCompleter<R> {
  /// Creates a cancellable completer.
  ///
  /// The optional [onCancel] callback runs when the operation is cancelled.
  /// It is a good place to stop timers, close subscriptions, or propagate
  /// cancellation to inner work.
  CancelableCompleter({void Function()? onCancel}) : _onCancel = onCancel;

  final Completer<R> _completer = Completer<R>();
  final void Function()? _onCancel;

  bool _isCanceled = false;
  bool _isCompleted = false;

  /// The operation controlled by this completer.
  CancelableOperation<R> get operation => CancelableOperation<R>._(this);

  /// Whether this completer has been cancelled.
  bool get isCanceled => _isCanceled;

  /// Whether this completer has completed, either successfully, with an error,
  /// or by cancellation.
  bool get isCompleted => _isCompleted;

  /// Completes the operation with [value].
  ///
  /// Does nothing if the operation was already completed or cancelled.
  void complete(R value) {
    if (_isCanceled || _isCompleted) return;
    _isCompleted = true;
    _completer.complete(value);
  }

  /// Completes the operation with [error] and optional [stackTrace].
  ///
  /// Does nothing if the operation was already completed or cancelled.
  void completeError(Object error, [StackTrace? stackTrace]) {
    if (_isCanceled || _isCompleted) return;
    _isCompleted = true;
    _completer.completeError(error, stackTrace);
  }

  /// Cancels the operation.
  ///
  /// Completes the operation with a [CancelException] and invokes [onCancel]
  /// if provided. Subsequent calls are ignored.
  void cancel() {
    if (_isCanceled || _isCompleted) return;
    _isCanceled = true;
    _isCompleted = true;
    _onCancel?.call();
    _completer.completeError(const CancelException());
  }
}
