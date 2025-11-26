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
