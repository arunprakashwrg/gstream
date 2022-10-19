// ignore_for_file: prefer_const_constructors_in_immutables

part of '../gstore.dart';

@immutable
class GStoreScope extends InheritedWidget {
  GStoreScope({
    Key? key,
    required Widget child,
    this.onCreate,
  }) : super(key: key, child: child);

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<GStore>('store', store));
    properties.add(ObjectFlagProperty<void Function(GStore store)?>.has(
        'onCreate', onCreate));
  }
}
