import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../gstream.dart';
import 'data_controller/controller_key.dart';
import 'data_controller/data_callback.dart';
import 'data_controller/persistance_callback.dart';
import 'event.dart';
import 'exceptions/controller_not_initialized_exception.dart';
import 'mixins/disposable_mixin.dart';
import 'utilities/glog.dart';

part 'data_controller/data_controller.dart';
part 'widgets/gstore_scope.dart';

class GStore {
  GStore._();

  /// Gets the associated [GStore] instance which is nearest to the current context.
  static GStore of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GStoreScope>()!.store;
  }

  final _dataControllers = <ControllerKey<dynamic>, DataController<dynamic>>{};

  bool get isEmpty => _dataControllers.isEmpty;

  void register<T>({
    PersistanceCallback<T>? persistanceCallback,
    String? tag,
    void Function(DataController<T> controller)? onCreate,
  }) {
    if (contains<T>(tag)) {
      return;
    }

    gLog('Registering controller with type: $T');

    final controller = DataController<T>._(
      tag,
      persistanceCallback,
    );

    _dataControllers[controller._key] = controller;
    onCreate?.call(controller);
  }

  DataController<T> get<T>([String? tag]) {
    if (!contains<T>(tag)) {
      throw ControllerNotInitializedException<T>();
    }

    gLog('Accessing controller ${ControllerKey<T>(tag)}');
    return _dataControllers[ControllerKey<T>(tag)] as DataController<T>;
  }

  void removeListener<T>(
    DataCallback<T> onEvent, [
    String? tag,
  ]) {
    final controller = get<T>(tag);
    controller._removeListener(onEvent);
    gLog('$onEvent listener removed.');
  }

  void listen<T>(
    DataCallback<T> onEvent, [
    String? tag,
  ]) {
    final controller = get<T>(tag);
    controller._addListener(onEvent);
    gLog('$onEvent listener added.');
  }

  bool contains<T>([String? tag]) {
    return _dataControllers.containsKey(ControllerKey<T>(tag));
  }

  void dispose<T>([String? tag]) {
    if (!contains<T>(tag)) {
      return;
    }

    final val = get<T>(tag);
    val.dispose();
    _dataControllers.remove(ControllerKey<T>(tag));
  }

  void disposeAll() {
    for (final entry in _dataControllers.entries) {
      entry.value.dispose();
    }

    _dataControllers.clear();
  }
}
