// ignore_for_file: avoid_positional_boolean_parameters, use_setters_to_change_properties

part of '../gstore.dart';

/// Interface to operate on the associated data with the type [T]
class DataController<T> with DisposableMixin {
  DataController._(
    this._tag,
    this._persistanceCallback,
  )   : _event = Event<T>.initial(),
        _prevEvent = Event<T>.initial();

  /// Gets the nearest [DataController] of the specified type and key to the current context.
  static DataController<T> of<T>(BuildContext context, [String? tag]) {
    return context
        .dependOnInheritedWidgetOfExactType<GStoreScope>()!
        .store
        .get<T>(tag);
  }

  final PersistanceCallback<T>? _persistanceCallback;
  final String? _tag;
  final _listeners = <DataCallback<T>>{};

  /// Denotes if we have any registered listeners currently.
  bool get hasListeners => _listeners.isNotEmpty;
  ControllerKey<T> get _key => ControllerKey<T>(_tag);

  Event<T> _event;
  Event<T> _prevEvent;
  bool _pause = false;
  DateTime _lastEmittedTime = DateTime.now();
  Duration? _interval;
  Duration? _throttle;

  /// Denotes if this controller is throttle set.
  bool get throttled => _throttle != null;

  /// Denotes if this controller has intervel set.
  bool get intervelled => _interval != null;

  set _set(Event<T> event) {
    _prevEvent = _event;
    _event = event;
    notifyListeners();
  }

  Event<T> get currentEvent => _event;

  Event<T> get previousEvent => _prevEvent;

  /// Called to pause emitting events
  void pauseEvents() => _pause = true;

  void resumeEvents() => _pause = false;

  void interval([Duration? duration]) => _interval = duration;

  void removeInterval() => _interval = null;

  void removeThrottle() => _throttle = null;

  void throttle([Duration? duration]) => _throttle = duration;

  void resetModifiers() {
    _pause = false;
    _interval = null;
    _throttle = null;
  }

  void _removeListener(DataCallback<T> callback) {
    if (!_listeners.contains(callback)) {
      return;
    }

    gLog('Removing listeners with id: ${callback.id}');
    return _listeners.removeWhere((element) => element == callback);
  }

  void notifyListeners() {
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
            callback(currentEvent);
            _lastEmittedTime = DateTime.now();
          });

          return;
        }

        callback(currentEvent);
        gLog('Event emitted: $currentEvent');
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
      // ignore: avoid_types_on_closure_parameters
      onError: (Object error, StackTrace? stackTrace) {
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

    gLog(error, stackTrace);

    _set = Event<T>.error(
      error: error,
      stackTrace: stackTrace,
    );
  }

  void add(T data, [bool notifyListeners = true]) {
    if (!hasListeners || _pause) {
      return;
    }

    _set = Event<T>.success(data: data);
  }

  void _addListener(DataCallback<T> onEvent) {
    if (_listeners.contains(onEvent)) {
      return;
    }

    _listeners.add(onEvent);
  }

  @override
  void dispose() {
    _listeners.clear();
    _pause = false;
    _interval = null;
    _lastEmittedTime = DateTime.now();
    _throttle = null;
  }
}
