import 'package:gstream/src/helpers.dart';

class ControllerKey<T> {
  const ControllerKey([this.tag]);

  Type get _typeKey => typeOf<T>();
  final String? tag;

  @override
  int get hashCode {
    if (tag != null) {
      return tag.hashCode + _typeKey.hashCode;
    }

    return _typeKey.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (other is! ControllerKey) {
      return false;
    }

    return other.hashCode == hashCode;
  }
}
