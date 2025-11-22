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
