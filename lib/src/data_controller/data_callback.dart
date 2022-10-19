import 'package:flutter/material.dart';

import '../event.dart';
import '../utilities/helpers.dart';

@immutable
class DataCallback<T> {
  DataCallback({
    required this.onEvent,
  }) : id = generateRandomId();

  final void Function(Event<T> data) onEvent;
  final String id;

  void call(Event<T> data) => onEvent(data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! DataCallback) {
      return false;
    }

    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
