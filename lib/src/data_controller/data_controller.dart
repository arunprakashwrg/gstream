part of '../gstore.dart';

class DataController<T> with DisposableMixin {
  DataController._(
    this._decoder,
    this._encoder,
    this._tag,
  ) : _dataIterable = [];

  /// Gets the nearest [DataController] of the specified type and key to the current context.
  static DataController<T> of<T>(BuildContext context, [String? tag]) {
    return context
        .dependOnInheritedWidgetOfExactType<GStoreScope>()!
        .store
        .get<T>(tag);
  }

  final T Function(dynamic json) _decoder;
  final Map<String, dynamic> Function(T instance) _encoder;
  final List<Map<String, dynamic>> _dataIterable;
  final String? _tag;

  ControllerKey<T> get _key => ControllerKey<T>(_tag);
  final _listeners = <DataCallback<T>>[];

  bool get hasListeners => _listeners.isNotEmpty;

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

    for (final callback in _listeners) {
      callback(event);
    }
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
    if (!hasListeners) {
      return;
    }

    final encodedData = _encoder(data);

    _dataIterable.add(encodedData);

    _invokeListeners(
      data: _decoder(data),
    );
  }

  void _on(DataCallback<T> onEvent) {
    if (_listeners.contains(onEvent)) {
      return;
    }

    _listeners.add(onEvent);
  }

  @override
  void dispose() {
    _dataIterable.clear();
    _listeners.clear();
  }
}
