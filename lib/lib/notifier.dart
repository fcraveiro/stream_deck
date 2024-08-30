import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:collection';

/// A generic notifier class to manage reactive state.
class Notifier<T> extends ChangeNotifier {
  late final NotifierBuilder<T> _notifierBuilder;
  late T _value;
  final List<void Function(T)> _callbacks = [];
  final List<Notifier<T>> _connectors = [];
  final List<NotifierTicker> _tickers = [];
  bool _disposed = false;

  /// Gets the current value.
  T get value => _value;

  /// Sets the value and notifies listeners.
  set value(T value) {
    if (_disposed) {
      // Recreate the state management on first use after dispose.
      _value = value;
      _disposed = false;
    }

    if (!_isEqual(_value, value)) {
      _value = value;
      _notifyListeners();
    }
  }

  /// Constructor initializes the notifier with an initial value.
  Notifier(T value) {
    _value = value;
    _notifierBuilder = NotifierBuilder(this);
  }

  /// Displays the current value using a builder function.
  Widget show(Function(T) builder) {
    return _notifierBuilder.show(builder);
  }

  /// Adds a callback to listen for value changes.
  void listen(void Function(T) callback) {
    if (!_callbacks.contains(callback)) {
      _callbacks.add(callback);
    }
  }

  /// Removes a callback.
  void unlisten(void Function(T) callback) {
    _callbacks.remove(callback);
  }

  /// Connects another Notifier for synchronization.
  void connect(Notifier<T> connector) {
    if (!_connectors.contains(connector)) {
      _connectors.add(connector);
    }
  }

  /// Disconnects a connected Notifier.
  void disconnect(Notifier<T> connector) {
    _connectors.remove(connector);
  }

  /// Disconnects all connected Notifiers.
  void disconnectAll() {
    _connectors.clear();
  }

  /// Connects a NotifierTicker for synchronization.
  void connectTicker(NotifierTicker ticker) {
    if (!_tickers.contains(ticker)) {
      _tickers.add(ticker);
    }
  }

  /// Disconnects a connected NotifierTicker.
  void disconnectTicker(NotifierTicker ticker) {
    _tickers.remove(ticker);
  }

  /// Disconnects all connected NotifierTickers.
  void disconnectAllTickers() {
    _tickers.clear();
  }

  /// Disposes the Notifier and clears resources.
  @override
  void dispose() {
    if (!_disposed) {
      _callbacks.clear();
      _connectors.clear();
      _tickers.clear();
      super.dispose();
      _disposed = true;
    }
  }

  /// Notifies all listeners, connectors, and tickers.
  void _notifyListeners() {
    for (var callback in _callbacks) {
      callback(_value);
    }
    for (var connector in _connectors) {
      connector.value = _value;
    }
    for (var ticker in _tickers) {
      ticker.tick();
    }
    notifyListeners();
  }

  /// Utility to check equality, handling complex types properly.
  bool _isEqual(T a, T b) {
    if (a is List && b is List) {
      return listEquals(a, b);
    }
    if (a is Map && b is Map) {
      return mapEquals(a, b);
    }
    return a == b;
  }
}

/// A specialized notifier for managing lists in a reactive way.
class NotifierList<T> extends Notifier<UnmodifiableListView<T>> {
  late List<T> _internalList;

  /// Constructor initializes the notifier list with an optional initial list.
  NotifierList([List<T>? initialList]) : super(UnmodifiableListView([])) {
    _internalList = List<T>.from(initialList ?? []);
    _updateValue();
  }

  /// Gets the length of the internal list.
  int get length => _internalList.length;

  /// Adds an item to the list and notifies listeners.
  void add(T item) {
    _internalList.add(item);
    _updateValue();
  }

  /// Adds multiple items to the list and notifies listeners.
  void addAll(Iterable<T> items) {
    _internalList.addAll(items);
    _updateValue();
  }

  /// Inserts an item at a specified index and notifies listeners.
  void insert(int index, T item) {
    _internalList.insert(index, item);
    _updateValue();
  }

  /// Removes an item from the list and notifies listeners if the list changed.
  bool remove(T item) {
    final removed = _internalList.remove(item);
    if (removed) _updateValue();
    return removed;
  }

  /// Removes the item at the specified index and notifies listeners.
  void removeAt(int index) {
    _internalList.removeAt(index);
    _updateValue();
  }

  /// Removes items that match the provided test function and notifies listeners if the list changed.
  void removeWhere(bool Function(T) test) {
    final originalLength = _internalList.length;
    _internalList.removeWhere(test);
    if (_internalList.length != originalLength) _updateValue();
  }

  /// Clears all items in the list and notifies listeners.
  void clear() {
    if (_internalList.isNotEmpty) {
      _internalList.clear();
      _updateValue();
    }
  }

  /// Sorts the list using the provided compare function and notifies listeners.
  void sort([int Function(T, T)? compare]) {
    _internalList.sort(compare);
    _updateValue();
  }

  /// Shuffles the list and notifies listeners.
  void shuffle([Random? random]) {
    _internalList.shuffle(random);
    _updateValue();
  }

  /// Maps each item in the list to a new value.
  List<R> map<R>(R Function(T) toElement) {
    return _internalList.map(toElement).toList();
  }

  /// Filters items in the list based on a test function.
  NotifierList<T> where(bool Function(T) test) {
    return NotifierList<T>(_internalList.where(test).toList());
  }

  /// Finds the first item that matches a test function.
  T? firstWhere(bool Function(T) test, {T Function()? orElse}) {
    return _internalList.firstWhere(test, orElse: orElse);
  }

  /// Applies an action to each item in the list.
  void forEach(void Function(T) action) {
    _internalList.forEach(action);
  }

  /// Accesses an item at a specific index.
  T operator [](int index) => _internalList[index];

  /// Sets an item at a specific index and notifies listeners if the value changed.
  void operator []=(int index, T value) {
    if (_internalList[index] != value) {
      _internalList[index] = value;
      _updateValue();
    }
  }

  /// Overrides the value setter to update the internal list if it has changed.
  @override
  set value(UnmodifiableListView<T> newValue) {
    if (!listEquals(_internalList, newValue)) {
      _internalList = List<T>.from(newValue);
      _updateValue();
    }
  }

  /// Updates the exposed value of the list.
  void _updateValue() {
    super.value = UnmodifiableListView(_internalList);
  }
}

/// A ticker class for managing periodic ticks.
class NotifierTicker {
  late final NotifierBuilder<bool> _notifierBuilder =
      NotifierBuilder(_notifier);
  final ValueNotifier<bool> _notifier = ValueNotifier(false);
  final List<void Function()> _callbacks = [];
  final List<NotifierTicker> _connectors = [];

  /// Toggles the tick value and notifies listeners.
  void tick() {
    _notifier.value = !_notifier.value;
    for (var callback in _callbacks) {
      callback();
    }
    for (var connector in _connectors) {
      connector.tick();
    }
  }

  /// Adds a callback to listen for ticks.
  void listen(void Function() callback) {
    if (!_callbacks.contains(callback)) {
      _callbacks.add(callback);
    }
  }

  /// Connects another NotifierTicker for synchronization.
  void connect(NotifierTicker connector) {
    if (!_connectors.contains(connector)) {
      _connectors.add(connector);
    }
  }

  /// Displays the current tick value using a builder function.
  Widget show(Function builder) {
    return _notifierBuilder.show((value) => builder());
  }

  /// Disposes the NotifierTicker and clears resources.
  void dispose() {
    _callbacks.clear();
    _connectors.clear();
    _notifier.dispose();
  }
}

/// A helper class to build widgets based on the state of Notifiers.
class NotifierBuilder<T> {
  final Listenable _notifier;

  /// Constructor initializes the builder with a Listenable.
  NotifierBuilder(Listenable notifier) : _notifier = notifier;

  /// Builds and returns a widget using the provided builder function.
  Widget show(Function(T) builder) {
    if (_notifier is Notifier<T>) {
      return AnimatedBuilder(
        animation: _notifier,
        builder: (context, _) => builder((_notifier).value),
      );
    } else if (_notifier is ValueListenable<T>) {
      return ValueListenableBuilder(
        valueListenable: _notifier,
        builder: (context, value, _) => builder(value),
      );
    } else {
      throw Exception('Unsupported Listenable type: ${_notifier.runtimeType}');
    }
  }
}
