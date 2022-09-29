import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gstream/src/data_controller/controller_key.dart';
import 'package:gstream/src/data_event.dart';
import 'package:gstream/src/disposable_mixin.dart';
import 'package:gstream/src/typedefs.dart';

part 'data_controller/data_controller.dart';
part 'gstore_scope.dart';

class GStore {
  GStore._();

  factory GStore.of(BuildContext context) {
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

    controller._initialze();
    _dataControllers[controller._key] = controller;
  }

  DataController<T> get<T>([String? tag]) {
    if (!contains<T>(tag)) {
      throw Exception("DataController with type ${T} doesn't exist!");
    }

    return _dataControllers[ControllerKey<T>(tag)] as DataController<T>;
  }

  Stream<DataEvent<T>> watch<T>([String? tag]) {
    return get<T>(tag).watch();
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
