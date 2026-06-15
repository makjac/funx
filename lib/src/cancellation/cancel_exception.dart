/// Exception thrown when a cancellable operation is cancelled before it
/// completes.
///
/// Callers awaiting the [Future] returned by a cancellable function can catch
/// this exception to detect cancellation.
///
/// Example:
/// ```dart
/// final operation = cancellableFunc.operation();
/// operation.cancel();
///
/// try {
///   await operation.value;
/// } on CancelException {
///   print('Cancelled');
/// }
/// ```
class CancelException implements Exception {
  /// Creates a [CancelException].
  const CancelException();

  @override
  String toString() => 'CancelException: operation was cancelled';
}
