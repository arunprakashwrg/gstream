import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../gstream.dart';
import '../data_controller/data_callback.dart';
import '../event.dart';

import '../utilities/glog.dart';
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
    required this.initialState,
    this.onDispose,
  }) : super(key: key);

  final String? tag;
  final DataController<T> Function()? onCreate;
  final void Function()? onDispose;
  final EventBuilder<T> builder;
  final T initialState;
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
    properties.add(ObjectFlagProperty<EventBuilder<T>>.has('builder', builder));
    properties
        .add(ObjectFlagProperty<void Function()?>.has('onDispose', onDispose));
    properties.add(ObjectFlagProperty<DataController<T> Function()?>.has(
        'onCreate', onCreate));
    properties.add(StringProperty('tag', tag));
    properties.add(DiagnosticsProperty<T>('initialState', initialState));
  }
}

class _GStreamBuilderState<T> extends State<GStreamBuilder<T>> {
  GStore get _store {
    return _storeScope.store;
  }

  late final DataCallback<T> _callback = DataCallback(
    onEvent: _onNewEvent,
    id: widget.tag,
  );
  late GStoreScope _storeScope;

  DataController<T>? _dataController;

  // ignore: diagnostic_describe_all_properties
  DataController<T> get controller => _dataController!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storeScope = context.dependOnInheritedWidgetOfExactType<GStoreScope>()!;

    if (_dataController == null) {
      if (widget.onCreate != null) {
        _dataController = widget.onCreate!();
      }

      _dataController ??= DataController.of<T>(context, widget.tag);
      gLog('Controller assigned: ${_dataController!.toString()}');
    }
  }

  @override
  void initState() {
    super.initState();

    print('INIT STATE CALLED: GSTREAM BUILDER');
    SchedulerBinding.instance!.addPostFrameCallback(
      (_) {
        if (controller.isDefaultEvent) {
          controller.add(widget.initialState);
        }

        _store.listen<T>(
          _callback,
          widget.tag,
        );
      },
    );
  }

  void _onNewEvent(Event<T> _) {
    // TODO: This comparison is failing due to a bug
    if (_dataController!.currentEvent == _dataController!.previousEvent ||
        !mounted) {
      // dont rebuild if both states are equal or state is no longer mounted
      gLog(
        'State rebuild is ignored as either both events are equal or the widget is not mounted',
      );
      return;
    }

    if (widget.shouldRebuildCallback != null) {
      final shouldRebuild = widget.shouldRebuildCallback!(
        _dataController!.previousEvent,
        _dataController!.currentEvent,
      );

      if (shouldRebuild) {
        setState(() {});
        return;
      }
    }

    setState(() {});
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
    if (controller.isDefaultEvent) {
      gLog('Displaying default event state');
      return widget.builder(
        context,
        Event<T>.success(data: widget.initialState),
        widget.child,
      );
    }

    return widget.builder(
      context,
      _dataController!.currentEvent,
      widget.child,
    );
  }
}
