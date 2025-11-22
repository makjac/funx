// ignore_for_file: use_late_for_private_fields_and_variables .

import 'dart:async';
import 'dart:collection';

import 'package:funx/src/core/func.dart';

/// Rate limiting strategy.
enum RateLimitStrategy {
  /// Token bucket algorithm - allows bursts but maintains average rate.
  tokenBucket,

  /// Leaky bucket algorithm - enforces steady rate, no bursts.
  leakyBucket,

  /// Fixed window - allows N requests per fixed time window.
  fixedWindow,

  /// Sliding window - allows N requests per sliding time window.
  slidingWindow,
}

/// A function that limits the rate of execution.
///
/// Supports multiple rate limiting strategies including token bucket,
/// leaky bucket, fixed window, and sliding window.
///
/// Example:
/// ```dart
/// final apiCall = Func(() async {
///   return await api.getData();
/// }).rateLimit(
///   maxCalls: 10,
///   window: Duration(seconds: 1),
///   strategy: RateLimitStrategy.tokenBucket,
/// );
///
/// for (var i = 0; i < 20; i++) {
///   await apiCall(); // First 10 execute immediately, rest are delayed
/// }
/// ```
class RateLimitExtension<R> extends Func<R> {
  /// Creates a rate-limiting wrapper.
  ///
  /// [maxCalls] specifies maximum calls per [window].
  /// [strategy] determines the rate limiting algorithm.
  RateLimitExtension(
    this._inner, {
    required this.maxCalls,
    required this.window,
    this.strategy = RateLimitStrategy.tokenBucket,
  }) : super(() => throw UnimplementedError()) {
    _initializeStrategy();
  }

  final Func<R> _inner;

  /// Maximum number of calls allowed per window.
  final int maxCalls;

  /// Time window for rate limiting.
  final Duration window;

  /// Rate limiting strategy to use.
  final RateLimitStrategy strategy;

  // Token bucket fields
  int _tokens = 0;
  DateTime? _lastRefill;

  // Leaky bucket fields
  final Queue<Completer<void>> _queue = Queue();
  Timer? _leakTimer;

  // Fixed/Sliding window fields
  final List<DateTime> _callTimestamps = [];

  void _initializeStrategy() {
    if (strategy == RateLimitStrategy.tokenBucket) {
      _tokens = maxCalls;
      _lastRefill = DateTime.now();
    } else if (strategy == RateLimitStrategy.leakyBucket) {
      _startLeakyBucket();
    }
  }

  void _startLeakyBucket() {
    final intervalMs = window.inMilliseconds ~/ maxCalls;
    _leakTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_queue.isNotEmpty) {
        _queue.removeFirst().complete();
      }
    });
  }

  Future<void> _tokenBucketWait() async {
    while (true) {
      final now = DateTime.now();
      final elapsed = now.difference(_lastRefill!);

      // Refill tokens based on elapsed time
      if (elapsed >= window) {
        final periods = elapsed.inMicroseconds ~/ window.inMicroseconds;
        _tokens = maxCalls;
        _lastRefill = _lastRefill!.add(window * periods);
      }

      if (_tokens > 0) {
        _tokens--;
        return;
      }

      // Wait until next refill
      final timeToRefill = window - elapsed;
      await Future<void>.delayed(timeToRefill);
    }
  }

  Future<void> _leakyBucketWait() async {
    if (_queue.length >= maxCalls) {
      // Queue full, wait for space
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    } else {
      // Queue has space
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }
  }

  Future<void> _fixedWindowWait() async {
    final now = DateTime.now();

    // Remove timestamps outside current window
    _callTimestamps.removeWhere(
      (timestamp) => now.difference(timestamp) >= window,
    );

    if (_callTimestamps.length >= maxCalls) {
      // Wait until oldest timestamp expires
      final oldestTimestamp = _callTimestamps.first;
      final waitTime = window - now.difference(oldestTimestamp);
      await Future<void>.delayed(waitTime);
      return _fixedWindowWait(); // Retry after waiting
    }

    _callTimestamps.add(now);
  }

  Future<void> _slidingWindowWait() async {
    final now = DateTime.now();

    // Remove timestamps outside sliding window
    _callTimestamps.removeWhere(
      (timestamp) => now.difference(timestamp) >= window,
    );

    if (_callTimestamps.length >= maxCalls) {
      // Calculate wait time based on oldest timestamp in window
      final oldestTimestamp = _callTimestamps.first;
      final waitTime =
          window -
          now.difference(oldestTimestamp) +
          const Duration(milliseconds: 1);
      await Future<void>.delayed(waitTime);
      return _slidingWindowWait(); // Retry after waiting
    }

    _callTimestamps.add(now);
  }

  @override
  Future<R> call() async {
    switch (strategy) {
      case RateLimitStrategy.tokenBucket:
        await _tokenBucketWait();
      case RateLimitStrategy.leakyBucket:
        await _leakyBucketWait();
      case RateLimitStrategy.fixedWindow:
        await _fixedWindowWait();
      case RateLimitStrategy.slidingWindow:
        await _slidingWindowWait();
    }

    return _inner();
  }

  /// Resets the rate limiter state.
  void reset() {
    _tokens = maxCalls;
    _lastRefill = DateTime.now();
    _queue.clear();
    _callTimestamps.clear();
  }

  /// Disposes resources (stops timers).
  void dispose() {
    _leakTimer?.cancel();
  }
}

/// A function that limits the rate of execution for single-argument functions.
///
/// Rate limiting is applied globally across all argument values.
///
/// Example:
/// ```dart
/// final fetchUser = Func1((String id) async {
///   return await api.getUser(id);
/// }).rateLimit(
///   maxCalls: 5,
///   window: Duration(seconds: 1),
/// );
/// ```
class RateLimitExtension1<T, R> extends Func1<T, R> {
  /// Creates a rate-limiting wrapper for single-argument functions.
  RateLimitExtension1(
    this._inner, {
    required this.maxCalls,
    required this.window,
    this.strategy = RateLimitStrategy.tokenBucket,
  }) : super((_) => throw UnimplementedError()) {
    _initializeStrategy();
  }

  final Func1<T, R> _inner;

  /// Maximum number of calls allowed per window.
  final int maxCalls;

  /// Time window for rate limiting.
  final Duration window;

  /// Rate limiting strategy to use.
  final RateLimitStrategy strategy;

  int _tokens = 0;
  DateTime? _lastRefill;
  final Queue<Completer<void>> _queue = Queue();
  Timer? _leakTimer;
  final List<DateTime> _callTimestamps = [];

  void _initializeStrategy() {
    if (strategy == RateLimitStrategy.tokenBucket) {
      _tokens = maxCalls;
      _lastRefill = DateTime.now();
    } else if (strategy == RateLimitStrategy.leakyBucket) {
      _startLeakyBucket();
    }
  }

  void _startLeakyBucket() {
    final intervalMs = window.inMilliseconds ~/ maxCalls;
    _leakTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_queue.isNotEmpty) {
        _queue.removeFirst().complete();
      }
    });
  }

  Future<void> _waitForSlot() async {
    switch (strategy) {
      case RateLimitStrategy.tokenBucket:
        await _tokenBucketWait();
      case RateLimitStrategy.leakyBucket:
        await _leakyBucketWait();
      case RateLimitStrategy.fixedWindow:
        await _fixedWindowWait();
      case RateLimitStrategy.slidingWindow:
        await _slidingWindowWait();
    }
  }

  Future<void> _tokenBucketWait() async {
    while (true) {
      final now = DateTime.now();
      final elapsed = now.difference(_lastRefill!);

      if (elapsed >= window) {
        _tokens = maxCalls;
        _lastRefill = now;
      }

      if (_tokens > 0) {
        _tokens--;
        return;
      }

      await Future<void>.delayed(window - elapsed);
    }
  }

  Future<void> _leakyBucketWait() async {
    final completer = Completer<void>();
    _queue.add(completer);
    await completer.future;
  }

  Future<void> _fixedWindowWait() async {
    final now = DateTime.now();
    _callTimestamps.removeWhere((t) => now.difference(t) >= window);

    if (_callTimestamps.length >= maxCalls) {
      final waitTime = window - now.difference(_callTimestamps.first);
      await Future<void>.delayed(waitTime);
      return _fixedWindowWait();
    }

    _callTimestamps.add(now);
  }

  Future<void> _slidingWindowWait() async {
    final now = DateTime.now();
    _callTimestamps.removeWhere((t) => now.difference(t) >= window);

    if (_callTimestamps.length >= maxCalls) {
      final waitTime = window - now.difference(_callTimestamps.first);
      await Future<void>.delayed(waitTime);
      return _slidingWindowWait();
    }

    _callTimestamps.add(now);
  }

  @override
  Future<R> call(T arg) async {
    await _waitForSlot();
    return _inner(arg);
  }

  /// Resets the rate limiter state.
  void reset() {
    _tokens = maxCalls;
    _lastRefill = DateTime.now();
    _queue.clear();
    _callTimestamps.clear();
  }

  /// Disposes resources (stops timers).
  void dispose() {
    _leakTimer?.cancel();
  }
}

/// A function that limits the rate of execution for two-argument functions.
///
/// Example:
/// ```dart
/// final compute = Func2((int a, int b) async {
///   return await heavyComputation(a, b);
/// }).rateLimit(maxCalls: 10, window: Duration(seconds: 1));
/// ```
class RateLimitExtension2<T1, T2, R> extends Func2<T1, T2, R> {
  /// Creates a rate-limiting wrapper for two-argument functions.
  RateLimitExtension2(
    this._inner, {
    required this.maxCalls,
    required this.window,
    this.strategy = RateLimitStrategy.tokenBucket,
  }) : super((_, _) => throw UnimplementedError()) {
    _initializeStrategy();
  }

  final Func2<T1, T2, R> _inner;

  /// Maximum number of calls allowed per window.
  final int maxCalls;

  /// Time window for rate limiting.
  final Duration window;

  /// Rate limiting strategy to use.
  final RateLimitStrategy strategy;

  int _tokens = 0;
  DateTime? _lastRefill;
  final Queue<Completer<void>> _queue = Queue();
  Timer? _leakTimer;
  final List<DateTime> _callTimestamps = [];

  void _initializeStrategy() {
    if (strategy == RateLimitStrategy.tokenBucket) {
      _tokens = maxCalls;
      _lastRefill = DateTime.now();
    } else if (strategy == RateLimitStrategy.leakyBucket) {
      _startLeakyBucket();
    }
  }

  void _startLeakyBucket() {
    final intervalMs = window.inMilliseconds ~/ maxCalls;
    _leakTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_queue.isNotEmpty) {
        _queue.removeFirst().complete();
      }
    });
  }

  Future<void> _waitForSlot() async {
    switch (strategy) {
      case RateLimitStrategy.tokenBucket:
        await _tokenBucketWait();
      case RateLimitStrategy.leakyBucket:
        await _leakyBucketWait();
      case RateLimitStrategy.fixedWindow:
        await _fixedWindowWait();
      case RateLimitStrategy.slidingWindow:
        await _slidingWindowWait();
    }
  }

  Future<void> _tokenBucketWait() async {
    while (true) {
      final now = DateTime.now();
      final elapsed = now.difference(_lastRefill!);

      if (elapsed >= window) {
        _tokens = maxCalls;
        _lastRefill = now;
      }

      if (_tokens > 0) {
        _tokens--;
        return;
      }

      await Future<void>.delayed(window - elapsed);
    }
  }

  Future<void> _leakyBucketWait() async {
    final completer = Completer<void>();
    _queue.add(completer);
    await completer.future;
  }

  Future<void> _fixedWindowWait() async {
    final now = DateTime.now();
    _callTimestamps.removeWhere((t) => now.difference(t) >= window);

    if (_callTimestamps.length >= maxCalls) {
      final waitTime = window - now.difference(_callTimestamps.first);
      await Future<void>.delayed(waitTime);
      return _fixedWindowWait();
    }

    _callTimestamps.add(now);
  }

  Future<void> _slidingWindowWait() async {
    final now = DateTime.now();
    _callTimestamps.removeWhere((t) => now.difference(t) >= window);

    if (_callTimestamps.length >= maxCalls) {
      final waitTime = window - now.difference(_callTimestamps.first);
      await Future<void>.delayed(waitTime);
      return _slidingWindowWait();
    }

    _callTimestamps.add(now);
  }

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    await _waitForSlot();
    return _inner(arg1, arg2);
  }

  /// Resets the rate limiter state.
  void reset() {
    _tokens = maxCalls;
    _lastRefill = DateTime.now();
    _queue.clear();
    _callTimestamps.clear();
  }

  /// Disposes resources (stops timers).
  void dispose() {
    _leakTimer?.cancel();
  }
}

extension FuncRateLimitExtension<R> on Func<R> {
  /// Creates a rate-limited version of this function.
  ///
  /// Parameters:
  /// - [maxCalls]: Maximum calls allowed per window
  /// - [window]: Time window for rate limiting
  /// - [strategy]: Rate limiting strategy (default: token bucket)
  ///
  /// Example:
  /// ```dart
  /// final api = Func(() => http.get(url)).rateLimit(
  ///   maxCalls: 10,
  ///   window: Duration(seconds: 1),
  ///   strategy: RateLimitStrategy.tokenBucket,
  /// );
  /// ```
  Func<R> rateLimit({
    required int maxCalls,
    required Duration window,
    RateLimitStrategy strategy = RateLimitStrategy.tokenBucket,
  }) => RateLimitExtension(
    this,
    maxCalls: maxCalls,
    window: window,
    strategy: strategy,
  );
}

extension Func1RateLimitExtension<T, R> on Func1<T, R> {
  /// Creates a rate-limited version of this function.
  ///
  /// Example:
  /// ```dart
  /// final fetchUser = Func1((String id) => api.get(id)).rateLimit(
  ///   maxCalls: 5,
  ///   window: Duration(seconds: 1),
  /// );
  /// ```
  Func1<T, R> rateLimit({
    required int maxCalls,
    required Duration window,
    RateLimitStrategy strategy = RateLimitStrategy.tokenBucket,
  }) => RateLimitExtension1(
    this,
    maxCalls: maxCalls,
    window: window,
    strategy: strategy,
  );
}

extension Func2RateLimitExtension<T1, T2, R> on Func2<T1, T2, R> {
  /// Creates a rate-limited version of this function.
  ///
  /// Example:
  /// ```dart
  /// final compute = Func2((int a, int b) => a * b).rateLimit(
  ///   maxCalls: 100,
  ///   window: Duration(seconds: 1),
  /// );
  /// ```
  Func2<T1, T2, R> rateLimit({
    required int maxCalls,
    required Duration window,
    RateLimitStrategy strategy = RateLimitStrategy.tokenBucket,
  }) => RateLimitExtension2(
    this,
    maxCalls: maxCalls,
    window: window,
    strategy: strategy,
  );
}
