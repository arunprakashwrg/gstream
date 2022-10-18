import 'package:flutter/material.dart';
import 'package:gstream/src/utilities/helpers.dart';

@immutable
class ControllerKey<T> {
  const ControllerKey([this.tag]);

  Type get _typeKey => typeOf<T>();
  final String? tag;

  @override
  int get hashCode {
    return _typeKey.hashCode ^ (tag?.hashCode ?? 0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }

    if (other is! ControllerKey) {
      return false;
    }

    return other.tag == tag && _typeKey.hashCode == other._typeKey.hashCode;
  }
}
