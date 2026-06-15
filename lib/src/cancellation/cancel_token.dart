/// A token that can be shared by multiple cancellable operations to cancel
/// them all at once.
///
/// Pass a [CancelToken] to [Func.cancellable], [Func1.cancellable], or
/// [Func2.cancellable]. Every invocation registered with the token will be
/// cancelled when [cancel] is called.
///
/// Example:
/// ```dart
/// final token = CancelToken();
///
/// final a = Func(() => workA()).cancellable(token: token);
/// final b = Func(() => workB()).cancellable(token: token);
///
/// unawaited(a());
/// unawaited(b());
///
/// token.cancel(); // cancels both
/// ```
class CancelToken {
  final List<void Function()> _callbacks = [];
  bool _isCancelled = false;

  /// Whether this token has been cancelled.
  bool get isCancelled => _isCancelled;

  /// Registers a [callback] to be invoked when this token is cancelled.
  ///
  /// If the token has already been cancelled, the callback is invoked
  /// immediately.
  ///
  /// This method is intended for internal use by cancellable wrappers.
  void register(void Function() callback) {
    if (_isCancelled) {
      callback();
    } else {
      _callbacks.add(callback);
    }
  }

  /// Cancels every operation registered with this token.
  ///
  /// Subsequent registrations will be cancelled immediately. Calling [cancel]
  /// more than once has no effect.
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;

    final callbacks = List<void Function()>.from(_callbacks);
    _callbacks.clear();

    for (final callback in callbacks) {
      callback();
    }
  }
}
