# Idle Callback

## What it is

Idle callback executes the wrapped function only when a custom detector reports that the system is idle. It polls the detector at a configurable interval until the detector returns `true`.

## When to use it

- Running heavy maintenance tasks when the app is not busy.
- Compressing logs or flushing analytics when CPU usage is low.
- Deferred image decoding or cache cleanup.

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
Func<R> idleCallback({
  Duration? checkInterval,
  IdleDetector? idleDetector,
});

// On Func1<T, R>
Func1<T, R> idleCallback({
  Duration? checkInterval,
  IdleDetector? idleDetector,
});

// On Func2<T1, T2, R>
Func2<T1, T2, R> idleCallback({
  Duration? checkInterval,
  IdleDetector? idleDetector,
});

typedef IdleDetector = bool Function();
bool defaultIdleDetector() => true;
```

### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `checkInterval` | `Duration` | `100ms` | How often to poll the detector. |
| `idleDetector` | `IdleDetector` | `defaultIdleDetector` | Function that returns `true` when the system is idle. |

## Examples

### Basic example

```dart
var isIdle = false;

final cleanup = Func<String>(() async => 'cleaned').idleCallback(
  checkInterval: Duration(milliseconds: 50),
  idleDetector: () => isIdle,
);

// Later:
isIdle = true;
print(await cleanup()); // cleaned
```

### Real-world example

```dart
var cpuLoad = 0.1;
var pendingFrames = 0;

bool isSystemIdle() => cpuLoad < 0.3 && pendingFrames == 0;

final compressLogs = Func<String>(() async => 'logs compressed')
  .idleCallback(
    checkInterval: Duration(seconds: 1),
    idleDetector: isSystemIdle,
  );

await compressLogs(); // runs only when the app is idle
```

## Best practices

- Keep the detector cheap because it runs on every polling tick.
- Use a longer `checkInterval` for heavy background work to reduce overhead.
- Always provide a timeout or cancellation mechanism in production so the call does not hang forever if the system never becomes idle.

## Common pitfalls

- **Hanging forever**: With the default detector, the function runs at the next tick, but a custom detector that never returns `true` leaves the future pending indefinitely.
- **Expensive detector**: Running heavy logic inside `idleDetector` defeats the purpose of deferring work.
