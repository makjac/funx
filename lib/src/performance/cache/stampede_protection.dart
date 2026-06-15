import 'dart:async';

/// Prevents cache stampede by coalescing concurrent loads for the same key.
///
/// When multiple callers request the same missing key at the same time, only
/// one loader executes. All callers receive the same result.
///
/// Example:
/// ```dart
/// final protection = StampedeProtection<String, int>();
/// final value = await protection.load('key', () async => expensiveLoad());
/// ```
class StampedeProtection<K, V> {
  final _inFlight = <K, Future<V>>{};

  /// Loads [key] using [loader], reusing an in-flight future if one exists.
  Future<V> load(K key, Future<V> Function() loader) async {
    if (_inFlight.containsKey(key)) return _inFlight[key]!;

    final future = loader();
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      // The removed in-flight future is already complete here.
      // ignore: unawaited_futures
      _inFlight.remove(key);
    }
  }
}
