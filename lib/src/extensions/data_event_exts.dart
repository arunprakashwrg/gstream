import 'package:gstream/src/data_event.dart';

import '../utilities/typedefs.dart';

extension DataEventExts<T> on DataEvent<T> {
  DataEvent<E> foldWith<E>(
    DataEvent<T> other,
    EventFold<E, T> foldCallback,
  ) {
    return foldCallback(this, other);
  }
}
