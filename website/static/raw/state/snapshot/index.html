# Snapshot

## What it is

`snapshot` captures and restores external state before and after function calls. It can create snapshots manually on demand or automatically before each execution, making it useful for undo/redo, rollback, and checkpointing workflows.

## When to use it

- Building undo/redo functionality.
- Checkpointing long-running workflows.
- Rolling back state when an operation fails or needs retrying.

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
SnapshotExtension<R, S> snapshot<S>({
  required S Function() getState,
  required void Function(S state) setState,
  bool autoSnapshot = false,
  void Function(Snapshot<S> snapshot)? onSnapshot,
  void Function(Snapshot<S> snapshot)? onRestore,
});

// On Func1<T, R>
SnapshotExtension1<T, R, S> snapshot<S>({
  required S Function() getState,
  required void Function(S state) setState,
  bool autoSnapshot = false,
  void Function(Snapshot<S> snapshot)? onSnapshot,
  void Function(Snapshot<S> snapshot)? onRestore,
});

// On Func2<T1, T2, R>
SnapshotExtension2<T1, T2, R, S> snapshot<S>({
  required S Function() getState,
  required void Function(S state) setState,
  bool autoSnapshot = false,
  void Function(Snapshot<S> snapshot)? onSnapshot,
  void Function(Snapshot<S> snapshot)? onRestore,
});
```

No parameters on the call itself.

### Returned wrapper methods

```dart
// api-reference
Snapshot<S> createSnapshot();
void restoreSnapshot(Snapshot<S> snapshot);
List<Snapshot<S>> get snapshots;
void clearSnapshots();
```

## Examples

### Basic example

```dart
var counter = 0;

final step = Func<int>(() async {
  return ++counter;
}).snapshot(
  getState: () => counter,
  setState: (s) => counter = s,
);

void main() async {
  await step(); // counter = 1
  final snap = step.createSnapshot();
  await step(); // counter = 2
  step.restoreSnapshot(snap); // counter = 1
  print(counter); // 1
}
```

### Real-world example

```dart
class StateStack {
  final List<Snapshot<Map<String, dynamic>>> _history = [];
  void push(Snapshot<Map<String, dynamic>> s) => _history.add(s);
}

var appState = <String, dynamic>{'theme': 'light'};

final updateState = Func1<Map<String, dynamic>, void>((patch) async {
  appState = {...appState, ...patch};
}).snapshot(
  getState: () => {...appState},
  setState: (s) => appState = {...s},
  autoSnapshot: true,
  onSnapshot: (s) => history.push(s),
);

final history = StateStack();

void main() async {
  await updateState({'theme': 'dark'});
}
```

## Best practices

- Keep snapshots immutable or deep-copy mutable state.
- Enable `autoSnapshot` only when every execution should be reversible.
- Cancel stream subscriptions or clear snapshots when the owning component is disposed.

## Common pitfalls

- **Mutating captured state**: `setState` receives the captured state object; mutations affect the snapshot if it is not copied.
- **Unbounded history**: Snapshot history grows until `clearSnapshots()` is called.
