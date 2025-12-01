/// Provides function execution control mechanisms for Dart.
///
/// Zero-dependency library offering comprehensive execution control
/// for async and sync functions. Includes timing controls, concurrency
/// management, reliability patterns, error handling, performance
/// optimizations, observability features, and scheduling mechanisms.
/// Supports method chaining for composing multiple behaviors. Designed
/// for building robust, resilient, and performant function pipelines.
///
/// Key categories:
/// - Concurrency: barriers, bulkheads, locks, semaphores, queues
/// - Control Flow: conditionals, repeats, switch patterns
/// - Core: function wrappers for async and sync operations
/// - Error Handling: catch, default values, recovery
/// - Observability: audit logs, metrics monitoring, tap inspection
/// - Orchestration: parallel execution, racing, sagas
/// - Performance: batching, caching, memoization, rate limiting
/// - Reliability: retries, backoff, circuit breakers, fallbacks
/// - Scheduling: one-time, recurring, backpressure control
/// - State: snapshots for state capture and restore
/// - Timing: debounce, throttle, delay, timeout, defer
/// - Transformation: merge, proxy, transform operations
/// - Validation: guards and validators for input checking
///
/// Example:
/// ```dart
/// import 'package:funx/funx.dart';
///
/// // Create debounced search with retry and timeout
/// final search = Func<List<Result>>(() async {
///   return await api.search(query);
/// })
///   .debounce(Duration(milliseconds: 300))
///   .retry(maxAttempts: 3)
///   .timeout(Duration(seconds: 5));
///
/// // Execute with full error handling
/// try {
///   final results = await search();
///   print('Found ${results.length} results');
/// } catch (e) {
///   print('Search failed: $e');
/// }
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

// Control Flow
export 'src/control_flow/conditional.dart';
export 'src/control_flow/repeat.dart';
export 'src/control_flow/switch.dart';

// Core
export 'src/core/func.dart';
export 'src/core/func_sync.dart';
export 'src/core/types.dart';

// Error Handling
export 'src/error_handling/catch.dart';
export 'src/error_handling/default.dart';

// Observability
export 'src/observability/audit.dart' hide AuditExtension1, AuditExtension2;
export 'src/observability/monitor.dart'
    hide MonitorExtension, MonitorExtension1, MonitorExtension2;
export 'src/observability/tap.dart';

// Orchestration
export 'src/orchestration/all.dart';
export 'src/orchestration/race.dart';
export 'src/orchestration/saga.dart';

// Performance
export 'src/performance/batch.dart';
export 'src/performance/cache_aside.dart';
export 'src/performance/compress.dart';
export 'src/performance/deduplicate.dart';
export 'src/performance/lazy.dart';
export 'src/performance/memoize.dart';
export 'src/performance/once.dart';
export 'src/performance/rate_limit.dart';
export 'src/performance/share.dart';
export 'src/performance/warm_up.dart';

// Reliability
export 'src/reliability/backoff.dart';
export 'src/reliability/circuit_breaker.dart';
export 'src/reliability/fallback.dart';
export 'src/reliability/recover.dart';
export 'src/reliability/retry.dart';

// Scheduling
export 'src/scheduling/backpressure.dart';
export 'src/scheduling/schedule.dart';

// State
export 'src/state/snapshot.dart';

// Timing
export 'src/timing/debounce.dart';
export 'src/timing/defer.dart';
export 'src/timing/delay.dart';
export 'src/timing/idle_callback.dart';
export 'src/timing/throttle.dart';
export 'src/timing/timeout.dart';

// Transformation
export 'src/transformation/merge.dart';
export 'src/transformation/proxy.dart';
export 'src/transformation/transform.dart';

// Validation
export 'src/validation/guard.dart';
export 'src/validation/validate.dart';
