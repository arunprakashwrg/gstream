import 'package:flutter/material.dart';

import '../event.dart';

typedef EventBuilder<T> = Widget Function(
  BuildContext context,
  Event<T> data,
  Widget? child,
);

typedef RebuildCallback<T> = bool Function(
  Event<T> previous,
  Event<T> current,
);

typedef EventFold<E, T> = Event<E> Function(
  Event<T> current,
  Event<T> other,
);

typedef Encoder<T> = Map<String, dynamic> Function(T instance);
typedef Decoder<T> = T Function(dynamic json);
