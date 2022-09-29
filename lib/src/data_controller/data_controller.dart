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

  void _initialze() {
    _controller = StreamController.broadcast();

    _controller!.stream.listen(
      _onStreamListen,
      onError: _onStreamError,
    );
  }

  void _onStreamError(Object error, StackTrace? stackTrace) {
    _invokeListeners(
      null,
      error,
      stackTrace,
    );
  }

  void _invokeListeners(
    T? data,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final event = data != null
        ? DataEvent<T>.success(data: data)
        : DataEvent<T>.error(
            error: error,
            stackTrace: stackTrace,
          );

    for (final callback in _listeners) {
      callback(event);
    }
  }

  void _onStreamListen(Map<String, dynamic> data) {
    _invokeListeners(_decoder(data), null, null);
  }

  void update(T data) {
    if (isDisposed) {
      return;
    }

    _controller!.add(_encoder(data));
  }

  void on(DataCallback<T> onEvent) {
    _listeners.add(onEvent);
  }

  Stream<DataEvent<T>> watch() {
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

  void reset() {
    dispose();
    _initialze();
  }

  @override
  void dispose() {
    _controller?.close();
    _controller = null;
    _listeners.clear();
  }
}
