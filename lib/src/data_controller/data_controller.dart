// ignore_for_file: avoid_positional_boolean_parameters, use_setters_to_change_properties

part of '../gstore.dart';

/// Interface to operate on the associated data with the type [T]

// ignore: must_be_immutable
class DataController<T> extends Equatable with DisposableMixin {
  DataController._(
    this._tag,
    this._persistanceCallback,
  );

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

  Event<T> _event = Event<T>.initial();
  bool _pause = false;
  DateTime _lastEmittedTime = DateTime.now();
  Duration? _intervalDuration;
  Duration? _throttleDuration;

  /// Denotes if this controller is throttle set.
  bool get throttled => _throttleDuration != null;

  /// Denotes if this controller has intervel set.
  bool get intervelled => _intervalDuration != null;

  bool get isInDefaultState => _event.isInitial;

  void _setState(Event<T> newEvent, [bool shouldNotify = true]) {
    // TODO: Bugged: Previous and current state is same
    print('Previous Event: ${_event.data}');
    _event = newEvent;
    print('Current Event: ${_event.data}');

    if (shouldNotify) {
      _internalNotifyListeners(_event);
    }
  }

  Event<T> get currentEvent => _event;

  /// Called to pause emitting events
  void pauseEvents() => _pause = true;

  void resumeEvents() => _pause = false;

  void interval([Duration? duration]) => _intervalDuration = duration;

  void removeInterval() => _intervalDuration = null;

  void removeThrottle() => _throttleDuration = null;

  void throttle([Duration? duration]) => _throttleDuration = duration;

  void resetModifiers() {
    _pause = false;
    _intervalDuration = null;
    _throttleDuration = null;
  }

  void _removeListener(DataCallback<T> callback) {
    if (!_listeners.contains(callback)) {
      return;
    }

    gLog('Removing listeners with id: ${callback.id}');
    return _listeners.removeWhere((element) => element == callback);
  }

  void NotifyListeners() {
    return _internalNotifyListeners(currentEvent);
  }

  void _internalNotifyListeners(Event<T> event) {
    gLog('${_listeners.length} listeners are currently listening.');

    Future.wait(
      _listeners.map((callback) async {
        final lastEventTime = DateTime.now().difference(_lastEmittedTime);

        if (_throttleDuration != null && lastEventTime < _throttleDuration!) {
          gLog(
            'Ignoring event as controller is throttled... (${lastEventTime.inMilliseconds} ms)',
          );
          return;
        }

        if (_intervalDuration != null && lastEventTime < _intervalDuration!) {
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
        gLog('Event emitted: ${event.data?.toString()}');
        _lastEmittedTime = DateTime.now();
      }),
    );
  }

  void setAsync(Future<T> Function() dataGenerator) {
    if (_pause) {
      return;
    }

    dataGenerator().then(
      set,
      // ignore: avoid_types_on_closure_parameters
      onError: (Object error, StackTrace? stackTrace) {
        setError(
          error,
          stackTrace ?? StackTrace.current,
        );
      },
    );
  }

  void setError(
    Object error, [
    StackTrace? stackTrace,
  ]) {
    if (_pause) {
      return;
    }

    gLog(error, stackTrace);

    _setState(Event<T>.error(
      error: error,
      stackTrace: stackTrace,
    ));
  }

  void set(T data, [bool notifyListeners = true]) {
    if (_pause) {
      return;
    }

    _setState(Event<T>.success(data: data), notifyListeners);
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
    _intervalDuration = null;
    _lastEmittedTime = DateTime.now();
    _throttleDuration = null;
  }

  @override
  List<Object?> get props {
    return [
      _listeners,
      _pause,
      _intervalDuration,
      _lastEmittedTime,
      _throttleDuration,
      currentEvent,
      _key,
      _tag,
    ];
  }
}
