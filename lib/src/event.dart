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

  factory Event.success({
    required T data,
  }) {
    return Event<T>(data: data);
  }

  factory Event.initial() {
    return Event<T>();
  }

  factory Event.error({
    required Object error,
    required StackTrace? stackTrace,
  }) {
    return Event<T>(
      error: error,
      stackTrace: stackTrace,
    );
  }

  final T? data;
  final Object? error;
  final StackTrace? stackTrace;

  bool get hasError => data == null && error != null;
  bool get hasData => data != null;
  bool get isInitial => !hasData && error == null && stackTrace == null;

  Type get _typeKey => typeOf<T>();

  Event<T> clone() {
    return Event<T>(
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

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
