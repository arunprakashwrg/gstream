part of '../gstore.dart';

/// Interface to operate on the associated data with the type [T]
class DataController<T> with DisposableMixin {
  DataController._(
    this._decoder,
    this._encoder,
    this._tag,
  );

  /// Gets the nearest [DataController] of the specified type and key to the current context.
  static DataController<T> of<T>(BuildContext context, [String? tag]) {
    return context
        .dependOnInheritedWidgetOfExactType<GStoreScope>()!
        .store
        .get<T>(tag);
  }

  final T Function(dynamic json) _decoder;
  final Map<String, dynamic> Function(T instance) _encoder;
  final List<Map<String, dynamic>> _dataHistory = [];
  final String? _tag;
  final _listeners = <DataCallback<T>>{};

  /// Denotes if we have any registered listeners currently.
  bool get hasListeners => _listeners.isNotEmpty;
  ControllerKey<T> get _key => ControllerKey<T>(_tag);

  /// Denotes the last emitted event.
  Event<T> get lastEvent {
    if (_dataHistory.isEmpty) {
      return Event.initial();
    }

    return Event.success(
      data: _decoder(_dataHistory.last),
    );
  }

  bool _pause = false;
  bool _replayHistoryOnAdd = false;
  DateTime _lastEmittedTime = DateTime.now();
  Duration? _interval;
  Duration? _throttle;

  /// Denotes if this controller is throttle set.
  bool get throttled => _throttle != null;

  /// Denotes if this controller has intervel set.
  bool get intervelled => _interval != null;

  /// Enable to retain history on registering a new controller
  void historyReplay([bool? value]) => _replayHistoryOnAdd = value ?? false;

  /// Called to pause emitting events
  void pauseEvents() => _pause = true;

  void resumeEvents() => _pause = false;

  void notifyListeners() => _invokeListeners(data: lastEvent.data);

  void interval([Duration? duration]) => _interval = duration;

  void removeInterval() => _interval = null;

  void removeThrottle() => _throttle = null;

  void throttle([Duration? duration]) => _throttle = duration;

  void resetModifiers() {
    _pause = false;
    _interval = null;
    _replayHistoryOnAdd = false;
    _throttle = null;
  }

  void _removeListener(DataCallback<T> callback) {
    if (!_listeners.contains(callback)) {
      return;
    }

    gLog('Removing listeners with id: ${callback.id}');
    return _listeners.removeWhere((element) => element == callback);
  }

  void _invokeListeners({
    T? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (error != null) {
      gLog(error, stackTrace);
    }

    if (!hasListeners) {
      return;
    }

    final event = $(() {
      if (data == null) {
        return Event<T>.error(
          error: error,
          stackTrace: stackTrace,
        );
      }

      return Event<T>.success(data: data);
    });

    Future.wait(
      _listeners.map((callback) async {
        final lastEventTime = DateTime.now().difference(_lastEmittedTime);

        if (_throttle != null && lastEventTime < _throttle!) {
          gLog(
            'Ignoring event as controller is throttled... (${lastEventTime.inMilliseconds} ms)',
          );
          return;
        }

        if (_interval != null && lastEventTime < _interval!) {
          gLog(
            'Delaying event due to interval... ${lastEventTime.inMilliseconds} ms',
          );
          Future.delayed(lastEventTime, () {
            callback(event);
            _lastEmittedTime = DateTime.now();
          });

          return;
        }

        callback(event);
        gLog('Event emitted: $event');
        _lastEmittedTime = DateTime.now();
      }),
    );
  }

  void addAsync(Future<T> Function() dataGenerator) {
    if (!hasListeners) {
      return;
    }

    dataGenerator().then(
      add,
      onError: (error, stackTrace) {
        addError(
          error,
          stackTrace ?? StackTrace.current,
        );
      },
    );
  }

  void addError(
    Object error, [
    StackTrace? stackTrace,
  ]) {
    if (!hasListeners) {
      return;
    }

    _invokeListeners(
      error: error,
      stackTrace: stackTrace,
    );
  }

  void add(T data, [bool notifyListeners = true]) {
    if (!hasListeners || _pause) {
      return;
    }

    _dataHistory.add(_encoder(data));

    if (notifyListeners) {
      _invokeListeners(
        data: data,
      );
    }
  }

  void _addListener(DataCallback<T> onEvent) {
    if (_listeners.contains(onEvent)) {
      return;
    }

    _listeners.add(onEvent);

    if (_dataHistory.isNotEmpty) {
      if (_replayHistoryOnAdd) {
        _dataHistory.forEach(
          (element) => onEvent(Event.success(data: _decoder(element))),
        );

        return;
      }

      _invokeListeners(data: _decoder(_dataHistory.last));
    }
  }

  @override
  void dispose() {
    _dataHistory.clear();
    _listeners.clear();
    _pause = false;
    _interval = null;
    _lastEmittedTime = DateTime.now();
    _replayHistoryOnAdd = false;
    _throttle = null;
  }
}
