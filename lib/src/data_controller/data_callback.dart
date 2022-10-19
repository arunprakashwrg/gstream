import 'package:flutter/material.dart';

import '../event.dart';
import '../utilities/helpers.dart';

@immutable
class DataCallback<T> {
  const DataCallback({
    required this.onEvent,
    this.id,
  });

  final void Function(Event<T> event) onEvent;
  final String? id;

  Type get _typeKey => typeOf<T>();

  void call(Event<T> data) => onEvent(data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! DataCallback) {
      return false;
    }

    return id == other.id && _typeKey == other._typeKey;
  }

  @override
  int get hashCode => (id?.hashCode ?? 0) ^ _typeKey.hashCode;
}
