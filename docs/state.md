# State

State decorators capture and restore application state around function execution.

---

## snapshot

### What it is

Captures and restores external state before and after function calls. Supports manual snapshots and automatic snapshots before each execution.

### When to use it

- Undo/redo functionality
- Rollback operations
- Checkpointing long-running workflows

### Async / sync support

| `Func<R>` | `Func1<T, R>` | `Func2<T1, T2, R>` | `FuncSync<R>` |
|-----------|---------------|--------------------|---------------|
| ✅ | ✅ | ✅ | ❌ |

### API reference

```dart
// api-reference
SnapshotExtension<R, S> snapshot<S>({
  required S Function() getState,
  required void Function(S state) setState,
  bool autoSnapshot = false,
  void Function(Snapshot<S> snapshot)? onSnapshot,
  void Function(Snapshot<S> snapshot)? onRestore,
})
```

Methods:

- `Snapshot<S> createSnapshot()` — capture current state.
- `void restoreSnapshot(Snapshot<S> snapshot)` — restore state.
- `List<Snapshot<S>> get snapshots` — immutable history.
- `void clearSnapshots()` — remove all snapshots.

### Examples

**Minimal**

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

**Real world**

```dart
class UndoStack {
  final List<Snapshot<Document>> _history = [];
  void push(Snapshot<Document> s) => _history.add(s);
}

extension DocumentExt on Document {
  Document apply(EditOperation op) => this; // placeholder transformation
}

var document = Document();
final undoStack = UndoStack();

final edit = Func1<EditOperation, void>((op) async {
  document = document.apply(op);
}).snapshot(
  getState: () => document,
  setState: (d) => document = d,
  autoSnapshot: true,
  onSnapshot: (s) => undoStack.push(s),
);

void main() async {
  await edit(EditOperation());
}
```

### Best practices

- Keep snapshots immutable or deep-copy mutable state.
- Enable `autoSnapshot` only when every execution should be reversible.

### Common pitfalls

- `setState` receives the captured state object; mutations affect the snapshot if it is not copied.
- Snapshot history grows unbounded unless `clearSnapshots()` is called.