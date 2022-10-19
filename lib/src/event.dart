import 'package:flutter/material.dart';

import '../gstream.dart';
import 'utilities/helpers.dart';

@immutable
class Event<T> extends Equatable {
  const Event({
    this.data,
    this.error,
    this.stackTrace,
  });

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
  List<Object?> get props {
    return [
      data,
      _typeKey,
      error,
      stackTrace,
    ];
  }
}
