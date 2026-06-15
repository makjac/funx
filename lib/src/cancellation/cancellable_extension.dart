import 'package:funx/src/cancellation/cancel_token.dart';
import 'package:funx/src/cancellation/cancellable_func.dart';
import 'package:funx/src/cancellation/cancellable_func1.dart';
import 'package:funx/src/cancellation/cancellable_func2.dart';
import 'package:funx/src/core/func.dart';

/// Extension adding cancellation support to no-parameter functions.
extension CancellableExtension<R> on Func<R> {
  /// Returns a [CancellableFunc] wrapping this function.
  ///
  /// If [token] is provided, every invocation is registered with the token
  /// and cancelled when [CancelToken.cancel] is called.
  ///
  /// Example:
  /// ```dart
  /// final work = Func<String>(() async => 'done').cancellable();
  /// final operation = work.operation();
  /// operation.cancel();
  /// ```
  CancellableFunc<R> cancellable({CancelToken? token}) =>
      CancellableFunc<R>(this, token: token);
}

/// Extension adding cancellation support to single-parameter functions.
extension CancellableExtension1<T, R> on Func1<T, R> {
  /// Returns a [CancellableFunc1] wrapping this function.
  CancellableFunc1<T, R> cancellable({CancelToken? token}) =>
      CancellableFunc1<T, R>(this, token: token);
}

/// Extension adding cancellation support to two-parameter functions.
extension CancellableExtension2<T1, T2, R> on Func2<T1, T2, R> {
  /// Returns a [CancellableFunc2] wrapping this function.
  CancellableFunc2<T1, T2, R> cancellable({CancelToken? token}) =>
      CancellableFunc2<T1, T2, R>(this, token: token);
}
