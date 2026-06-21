# Rate Limit

## What it is

Rate limit restricts how many executions can occur within a time window. Excess calls either wait or fail, depending on the strategy.

## When to use it

- API clients that must respect a server's rate limit.
- Sending notifications or emails without overwhelming the provider.
- Throttling high-frequency user actions.

## Async / sync support

| Wrapper | Support |
|---|---|
| `Func<R>` | ✅ Async |
| `Func1<T, R>` | ✅ Async |
| `Func2<T1, T2, R>` | ✅ Async |
| `FuncSync<R>` | ❌ No |

## API reference

```dart
// api-reference
// On Func<R>
Func<R> rateLimit({
  required int maxCalls,
  required Duration window,
  RateLimitStrategy strategy = RateLimitStrategy.queue,
});

// On Func1<T, R>
Func1<T, R> rateLimit({
  required int maxCalls,
  required Duration window,
  RateLimitStrategy strategy = RateLimitStrategy.queue,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> rateLimit({
  required int maxCalls,
  required Duration window,
  RateLimitStrategy strategy = RateLimitStrategy.queue,
});

enum RateLimitStrategy { queue, reject }
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `maxCalls` | `int` | required | Maximum allowed executions per window. |
| `window` | `Duration` | required | Sliding time window. |
| `strategy` | `RateLimitStrategy` | `queue` | `queue` waits for the next slot; `reject` throws `RateLimitException`. |

## Examples

### Basic example

```dart
var calls = 0;
final limitedApi = Func<int>(() async => ++calls).rateLimit(
  maxCalls: 2,
  window: Duration(seconds: 1),
  strategy: RateLimitStrategy.tokenBucket,
);

await limitedApi();
await limitedApi();
final third = limitedApi(); // queued until the window refreshes
await third;
// calls == 3
print(calls);
```

### Real-world example

```dart
final sendEmail = Func1<Email, void>((email) async {
  await mailer.send(email);
}).rateLimit(
  maxCalls: 10,
  window: Duration(minutes: 1),
  strategy: RateLimitStrategy.slidingWindow,
);

void main() async {
  await sendEmail(Email());
}
```

## Best practices

- Choose `reject` for user-facing operations that should fail fast.
- Choose `queue` for background tasks where latency is acceptable.
- Set `maxCalls` slightly below the actual provider limit to leave headroom.

## Common pitfalls

- **Bursts at window boundaries**: Sliding windows smooth bursts better than fixed windows; `funx` uses a sliding window.
- **Queue growth**: With `queue`, a sustained overload can create a long backlog.
