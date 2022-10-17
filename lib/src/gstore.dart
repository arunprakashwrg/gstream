import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gstream/src/data_controller/controller_key.dart';
import 'package:gstream/src/data_event.dart';
import 'package:gstream/src/mixins/disposable_mixin.dart';
import 'package:gstream/src/utilities/helpers.dart';
import 'package:gstream/src/utilities/typedefs.dart';

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
  }) {
    if (contains<T>(tag)) {
      return;
    }

    final controller = DataController<T>._(
      decoder,
      encoder,
      tag,
    );

    _dataControllers[controller._key] = controller;
  }

  DataController<T> get<T>([String? tag]) {
    if (!contains<T>(tag)) {
      throw Exception("DataController with type ${T} doesn't exist!");
    }

    return _dataControllers[ControllerKey<T>(tag)] as DataController<T>;
  }

  void listen<T>(
    DataCallback<T> onEvent, [
    String? tag,
  ]) {
    final controller = get<T>(tag);
    controller._on(onEvent);
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
