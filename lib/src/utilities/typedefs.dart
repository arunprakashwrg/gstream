import 'package:flutter/material.dart';

import '../data_event.dart';

typedef DataCallback<T> = void Function(DataEvent<T> data);
typedef EventBuilder<T> = Widget Function(
  BuildContext context,
  DataEvent<T> data,
  Widget? child,
);
typedef RebuildCallback<T> = bool Function(
  DataEvent<T> previous,
  DataEvent<T> current,
);
