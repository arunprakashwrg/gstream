import 'package:gstream/src/exceptions/g_exception.dart';
import 'package:gstream/src/utilities/helpers.dart';

class ControllerReinitializingException<T> extends GException {
  ControllerReinitializingException()
      : super('Controller of type ${typeOf<T>()} tried to reinitialize.');
}
