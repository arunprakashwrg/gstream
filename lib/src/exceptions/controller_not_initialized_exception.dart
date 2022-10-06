import 'package:gstream/src/exceptions/g_exception.dart';

import '../utilities/helpers.dart';

class ControllerNotInitializedException<T> extends GException {
  ControllerNotInitializedException()
      : super('Controller of type ${typeOf<T>()} not initialized.');
}
