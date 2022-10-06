import 'package:gstream/src/exceptions/g_exception.dart';

import '../utilities/helpers.dart';

class ControllerDisposedException<T> extends GException {
  ControllerDisposedException()
      : super(
            'Controller of type ${typeOf<T>()} is disposed. Try calling reset()');
}
