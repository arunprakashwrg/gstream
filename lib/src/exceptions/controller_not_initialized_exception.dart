import '../utilities/helpers.dart';
import 'g_exception.dart';

class ControllerNotInitializedException<T> extends GException {
  ControllerNotInitializedException()
      : super('Controller of type ${typeOf<T>()} not initialized.');
}
