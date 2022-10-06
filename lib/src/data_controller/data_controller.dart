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
  final String? _tag;
  final Map<String, dynamic> Function(T instance) _encoder;
  StreamController<Map<String, dynamic>>? _controller;

  ControllerKey<T> get _key => ControllerKey<T>(_tag);
  final _listeners = <DataCallback<T>>[];

  bool get isDisposed => _controller == null || _controller!.isClosed;
  bool get hasListeners => _listeners.isNotEmpty;
  bool get hasInitialized => !isDisposed;

  void _initialze() {
    if (hasInitialized) {
      throw ControllerReinitializingException<T>();
    }

    _controller = StreamController.broadcast();

    _controller!.stream.listen(
      _onStreamListen,
      onError: _onStreamError,
    );
  }

  void _invokeListeners(
    T? data,
    Object? error,
    StackTrace? stackTrace,
  ) {
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

  void _onStreamError(Object error, StackTrace? stackTrace) {
    _invokeListeners(
      null,
      error,
      stackTrace,
    );
  }

  void _onStreamListen(Map<String, dynamic> data) {
    // TODO: Add data persistance
    _invokeListeners(
      _decoder(data),
      null,
      null,
    );
  }

  // TODO: How do we handle a situtation where we don't have any listeners and we have to add a data to the stream?
  void insert(T data) {
    if (!hasInitialized || !hasListeners) {
      return;
    }

    _controller!.add(_encoder(data));
  }

  void on(DataCallback<T> onEvent) {
    if (_listeners.contains(onEvent)) {
      return;
    }

    _listeners.add(onEvent);

    if (!hasInitialized) {
      _initialze();
    }
  }

  Stream<DataEvent<T>> watch() {
    if (!hasInitialized) {
      throw ControllerNotInitializedException<T>();
    }

    return _controller!.stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          sink.add(
            DataEvent.success(
              data: _decoder(data),
            ),
          );
        },
        handleError: (error, stackTrace, sink) {
          sink.add(
            DataEvent.error(
              error: error,
              stackTrace: stackTrace,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.close();
    _controller = null;
    _listeners.clear();
  }
}
