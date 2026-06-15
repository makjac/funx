/// A single cache entry with metadata used by eviction policies.
///
/// Stores the cached value together with optional expiration time, weight,
/// and access counter. The metadata is used by [LruCache], [LfuCache],
/// [FifoCache], and [WeightedCache] to make eviction decisions.
///
/// Example:
/// ```dart
/// final entry = CacheEntry<String>('data',
///   expiresAt: DateTime.now().add(Duration(minutes: 5)),
///   weight: 1024,
/// );
/// ```
class CacheEntry<V> {
  /// Creates a cache entry.
  ///
  /// [value] is the cached value.
  /// [expiresAt] is the optional expiration time. If null, the entry never
  /// expires.
  /// [weight] is the size cost of this entry used by weighted eviction.
  /// [accessCount] is the initial access counter used by LFU eviction.
  CacheEntry(
    this.value, {
    this.expiresAt,
    this.weight = 1,
    this.accessCount = 1,
  });

  /// The cached value.
  final V value;

  /// Optional expiration time.
  ///
  /// When [DateTime.now] is after this time, [isExpired] returns true.
  final DateTime? expiresAt;

  /// Weight of this entry.
  ///
  /// Used by [WeightedCache] to enforce a total weight limit.
  final int weight;

  /// Number of times this entry has been accessed.
  ///
  /// Used by [LfuCache] to determine which entry to evict.
  int accessCount;

  /// Whether this entry has expired.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}
