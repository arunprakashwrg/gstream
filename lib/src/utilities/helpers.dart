import 'package:uuid/uuid.dart';

Type typeOf<T>() => T;

T $<T>(T Function() callback) => callback();

String generateRandomId() {
  return const Uuid().v4();
}
