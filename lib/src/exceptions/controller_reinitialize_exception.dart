import '../utilities/helpers.dart';
import 'g_exception.dart';

class ControllerReinitializingException<T> extends GException {
  ControllerReinitializingException()
      : super('Controller of type ${typeOf<T>()} tried to reinitialize.');
}
