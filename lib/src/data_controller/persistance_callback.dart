import '../utilities/typedefs.dart';

class PersistanceCallback<T> {
  const PersistanceCallback({
    required this.decoder,
    required this.encoder,
  });

  final Decoder<T> decoder;
  final Encoder<T> encoder;
}
