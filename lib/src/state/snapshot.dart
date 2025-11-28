/// State checkpointing and restoration.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Represents a point-in-time capture of function state.
///
/// Stores the state value along with a timestamp indicating when the
/// snapshot was created. Used for checkpointing, rollback, undo/redo
/// functionality, or state recovery scenarios. Snapshots are immutable
/// once created, ensuring state integrity.
///
/// Example:
/// ```dart
/// final snapshot = Snapshot(userCount, DateTime.now());
/// print('State at ${snapshot.timestamp}: ${snapshot.state}');
/// ```
class Snapshot<S> {
  /// Creates a snapshot with the given state and timestamp.
  ///
  /// The [state] parameter holds the captured state value. The
  /// [timestamp] parameter records when the snapshot was created,
  /// typically set to [DateTime.now].
  ///
  /// Example:
  /// ```dart
  /// final snap = Snapshot(currentValue, DateTime.now());
  /// ```
  Snapshot(this.state, this.timestamp);

  /// The captured state.
  final S state;

  /// When the snapshot was created.
  final DateTime timestamp;
}

/// Adds state checkpointing and restoration to functions.
///
/// Enables saving and restoring function state at specific points,
/// implementing rollback, undo/redo, or crash recovery functionality.
/// The [getState] function extracts current state, while [setState]
/// restores it. Snapshots can be created automatically before each
/// execution or manually on demand. This pattern is ideal for stateful
/// operations where you need to track changes or support undo
/// operations, such as document editing, game state management, or
/// transactional processing.
///
/// Example:
/// ```dart
/// int counter = 0;
/// final counting = Func<int>(() async {
///   return ++counter;
/// }).snapshot(
///   getState: () => counter,
///   setState: (state) => counter = state,
///   onSnapshot: (snap) => print('Saved: ${snap.state}'),
/// );
///
/// await counting(); // counter = 1
/// final snap = counting.createSnapshot();
/// await counting(); // counter = 2
/// counting.restoreSnapshot(snap); // counter = 1
/// ```
class SnapshotExtension<R, S> extends Func<R> {
  /// Creates a snapshot wrapper for a no-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [getState]
  /// function extracts the current state value that should be captured.
  /// The [setState] function restores a previously captured state. When
  /// [autoSnapshot] is true, a snapshot is created automatically before
  /// each execution. The optional [onSnapshot] callback is invoked when
  /// a snapshot is created. The optional [onRestore] callback is invoked
  /// when a snapshot is restored.
  ///
  /// Example:
  /// ```dart
  /// final snapshotted = SnapshotExtension(
  ///   myFunc,
  ///   getState: () => currentState,
  ///   setState: (s) => currentState = s,
  ///   autoSnapshot: true,
  /// );
  /// ```
  SnapshotExtension(
    this._inner, {
    required this.getState,
    required this.setState,
    this.autoSnapshot = false,
    this.onSnapshot,
    this.onRestore,
  }) : super(() => throw UnimplementedError());

  final Func<R> _inner;

  /// Function that extracts the current state value.
  final S Function() getState;

  /// Function that restores the state to a given value.
  final void Function(S state) setState;

  /// Whether to automatically create snapshots before each execution.
  final bool autoSnapshot;

  /// Optional callback invoked when a snapshot is created.
  final void Function(Snapshot<S> snapshot)? onSnapshot;

  /// Optional callback invoked when a snapshot is restored.
  final void Function(Snapshot<S> snapshot)? onRestore;

  final List<Snapshot<S>> _snapshots = [];

  /// Creates and stores a snapshot of the current state.
  ///
  /// Captures the current state using [getState], creates a [Snapshot]
  /// with the current timestamp, adds it to the snapshot history, and
  /// invokes the [onSnapshot] callback if provided.
  ///
  /// Returns the created [Snapshot] instance.
  ///
  /// Example:
  /// ```dart
  /// final snap = snapshotFunc.createSnapshot();
  /// print('Captured state: ${snap.state}');
  /// ```
  Snapshot<S> createSnapshot() {
    final snapshot = Snapshot(getState(), DateTime.now());
    _snapshots.add(snapshot);
    onSnapshot?.call(snapshot);
    return snapshot;
  }

  /// Restores the state from a given snapshot.
  ///
  /// Sets the current state to the value stored in the [snapshot] using
  /// [setState]. Invokes the [onRestore] callback if provided. This does
  /// not remove the snapshot from history.
  ///
  /// Example:
  /// ```dart
  /// final snap = snapshotFunc.createSnapshot();
  /// // ... state changes ...
  /// snapshotFunc.restoreSnapshot(snap); // Revert to saved state
  /// ```
  void restoreSnapshot(Snapshot<S> snapshot) {
    setState(snapshot.state);
    onRestore?.call(snapshot);
  }

  /// Returns an immutable list of all created snapshots.
  ///
  /// The snapshots are ordered chronologically from oldest to newest.
  /// This list cannot be modified directly. Use [clearSnapshots] to
  /// remove all snapshots.
  ///
  /// Example:
  /// ```dart
  /// for (final snap in snapshotFunc.snapshots) {
  ///   print('State at ${snap.timestamp}: ${snap.state}');
  /// }
  /// ```
  List<Snapshot<S>> get snapshots => List.unmodifiable(_snapshots);

  /// Clears all stored snapshots from history.
  ///
  /// Removes all snapshots from the internal list. This does not affect
  /// the current state. Use this to free memory when snapshots are no
  /// longer needed.
  ///
  /// Example:
  /// ```dart
  /// snapshotFunc.clearSnapshots(); // Remove all snapshots
  /// ```
  void clearSnapshots() {
    _snapshots.clear();
  }

  @override
  Future<R> call() async {
    if (autoSnapshot) {
      createSnapshot();
    }
    return _inner();
  }
}

/// Adds state checkpointing and restoration to one-parameter functions.
///
/// Enables saving and restoring function state at specific points,
/// implementing rollback, undo/redo, or crash recovery functionality.
/// The [getState] function extracts current state, while [setState]
/// restores it. Snapshots can be created automatically before each
/// execution or manually on demand. This pattern is ideal for stateful
/// operations where you need to track changes or support undo
/// operations, such as document editing, game state management, or
/// transactional processing.
///
/// Example:
/// ```dart
/// int processCount = 0;
/// final process = Func1<String, int>((data) async {
///   processCount++;
///   return data.length;
/// }).snapshot(
///   getState: () => processCount,
///   setState: (state) => processCount = state,
/// );
///
/// await process('test'); // processCount = 1
/// final snap = process.createSnapshot();
/// await process('hello'); // processCount = 2
/// process.restoreSnapshot(snap); // processCount = 1
/// ```
class SnapshotExtension1<T, R, S> extends Func1<T, R> {
  /// Creates a snapshot wrapper for a one-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [getState]
  /// function extracts the current state value that should be captured.
  /// The [setState] function restores a previously captured state. When
  /// [autoSnapshot] is true, a snapshot is created automatically before
  /// each execution. The optional [onSnapshot] callback is invoked when
  /// a snapshot is created. The optional [onRestore] callback is invoked
  /// when a snapshot is restored.
  ///
  /// Example:
  /// ```dart
  /// final snapshotted = SnapshotExtension1(
  ///   myFunc1,
  ///   getState: () => currentState,
  ///   setState: (s) => currentState = s,
  ///   autoSnapshot: true,
  /// );
  /// ```
  SnapshotExtension1(
    this._inner, {
    required this.getState,
    required this.setState,
    this.autoSnapshot = false,
    this.onSnapshot,
    this.onRestore,
  }) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;

  /// Function that extracts the current state value.
  final S Function() getState;

  /// Function that restores the state to a given value.
  final void Function(S state) setState;

  /// Whether to automatically create snapshots before each execution.
  final bool autoSnapshot;

  /// Optional callback invoked when a snapshot is created.
  final void Function(Snapshot<S> snapshot)? onSnapshot;

  /// Optional callback invoked when a snapshot is restored.
  final void Function(Snapshot<S> snapshot)? onRestore;

  final List<Snapshot<S>> _snapshots = [];

  /// Creates and stores a snapshot of the current state.
  ///
  /// Captures the current state using [getState], creates a [Snapshot]
  /// with the current timestamp, adds it to the snapshot history, and
  /// invokes the [onSnapshot] callback if provided.
  ///
  /// Returns the created [Snapshot] instance.
  ///
  /// Example:
  /// ```dart
  /// final snap = snapshotFunc.createSnapshot();
  /// print('Captured state: ${snap.state}');
  /// ```
  Snapshot<S> createSnapshot() {
    final snapshot = Snapshot(getState(), DateTime.now());
    _snapshots.add(snapshot);
    onSnapshot?.call(snapshot);
    return snapshot;
  }

  /// Restores the state from a given snapshot.
  ///
  /// Sets the current state to the value stored in the [snapshot] using
  /// [setState]. Invokes the [onRestore] callback if provided. This does
  /// not remove the snapshot from history.
  ///
  /// Example:
  /// ```dart
  /// final snap = snapshotFunc.createSnapshot();
  /// // ... state changes ...
  /// snapshotFunc.restoreSnapshot(snap); // Revert to saved state
  /// ```
  void restoreSnapshot(Snapshot<S> snapshot) {
    setState(snapshot.state);
    onRestore?.call(snapshot);
  }

  /// Returns an immutable list of all created snapshots.
  ///
  /// The snapshots are ordered chronologically from oldest to newest.
  /// This list cannot be modified directly. Use [clearSnapshots] to
  /// remove all snapshots.
  ///
  /// Example:
  /// ```dart
  /// for (final snap in snapshotFunc.snapshots) {
  ///   print('State at ${snap.timestamp}: ${snap.state}');
  /// }
  /// ```
  List<Snapshot<S>> get snapshots => List.unmodifiable(_snapshots);

  /// Clears all stored snapshots from history.
  ///
  /// Removes all snapshots from the internal list. This does not affect
  /// the current state. Use this to free memory when snapshots are no
  /// longer needed.
  ///
  /// Example:
  /// ```dart
  /// snapshotFunc.clearSnapshots(); // Remove all snapshots
  /// ```
  void clearSnapshots() {
    _snapshots.clear();
  }

  @override
  Future<R> call(T arg) async {
    if (autoSnapshot) {
      createSnapshot();
    }
    return _inner(arg);
  }
}

/// Adds state checkpointing and restoration to two-parameter functions.
///
/// Enables saving and restoring function state at specific points,
/// implementing rollback, undo/redo, or crash recovery functionality.
/// The [getState] function extracts current state, while [setState]
/// restores it. Snapshots can be created automatically before each
/// execution or manually on demand. This pattern is ideal for stateful
/// operations where you need to track changes or support undo
/// operations, such as document editing, game state management, or
/// transactional processing.
///
/// Example:
/// ```dart
/// Map<String, int> cache = {};
/// final merge = Func2<String, int, String>((key, value) async {
///   cache[key] = value;
///   return '$key=$value';
/// }).snapshot(
///   getState: () => Map.from(cache),
///   setState: (state) => cache = Map.from(state),
/// );
///
/// await merge('a', 1); // cache = {'a': 1}
/// final snap = merge.createSnapshot();
/// await merge('b', 2); // cache = {'a': 1, 'b': 2}
/// merge.restoreSnapshot(snap); // cache = {'a': 1}
/// ```
class SnapshotExtension2<T1, T2, R, S> extends Func2<T1, T2, R> {
  /// Creates a snapshot wrapper for a two-parameter function.
  ///
  /// The [_inner] parameter is the function to wrap. The [getState]
  /// function extracts the current state value that should be captured.
  /// The [setState] function restores a previously captured state. When
  /// [autoSnapshot] is true, a snapshot is created automatically before
  /// each execution. The optional [onSnapshot] callback is invoked when
  /// a snapshot is created. The optional [onRestore] callback is invoked
  /// when a snapshot is restored.
  ///
  /// Example:
  /// ```dart
  /// final snapshotted = SnapshotExtension2(
  ///   myFunc2,
  ///   getState: () => currentState,
  ///   setState: (s) => currentState = s,
  ///   autoSnapshot: true,
  /// );
  /// ```
  SnapshotExtension2(
    this._inner, {
    required this.getState,
    required this.setState,
    this.autoSnapshot = false,
    this.onSnapshot,
    this.onRestore,
  }) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;

  /// Function that extracts the current state value.
  final S Function() getState;

  /// Function that restores the state to a given value.
  final void Function(S state) setState;

  /// Whether to automatically create snapshots before each execution.
  final bool autoSnapshot;

  /// Optional callback invoked when a snapshot is created.
  final void Function(Snapshot<S> snapshot)? onSnapshot;

  /// Optional callback invoked when a snapshot is restored.
  final void Function(Snapshot<S> snapshot)? onRestore;

  final List<Snapshot<S>> _snapshots = [];

  /// Creates and stores a snapshot of the current state.
  ///
  /// Captures the current state using [getState], creates a [Snapshot]
  /// with the current timestamp, adds it to the snapshot history, and
  /// invokes the [onSnapshot] callback if provided.
  ///
  /// Returns the created [Snapshot] instance.
  ///
  /// Example:
  /// ```dart
  /// final snap = snapshotFunc.createSnapshot();
  /// print('Captured state: ${snap.state}');
  /// ```
  Snapshot<S> createSnapshot() {
    final snapshot = Snapshot(getState(), DateTime.now());
    _snapshots.add(snapshot);
    onSnapshot?.call(snapshot);
    return snapshot;
  }

  /// Restores the state from a given snapshot.
  ///
  /// Sets the current state to the value stored in the [snapshot] using
  /// [setState]. Invokes the [onRestore] callback if provided. This does
  /// not remove the snapshot from history.
  ///
  /// Example:
  /// ```dart
  /// final snap = snapshotFunc.createSnapshot();
  /// // ... state changes ...
  /// snapshotFunc.restoreSnapshot(snap); // Revert to saved state
  /// ```
  void restoreSnapshot(Snapshot<S> snapshot) {
    setState(snapshot.state);
    onRestore?.call(snapshot);
  }

  /// Returns an immutable list of all created snapshots.
  ///
  /// The snapshots are ordered chronologically from oldest to newest.
  /// This list cannot be modified directly. Use [clearSnapshots] to
  /// remove all snapshots.
  ///
  /// Example:
  /// ```dart
  /// for (final snap in snapshotFunc.snapshots) {
  ///   print('State at ${snap.timestamp}: ${snap.state}');
  /// }
  /// ```
  List<Snapshot<S>> get snapshots => List.unmodifiable(_snapshots);

  /// Clears all stored snapshots from history.
  ///
  /// Removes all snapshots from the internal list. This does not affect
  /// the current state. Use this to free memory when snapshots are no
  /// longer needed.
  ///
  /// Example:
  /// ```dart
  /// snapshotFunc.clearSnapshots(); // Remove all snapshots
  /// ```
  void clearSnapshots() {
    _snapshots.clear();
  }

  @override
  Future<R> call(T1 arg1, T2 arg2) async {
    if (autoSnapshot) {
      createSnapshot();
    }
    return _inner(arg1, arg2);
  }
}
