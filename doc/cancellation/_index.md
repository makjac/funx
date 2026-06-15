# Cancellation

Cancellation provides cooperative control over asynchronous work. Decorators in this category let callers abandon a pending execution before it completes, avoiding wasted work and stale results.

The core abstraction is a cancellable wrapper around `Func`, `Func1`, and `Func2`. Each invocation returns a future that completes normally with the function result or, if cancelled, with a `CancelException`.

## Decorators

| Decorator | Description |
|---|---|
| `cancellable()` | Wraps a function so each invocation can be cancelled individually or via a shared `CancelToken`. |

## Primitives

| Type | Description |
|---|---|
| `CancelableOperation<R>` | An operation exposing its result future and a `cancel()` method. |
| `CancelableCompleter<R>` | A completer used to build `CancelableOperation` instances. |
| `CancelToken` | Shared token for cancelling multiple operations at once. |
| `CancelException` | Exception thrown when an operation is cancelled. |

## When to use

- Long-running tasks that may become irrelevant, such as network requests in a Flutter screen that is being disposed.
- Parallel work where the first successful result makes remaining work unnecessary.
- User-triggered actions that should be aborted on a subsequent user action.
