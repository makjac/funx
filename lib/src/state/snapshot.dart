/// State checkpointing and restoration.
library;

import 'dart:async';

import 'package:funx/src/core/func.dart';

/// Snapshot of function state.
class Snapshot<S> {
  /// Creates a snapshot with state.
  Snapshot(this.state, this.timestamp);

  /// The captured state.
  final S state;

  /// When the snapshot was created.
  final DateTime timestamp;
}

/// Adds checkpointing and restoration capabilities to functions.
///
/// Allows saving and restoring function state at specific points,
/// useful for rollback, undo/redo, or recovery scenarios.
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
  /// [_inner] is the function to wrap.
  /// [getState] extracts the current state.
  /// [setState] restores a state.
  /// [autoSnapshot] if true, creates snapshot before each execution.
  /// [onSnapshot] is called when a snapshot is created.
  /// [onRestore] is called when a snapshot is restored.
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

  /// Function to get current state.
  final S Function() getState;

  /// Function to set state.
  final void Function(S state) setState;

  /// If true, creates snapshot before each execution.
  final bool autoSnapshot;

  /// Callback when snapshot is created.
  final void Function(Snapshot<S> snapshot)? onSnapshot;

  /// Callback when snapshot is restored.
  final void Function(Snapshot<S> snapshot)? onRestore;

  final List<Snapshot<S>> _snapshots = [];

  /// Creates a snapshot of current state.
  Snapshot<S> createSnapshot() {
    final snapshot = Snapshot(getState(), DateTime.now());
    _snapshots.add(snapshot);
    onSnapshot?.call(snapshot);
    return snapshot;
  }

  /// Restores state from a snapshot.
  void restoreSnapshot(Snapshot<S> snapshot) {
    setState(snapshot.state);
    onRestore?.call(snapshot);
  }

  /// Gets all snapshots.
  List<Snapshot<S>> get snapshots => List.unmodifiable(_snapshots);

  /// Clears all snapshots.
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

/// Adds checkpointing to single-parameter functions.
///
/// Example:
/// ```dart
/// final snapshotted = Func1<int, int>((n) async {
///   return n * 2;
/// }).snapshot(
///   getState: () => myState,
///   setState: (s) => myState = s,
/// );
/// ```
class SnapshotExtension1<T, R, S> extends Func1<T, R> {
  /// Creates a snapshot wrapper for a single-parameter function.
  SnapshotExtension1(
    this._inner, {
    required this.getState,
    required this.setState,
    this.autoSnapshot = false,
    this.onSnapshot,
    this.onRestore,
  }) : super((arg) => throw UnimplementedError());

  final Func1<T, R> _inner;
  final S Function() getState;
  final void Function(S state) setState;
  final bool autoSnapshot;
  final void Function(Snapshot<S> snapshot)? onSnapshot;
  final void Function(Snapshot<S> snapshot)? onRestore;

  final List<Snapshot<S>> _snapshots = [];

  Snapshot<S> createSnapshot() {
    final snapshot = Snapshot(getState(), DateTime.now());
    _snapshots.add(snapshot);
    onSnapshot?.call(snapshot);
    return snapshot;
  }

  void restoreSnapshot(Snapshot<S> snapshot) {
    setState(snapshot.state);
    onRestore?.call(snapshot);
  }

  List<Snapshot<S>> get snapshots => List.unmodifiable(_snapshots);

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

/// Adds checkpointing to two-parameter functions.
///
/// Example:
/// ```dart
/// final snapshotted = Func2<int, int, int>((a, b) async {
///   return a + b;
/// }).snapshot(
///   getState: () => total,
///   setState: (s) => total = s,
/// );
/// ```
class SnapshotExtension2<T1, T2, R, S> extends Func2<T1, T2, R> {
  /// Creates a snapshot wrapper for a two-parameter function.
  SnapshotExtension2(
    this._inner, {
    required this.getState,
    required this.setState,
    this.autoSnapshot = false,
    this.onSnapshot,
    this.onRestore,
  }) : super((arg1, arg2) => throw UnimplementedError());

  final Func2<T1, T2, R> _inner;
  final S Function() getState;
  final void Function(S state) setState;
  final bool autoSnapshot;
  final void Function(Snapshot<S> snapshot)? onSnapshot;
  final void Function(Snapshot<S> snapshot)? onRestore;

  final List<Snapshot<S>> _snapshots = [];

  Snapshot<S> createSnapshot() {
    final snapshot = Snapshot(getState(), DateTime.now());
    _snapshots.add(snapshot);
    onSnapshot?.call(snapshot);
    return snapshot;
  }

  void restoreSnapshot(Snapshot<S> snapshot) {
    setState(snapshot.state);
    onRestore?.call(snapshot);
  }

  List<Snapshot<S>> get snapshots => List.unmodifiable(_snapshots);

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
