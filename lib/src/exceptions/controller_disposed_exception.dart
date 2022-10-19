import '../utilities/helpers.dart';
import 'g_exception.dart';

class ControllerDisposedException<T> extends GException {
  ControllerDisposedException()
      : super(
            'Controller of type ${typeOf<T>()} is disposed. Try calling reset()');
}
