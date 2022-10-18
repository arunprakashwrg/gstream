part of '../gstore.dart';

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
  final _listeners = <DataCallback<T>>[];

  bool get hasListeners => _listeners.isNotEmpty;
  ControllerKey<T> get _key => ControllerKey<T>(_tag);
  DataEvent<T> get lastEvent {
    if (_dataHistory.isEmpty) {
      return DataEvent.initial();
    }

    return DataEvent.success(
      data: _decoder(_dataHistory.last),
    );
  }

  bool _pause = false;
  bool _replayHistoryOnAdd = false;
  DateTime _lastEmittedTime = DateTime.now();
  Duration? _interval;
  Duration? _throttle;

  bool get throttled => _throttle != null;
  bool get intervelled => _interval != null;

  void withReplay(bool value) => _replayHistoryOnAdd = value;

  void pauseEvents() => _pause = true;

  void resumeEvents() => _pause = false;

  void notifyListeners() => _invokeListeners(data: lastEvent.data);

  void interval([Duration? duration]) => _interval = duration;

  void throttle([Duration? duration]) => _throttle = duration;

  void _invokeListeners({
    T? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!hasListeners) {
      return;
    }

    final event = $(() {
      if (data == null) {
        return DataEvent<T>.error(
          error: error,
          stackTrace: stackTrace,
        );
      }

      return DataEvent<T>.success(data: data);
    });

    Future.wait(
      _listeners.map((callback) async {
        final lastEventTime = DateTime.now().difference(_lastEmittedTime);

        if (_throttle != null && lastEventTime < _throttle!) {
          return;
        }

        if (_interval != null) {
          if (lastEventTime < _interval!) {
            Future.delayed(lastEventTime, () {
              callback(event);
              _lastEmittedTime = DateTime.now();
            });

            return;
          }
        }

        callback(event);
        _lastEmittedTime = DateTime.now();
      }),
    );
  }

  void insertAsync(Future<T> Function() dataGenerator) {
    if (!hasListeners) {
      return;
    }

    dataGenerator().then(
      (value) {
        insert(value);
      },
      onError: (error, stackTrace) {
        insertError(
          error,
          stackTrace ?? StackTrace.current,
        );
      },
    );
  }

  void insertError(
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

  void insert(T data) {
    if (!hasListeners || _pause) {
      return;
    }

    _dataHistory.add(_encoder(data));

    _invokeListeners(
      data: data,
    );
  }

  void _on(DataCallback<T> onEvent) {
    if (_listeners.contains(onEvent)) {
      return;
    }

    _listeners.add(onEvent);

    if (_dataHistory.isNotEmpty) {
      if (_replayHistoryOnAdd) {
        _dataHistory.forEach(
          (element) => _invokeListeners(data: _decoder(element)),
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
  }
}
