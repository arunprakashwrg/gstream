part of 'gstore.dart';

class GStoreScope extends InheritedWidget {
  GStoreScope({
    required Widget child,
    this.onCreate,
  }) : super(child: child);

  late final GStore _store;
  final void Function(GStore store)? onCreate;

  GStore get store {
    return _store;
  }

  @override
  InheritedElement createElement() {
    final element = super.createElement();
    _store = GStore._();

    onCreate?.call(_store);

    return element;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
