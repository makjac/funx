import 'dart:async';

import 'package:funx/src/performance/cache/advanced_cache.dart';
import 'package:funx/src/performance/cache/cache_entry.dart';

/// Periodically pre-fetches and refreshes a set of cache keys.
///
/// Useful for keeping hot data warm so callers never hit a cold cache.
///
/// Example:
/// ```dart
/// final warmer = CacheWarmer<String, User>(
///   cache: cache,
///   loader: (id) async => api.getUser(id),
///   interval: Duration(minutes: 5),
///   keys: ['user-1', 'user-2'],
/// );
/// warmer.start();
/// // later:
/// await warmer.stop();
/// ```
class CacheWarmer<K, V> {
  /// Creates a cache warmer.
  CacheWarmer({
    required this.cache,
    required this.loader,
    required this.interval,
    required this.keys,
  });

  /// Cache to warm.
  final AdvancedCache<K, V> cache;

  /// Loader used to refresh each key.
  final Future<V> Function(K key) loader;

  /// Refresh interval.
  final Duration interval;

  /// Keys that should be kept warm.
  final Iterable<K> keys;

  Timer? _timer;

  /// Whether the warmer is currently running.
  bool get isRunning => _timer != null && _timer!.isActive;

  /// Starts periodic warming.
  ///
  /// Optionally performs an immediate warm-up before the first interval.
  void start({bool immediate = true}) {
    stop();
    if (immediate) {
      unawaited(_warmAll());
    }
    _timer = Timer.periodic(interval, (_) => unawaited(_warmAll()));
  }

  /// Stops periodic warming.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _warmAll() async {
    for (final key in keys) {
      try {
        final value = await loader(key);
        cache.putEntry(key, CacheEntry(value));
      } catch (_) {
        // Ignore warm-up errors so one failing key does not stop the rest.
      }
    }
  }
}
