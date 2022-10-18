import 'package:gstream/src/utilities/helpers.dart';

class Event<T> {
  const Event.success({
    required this.data,
  })  : error = null,
        stackTrace = null;

  const Event.initial()
      : error = null,
        data = null,
        stackTrace = null;

  const Event.error({
    required this.error,
    required this.stackTrace,
  }) : data = null;

  final T? data;
  final Object? error;
  final StackTrace? stackTrace;

  bool get hasError => data == null && error != null;
  bool get hasData => data != null;
  bool get isInitial => !hasData && error == null && stackTrace == null;

  Type get _typeKey => typeOf<T>();

  @override
  bool operator ==(Object other) {
    if (other is! Event) {
      return false;
    }

    return identical(other, this) || other.data == this.data;
  }

  @override
  int get hashCode => (data?.hashCode ?? 0) ^ _typeKey.hashCode;
}
