import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gstream/src/data_controller/controller_key.dart';
import 'package:gstream/src/data_event.dart';
import 'package:gstream/src/mixins/disposable_mixin.dart';
import 'package:gstream/src/utilities/helpers.dart';
import 'package:gstream/src/utilities/typedefs.dart';

import 'exceptions/controller_not_initialized_exception.dart';
import 'exceptions/controller_reinitialize_exception.dart';

part 'data_controller/data_controller.dart';
part 'widgets/gstore_scope.dart';

class GStore {
  GStore._();

  /// Gets the associated [GStore] store which is nearest to the current context.
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
