/// Immutable pair of two arguments used as a cache key for two-argument
/// memoization and cache-aside wrappers.
class ArgPair<T1, T2> {
  /// Creates an argument pair.
  const ArgPair(this.arg1, this.arg2);

  /// First argument.
  final T1 arg1;

  /// Second argument.
  final T2 arg2;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArgPair<T1, T2> &&
          runtimeType == other.runtimeType &&
          arg1 == other.arg1 &&
          arg2 == other.arg2;

  @override
  int get hashCode => Object.hash(arg1, arg2);
}
