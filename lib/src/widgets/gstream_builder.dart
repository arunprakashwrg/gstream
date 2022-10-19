import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../gstream.dart';
import '../data_controller/data_callback.dart';
import '../event.dart';

import '../utilities/typedefs.dart';

class GStreamBuilder<T> extends StatefulWidget {
  const GStreamBuilder({
    Key? key,
    this.tag,
    this.child,
    required this.builder,
    this.shouldRebuildCallback,
    this.disposeMode = ControllerDisposeMode.auto,
    this.onCreate,
    this.fac,
    this.onDispose,
  }) : super(key: key);

  final String? tag;
  final DataController<T> Function()? onCreate;
  final void Function()? onDispose;
  final EventBuilder<T> builder;
  final T Function()? fac;
  final RebuildCallback<T>? shouldRebuildCallback;
  final Widget? child;

  /// Determines if the associated [DataController] should be disposed as soon as this widget is unmounted.
  final ControllerDisposeMode disposeMode;

  @override
  State<GStreamBuilder> createState() => _GStreamBuilderState<T>();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(EnumProperty<ControllerDisposeMode>('disposeMode', disposeMode));
    properties.add(ObjectFlagProperty<RebuildCallback<T>?>.has(
        'shouldRebuildCallback', shouldRebuildCallback));
    properties.add(ObjectFlagProperty<T Function()?>.has('fac', fac));
    properties.add(ObjectFlagProperty<EventBuilder<T>>.has('builder', builder));
    properties
        .add(ObjectFlagProperty<void Function()?>.has('onDispose', onDispose));
    properties.add(ObjectFlagProperty<DataController<T> Function()?>.has(
        'onCreate', onCreate));
    properties.add(StringProperty('tag', tag));
  }
}

class _GStreamBuilderState<T> extends State<GStreamBuilder<T>> {
  GStore get _store {
    return _storeScope.store;
  }

  late final DataCallback<T> _callback = DataCallback(onEvent: _onNewEvent);
  late GStoreScope _storeScope;

  DataController<T>? _dataController;
  Event<T> _event = Event<T>.initial();
  Event<T> _prevEvent = Event<T>.initial();
  Widget? _cachedChild;

  DataController<T> get controller => _dataController!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storeScope = context.dependOnInheritedWidgetOfExactType<GStoreScope>()!;
  }

  @override
  void initState() {
    if (widget.fac != null) {
      _event = Event<T>.success(data: widget.fac!());
      _prevEvent = _event;
    }

    super.initState();

    SchedulerBinding.instance!.addPostFrameCallback(
      (_) {
        if (_dataController == null) {
          if (widget.onCreate != null) {
            _dataController = widget.onCreate!();
          }

          _dataController ??= DataController.of<T>(context, widget.tag);
        }

        if (_event != _dataController!.lastEvent) {
          setState(() {
            _event = _dataController!.lastEvent;
            _prevEvent = _event;
          });
        }

        _store.listen<T>(
          _callback,
          widget.tag,
        );
      },
    );
  }

  void _onNewEvent(Event<T> newEvent) {
    if (newEvent == _event || !mounted) {
      // dont rebuild if both states are equal or state is no longer mounted
      return;
    }

    if (widget.shouldRebuildCallback != null) {
      final shouldRebuild = widget.shouldRebuildCallback!(
        _event,
        newEvent,
      );

      if (shouldRebuild) {
        setState(() {
          _prevEvent = _event;
          _event = newEvent;
        });

        return;
      }
    }

    setState(() {
      _prevEvent = _event;
      _event = newEvent;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _store.removeListener<T>(_callback, widget.tag);

    switch (widget.disposeMode) {
      case ControllerDisposeMode.cached:
      case ControllerDisposeMode.persist:
        break;

      case ControllerDisposeMode.force:
        _store.dispose<T>(widget.tag);
        widget.onDispose?.call();
        break;

      case ControllerDisposeMode.auto:
      default:
        if (controller.hasListeners) {
          break;
        }

        _store.dispose<T>(widget.tag);
        widget.onDispose?.call();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedChild != null && _event == _prevEvent) {
      return _cachedChild!;
    }

    return _cachedChild = widget.builder(
      context,
      _event,
      widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<DataController<T>>('controller', controller));
  }
}
