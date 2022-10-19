import 'dart:developer';

import '../exceptions/g_exception.dart';

void gLog(Object obj, [StackTrace? stackTrace]) {
  if (obj is GException) {
    return log(
      obj.message,
      name: 'GSTREAM',
      error: obj,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  if (obj is Exception) {
    return log(
      obj.toString(),
      name: 'GSTREAM',
      error: obj,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  log(obj.toString(), name: 'GSTREAM', time: DateTime.now());
}
