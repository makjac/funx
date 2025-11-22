/// Funx - A zero-dependency function execution control library for Dart.
///
/// Funx provides a comprehensive set of execution control mechanisms for async
/// and sync functions, including timing controls, concurrency management,
/// reliability patterns, and performance optimizations.
///
/// Example:
/// ```dart
/// import 'package:funx/funx.dart';
///
/// // Create a debounced search function
/// final search = Func<List<Result>>(() async {
///   return await api.search(query);
/// }).debounce(Duration(milliseconds: 300));
///
/// // Use it
/// final results = await search();
/// ```
library;

// Concurrency
export 'src/concurrency/barrier.dart';
export 'src/concurrency/bulkhead.dart';
export 'src/concurrency/countdown_latch.dart';
export 'src/concurrency/lock.dart';
export 'src/concurrency/monitor.dart';
export 'src/concurrency/queue.dart';
export 'src/concurrency/rw_lock.dart';
export 'src/concurrency/semaphore.dart';

// Core
export 'src/core/func.dart';
export 'src/core/func_sync.dart';
export 'src/core/types.dart';

// Performance
export 'src/performance/deduplicate.dart';
export 'src/performance/lazy.dart';
export 'src/performance/memoize.dart';
export 'src/performance/once.dart';
export 'src/performance/share.dart';

// Reliability
export 'src/reliability/backoff.dart';
export 'src/reliability/circuit_breaker.dart';
export 'src/reliability/fallback.dart';
export 'src/reliability/recover.dart';
export 'src/reliability/retry.dart';

// Timing
export 'src/timing/debounce.dart';
export 'src/timing/defer.dart';
export 'src/timing/delay.dart';
export 'src/timing/idle_callback.dart';
export 'src/timing/throttle.dart';
export 'src/timing/timeout.dart';
