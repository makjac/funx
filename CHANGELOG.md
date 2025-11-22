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

### Type Definitions

- `AsyncFunction<R>`: Type alias for async functions with no parameters
- `AsyncFunction1<T, R>`: Type alias for async functions with one parameter
- `AsyncFunction2<T1, T2, R>`: Type alias for async functions with two parameters
- `SyncFunction<R>`: Type alias for sync functions with no parameters
- Various callback type definitions for error handling and state changes
