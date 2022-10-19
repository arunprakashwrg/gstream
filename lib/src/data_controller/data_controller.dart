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
  Event<T> _prevEvent = Event<T>.initial();
  bool _pause = false;
  DateTime _lastEmittedTime = DateTime.now();
  Duration? _interval;
  Duration? _throttle;

  /// Denotes if this controller is throttle set.
  bool get throttled => _throttle != null;

  /// Denotes if this controller has intervel set.
  bool get intervelled => _interval != null;

  void _setState(Event<T> event, [bool shouldNotify = true]) {
    // TODO: Bugged: Previous and current state is same
    _prevEvent = _event;
    print('Previous Event: ${_prevEvent.data}');
    _event = event;
    print('Current Event: ${_event.data}');

    if (shouldNotify) {
      notifyListeners();
    }
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
    gLog('${_listeners.length} listeners are currently listening.');

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
        gLog('Event emitted: ${currentEvent.data?.toString()}');
        _lastEmittedTime = DateTime.now();
      }),
    );
  }

  void addAsync(Future<T> Function() dataGenerator) {
    if (_pause) {
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
    if (_pause) {
      return;
    }

    gLog(error, stackTrace);

    _setState(Event<T>.error(
      error: error,
      stackTrace: stackTrace,
    ));
  }

  void add(T data, [bool notifyListeners = true]) {
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
    _interval = null;
    _lastEmittedTime = DateTime.now();
    _throttle = null;
  }

  @override
  List<Object?> get props {
    return [
      _listeners,
      _pause,
      _interval,
      _lastEmittedTime,
      _throttle,
      currentEvent,
      previousEvent,
      _key,
      _tag,
    ];
  }
}
