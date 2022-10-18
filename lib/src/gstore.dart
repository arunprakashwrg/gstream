import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gstream/src/data_controller/controller_key.dart';
import 'package:gstream/src/event.dart';
import 'package:gstream/src/exceptions/controller_not_initialized_exception.dart';
import 'package:gstream/src/mixins/disposable_mixin.dart';
import 'package:gstream/src/utilities/glog.dart';
import 'package:gstream/src/utilities/helpers.dart';

import 'data_controller/data_callback.dart';

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
    required Map<String, dynamic> Function(T instance) encoder,
    required T Function(dynamic json) decoder,
    String? tag,
    void Function(DataController<T> controller)? onCreate,
  }) {
    if (contains<T>(tag)) {
      return;
    }

    gLog('Registering controller with type: $T');

    final controller = DataController<T>._(
      decoder,
      encoder,
      tag,
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
    gLog('${onEvent} listener removed.');
  }

  void listen<T>(
    DataCallback<T> onEvent, [
    String? tag,
  ]) {
    final controller = get<T>(tag);
    controller._addListener(onEvent);
  }

  bool contains<T>([String? tag]) {
    return _dataControllers.containsKey(ControllerKey<T>(tag));
  }

  void remove<T>([String? tag]) {
    if (!contains<T>(tag)) {
      return;
    }

    final val = get<T>(tag);
    val.dispose();
    _dataControllers.remove(ControllerKey<T>(tag));
  }
}
