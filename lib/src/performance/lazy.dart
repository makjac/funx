import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Defers function execution until the first time it is called.
///
/// Wraps a computation that should only be performed when actually
/// needed, not when the lazy function is created. Unlike memoization,
/// this executes every time it's called - the "lazy" aspect refers
/// to deferring the initial setup or execution until first use. This
/// pattern is useful for expensive initialization that may not always
/// be needed, or when you want to delay resource allocation.
///
/// Example:
/// ```dart
/// final expensiveInit = Func(() => loadHugeDataset()).lazy();
/// // loadHugeDataset() not called yet
///
/// final data = await expensiveInit(); // now loadHugeDataset() called
/// final data2 = await expensiveInit(); // called again (not cached)
/// ```
class LazyExtension<R> extends Func<R> {
  /// Creates a lazy execution wrapper for the given function.
  LazyExtension(this._inner) : super(() => throw UnimplementedError());

  final Func<R> _inner;
  bool _initialized = false;

  /// Executes the wrapped function on first call.
  ///
  /// Unlike `.once()`, this will execute every time it's called.
  /// The "lazy" aspect is that it defers execution until needed.
  @override
  Future<R> call() async {
    if (!_initialized) {
      _initialized = true;
    }
    return _inner();
  }
}

/// Defers function execution until first call for one-argument functions.
///
/// Extends lazy evaluation to functions with one parameter. Each call
/// with any argument triggers execution - arguments are not cached.
/// Useful for delaying resource-intensive operations that depend on
/// runtime parameters.
///
/// Example:
/// ```dart
/// final loader = Func1((String path) => File(path).read()).lazy();
/// // File reading not performed yet
///
/// final content = await loader('config.json'); // now file is read
/// final data = await loader('data.json'); // reads again with new arg
/// ```
class LazyExtension1<T, R> extends Func1<T, R> {
  /// Creates a lazy execution wrapper for the given one-argument function.
  LazyExtension1(this._inner) : super((_) => throw UnimplementedError());

  final Func1<T, R> _inner;
  bool _initialized = false;

  /// Executes the wrapped function on first call with the given argument.
  @override
  Future<R> call(T arg) async {
    if (!_initialized) {
      _initialized = true;
    }
    return _inner(arg);
  }
}

/// Defers function execution until first call for two-argument functions.
///
/// Extends lazy evaluation to functions with two parameters. Each call
/// triggers execution regardless of arguments - no caching occurs.
/// Useful for computations that should only run when explicitly needed.
///
/// Example:
/// ```dart
/// final compute = Func2((int a, int b) => a * b).lazy();
/// // Computation not performed yet
///
/// final result = await compute(3, 4); // now computation runs
/// final result2 = await compute(5, 6); // runs again with new args
/// ```
class LazyExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a lazy execution wrapper for the given two-argument function.
  LazyExtension2(this._inner) : super((_, _) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;
  bool _initialized = false;

  /// Executes the wrapped function on first call with the given arguments.
  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    if (!_initialized) {
      _initialized = true;
    }
    return _inner(arg1, arg2);
  }
}

/// Extension methods on [Func] for lazy functionality.
extension FuncLazyExtension<R> on Func<R> {
  /// Creates a lazy version of this function that defers execution
  /// until the first call.
  ///
  /// Example:
  /// ```dart
  /// final init = Func(() {
  ///   print('Initializing...');
  ///   return Database();
  /// }).lazy();
  ///
  /// // Nothing printed yet
  /// final db = init(); // prints "Initializing..." and returns Database
  /// ```
  Func<R> lazy() => LazyExtension(this);
}

/// Extension methods on [Func1] for lazy functionality.
extension Func1LazyExtension<T, R> on Func1<T, R> {
  /// Creates a lazy version of this function that defers execution
  /// until the first call.
  ///
  /// Example:
  /// ```dart
  /// final loader = Func1((String path) {
  ///   print('Loading $path...');
  ///   return File(path).readAsString();
  /// }).lazy();
  ///
  /// // Nothing loaded yet
  /// final content = loader('data.txt'); // prints "Loading data.txt..."
  /// ```
  Func1<T, R> lazy() => LazyExtension1(this);
}

/// Extension methods on [Func2] for lazy functionality.
extension Func2LazyExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Creates a lazy version of this function that defers execution
  /// until the first call.
  ///
  /// Example:
  /// ```dart
  /// final multiply = Func2((int a, int b) {
  ///   print('Computing $a * $b...');
  ///   return a * b;
  /// }).lazy();
  ///
  /// // Nothing computed yet
  /// final result = multiply(3, 4); // prints "Computing 3 * 4..."
  /// ```
  Func2<T1, T2, R> lazy() => LazyExtension2(this);
}
