import 'package:gstream/src/utilities/helpers.dart';

class DataEvent<T> {
  const DataEvent.success({
    required this.data,
  })  : error = null,
        stackTrace = null;

  const DataEvent.initial()
      : error = null,
        data = null,
        stackTrace = null;

  const DataEvent.error({
    required this.error,
    required this.stackTrace,
  }) : data = null;

  final T? data;
  final Object? error;
  final StackTrace? stackTrace;

  bool get hasError => data == null && error != null;
  bool get hasData => data != null;

  Type get _typeKey => typeOf<T>();

  @override
  bool operator ==(Object other) {
    if (other is! DataEvent) {
      return false;
    }

    return identical(other, this) || other.data == this.data;
  }

  @override
  int get hashCode => (data?.hashCode ?? 0) ^ _typeKey.hashCode;
}
