import 'package:gstream/src/event.dart';

import '../utilities/typedefs.dart';

extension DataEventExts<T> on Event<T> {
  Event<E> foldWith<E>(
    Event<T> other,
    EventFold<E, T> foldCallback,
  ) {
    return foldCallback(this, other);
  }
}
