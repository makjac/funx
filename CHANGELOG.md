## 0.5.0

### Error Handling

- **Catch**: Type-safe error handling with specific handlers
  - `CatchExtension`, `CatchExtension1`, `CatchExtension2` for `Func`, `Func1`, `Func2`
  - `Map<Type, Handler>` for type-specific error handling
  - `catchAll` handler for unmatched errors
  - `onCatch` callback for each caught error
  - `rethrowUnhandled` option for unhandled errors
  - Stack trace preservation

- **Default**: Provide default values when function execution fails
  - `DefaultExtension`, `DefaultExtension1`, `DefaultExtension2`
  - Default value or default factory support
  - `defaultIf` predicate to determine when to use default
  - `onDefault` callback when default value is used
  - Graceful error recovery

## 0.4.0

- **Once**: Execute function only once and cache result forever
  - `OnceExtension`, `OnceExtension1`, `OnceExtension2` for `Func`, `Func1`, `Func2`
  - Result and error caching
  - Reset functionality with optional predicate
  - Cache invalidation support

- **Lazy**: Defer function execution until first call
  - `LazyExtension`, `LazyExtension1`, `LazyExtension2`
  - Deferred initialization pattern
  - Lazy loading support

- **Memoize**: Cache function results with TTL and eviction policies
  - `MemoizeExtension`, `MemoizeExtension1`, `MemoizeExtension2`
  - Configurable time-to-live (TTL)
  - Maximum cache size limits
  - Multiple eviction policies:
    - `EvictionPolicy.lru`: Least Recently Used
    - `EvictionPolicy.lfu`: Least Frequently Used
    - `EvictionPolicy.fifo`: First In First Out
  - Per-argument caching for `Func1` and `Func2`
  - Manual cache clearing

- **Deduplicate**: Prevent duplicate function calls within a time window
  - `DeduplicateExtension`, `DeduplicateExtension1`, `DeduplicateExtension2`
  - Configurable deduplication window
  - Per-argument deduplication tracking
  - Manual reset functionality

- **Share**: Share single execution among concurrent callers
  - `ShareExtension`, `ShareExtension1`, `ShareExtension2`
  - Concurrent call deduplication
  - Per-argument sharing for `Func1` and `Func2`
  - Automatic cleanup after execution

- **Batch**: Accumulate calls and execute in batches
  - `BatchExtension`, `BatchExtension2` for `Func1` and `Func2`
  - Configurable batch size (`maxSize`)
  - Configurable wait time (`maxWait`)
  - Custom batch executor
  - Manual flush and cancel support
  - Individual result handling

- **RateLimit**: Control function execution rate
  - `RateLimitExtension`, `RateLimitExtension1`, `RateLimitExtension2`
  - Multiple rate limiting strategies:
    - `RateLimitStrategy.tokenBucket`: Allows bursts, maintains average rate
    - `RateLimitStrategy.leakyBucket`: Enforces steady rate, no bursts
    - `RateLimitStrategy.fixedWindow`: Fixed time window limiting
    - `RateLimitStrategy.slidingWindow`: Sliding time window limiting
  - Configurable rate limits (calls per window)
  - Manual reset and disposal

- **WarmUp**: Pre-execute functions for eager loading
  - `WarmUpExtension`, `WarmUpExtension1`, `WarmUpExtension2`
  - Multiple trigger strategies:
    - `WarmUpTrigger.onInit`: Warm up immediately
    - `WarmUpTrigger.onFirstCall`: Warm up on first call
    - `WarmUpTrigger.manual`: Manual warm-up control
  - Periodic refresh support (`keepFresh`)
  - Manual warm-up with `warmUpWith()` for Func1/Func2
  - Resource disposal

- **Compress/Decompress**: Automatic data compression
  - `CompressExtension1`, `CompressBytesExtension1` for compression
  - `DecompressExtension`, `DecompressBytesExtension` for decompression
  - Multiple algorithms:
    - `CompressionAlgorithm.gzip`: GZIP compression
    - `CompressionAlgorithm.zlib`: ZLIB compression
  - Configurable compression levels (none, fast, balanced, best)
  - Automatic threshold-based compression
  - Support for both string and byte data

- **CacheAside**: Cache-aside pattern with automatic loading
  - `CacheAsideExtension1`, `CacheAsideExtension2`
  - `Cache<K,V>` interface for custom cache backends
  - `InMemoryCache` implementation included
  - Configurable TTL for cache entries
  - Multiple refresh strategies:
    - `RefreshStrategy.none`: No automatic refresh
    - `RefreshStrategy.backgroundRefresh`: Refresh in background
    - `RefreshStrategy.refreshOnAccess`: Refresh on next access
  - Cache hit/miss callbacks
  - Manual cache invalidation

## 0.3.0

- **Retry**: Automatic retry with configurable backoff strategies
  - `RetryExtension`, `RetryExtension1`, `RetryExtension2` for `Func`, `Func1`, `Func2`
  - Configurable maximum attempts
  - Multiple backoff strategies:
    - `ConstantBackoff`: Fixed delay between retries
    - `LinearBackoff`: Linearly increasing delays
    - `ExponentialBackoff`: Exponentially increasing delays (default)
    - `FibonacciBackoff`: Fibonacci sequence-based delays
    - `DecorrelatedJitterBackoff`: Randomized exponential backoff
    - `CustomBackoff`: User-defined backoff logic
  - Optional retry predicate (`retryIf`)
  - Retry callbacks (`onRetry`)

- **CircuitBreaker**: Prevent cascading failures with circuit breaker pattern
  - `CircuitBreaker` class with three states (CLOSED, OPEN, HALF_OPEN)
  - `CircuitBreakerExtension`, `CircuitBreakerExtension1`, `CircuitBreakerExtension2`
  - Configurable failure threshold
  - Configurable success threshold for recovery
  - Automatic state transitions
  - State change callbacks
  - Reset functionality

- **Fallback**: Provide fallback values or functions on error
  - `FallbackExtension`, `FallbackExtension1`, `FallbackExtension2`
  - Fallback value or fallback function support
  - Optional fallback predicate (`fallbackIf`)
  - Fallback callbacks (`onFallback`)
  - Chainable fallback cascades

- **Recover**: Execute recovery actions on errors
  - `RecoveryStrategy` class for defining recovery behavior
  - `RecoverExtension`, `RecoverExtension1`, `RecoverExtension2`
  - Configurable recovery actions
  - Optional recovery predicate (`shouldRecover`)
  - Configurable error rethrow behavior
  - Support for cleanup, reconnection, and state reset patterns

## 0.2.0

### Core Concurrency Primitives

- **Lock**: Mutual exclusion mechanism for protecting critical sections
  - `Lock` class with acquire/release methods
  - `LockExtension`, `LockExtension1`, `LockExtension2` for `Func`, `Func1`, `Func2`
  - Support for timeout handling
  - Thread-safe synchronized execution

- **RWLock**: Read-Write lock for concurrent reads and exclusive writes
  - `RWLock` class with separate read/write lock acquisition
  - `ReadLockExtension`, `ReadLockExtension1`, `ReadLockExtension2` for concurrent reads
  - `WriteLockExtension`, `WriteLockExtension1`, `WriteLockExtension2` for exclusive writes
  - Writer priority support
  - Timeout support for both read and write locks

- **Semaphore**: Concurrent execution limiting mechanism
  - `Semaphore` class with configurable maximum concurrent operations
  - `SemaphoreExtension`, `SemaphoreExtension1`, `SemaphoreExtension2`
  - FIFO and LIFO queuing modes
  - Available permits tracking
  - Timeout handling

### Advanced Synchronization

- **Barrier**: Multi-party synchronization mechanism
  - `Barrier` class for coordinating N parties
  - Cyclic mode for reusable barriers
  - Barrier action callbacks
  - `BarrierExtension`, `BarrierExtension1`, `BarrierExtension2`
  - Timeout support with callbacks

- **CountdownLatch**: Wait-for-N-operations pattern
  - `CountdownLatch` class with countdown functionality
  - Completion callbacks
  - `CountdownLatchExtension`, `CountdownLatchExtension1`, `CountdownLatchExtension2`
  - Automatic countdown after function execution

- **Monitor**: Mutex with condition variables
  - `Monitor` class for synchronized execution
  - `waitWhile` and `waitUntil` condition waiting
  - `notify` and `notifyAll` for waking waiters
  - `MonitorExtension`, `MonitorExtension1`, `MonitorExtension2`

### Resource Management

- **Bulkhead**: Resource isolation and pool management
  - `Bulkhead` class with configurable pool size
  - Round-robin pool selection
  - Queue size management
  - `BulkheadExtension`, `BulkheadExtension1`, `BulkheadExtension2`
  - Isolation failure callbacks

- **FunctionQueue**: Sequential or controlled parallel execution
  - `FunctionQueue` class with configurable concurrency
  - FIFO, LIFO, and Priority queuing modes
  - Priority function support
  - Maximum queue size limits
  - Queue change callbacks
  - `QueueExtension1`, `QueueExtension2` for `Func1` and `Func2`

## 0.1.0

### Core Function Wrappers

- `Func<R>`: Asynchronous function wrapper with no parameters
- `Func1<T, R>`: Asynchronous function wrapper with one parameter
- `Func2<T1, T2, R>`: Asynchronous function wrapper with two parameters
- `FuncSync<R>`: Synchronous function wrapper with no parameters

### Timing Control Mechanisms

- **Debounce**: Delay function execution until after a specified time has elapsed
  - `DebounceExtension`, `DebounceExtension1`, `DebounceExtension2`
  - Configurable delay duration
  - Leading and trailing edge support

- **Throttle**: Limit function execution rate to once per specified interval
  - `ThrottleExtension`, `ThrottleExtension1`, `ThrottleExtension2`
  - Configurable interval
  - Leading and trailing edge support

- **Delay**: Add a delay before function execution
  - `DelayExtension`, `DelayExtension1`, `DelayExtension2`
  - Configurable delay duration

- **Defer**: Defer function execution to the next event loop iteration
  - `DeferExtension`, `DeferExtension1`, `DeferExtension2`

- **Timeout**: Add timeout control to function execution
  - `TimeoutExtension`, `TimeoutExtension1`, `TimeoutExtension2`
  - Configurable timeout duration
  - Custom timeout callbacks

- **IdleCallback**: Execute function when system is idle
  - `IdleCallbackExtension`, `IdleCallbackExtension1`, `IdleCallbackExtension2`
  - Configurable idle timeout
