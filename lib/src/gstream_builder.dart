import 'package:flutter/material.dart';
import 'package:gstream/gstream.dart';
import 'package:gstream/src/data_event.dart';

class GStreamBuilder<T> extends StatefulWidget {
  const GStreamBuilder({
    Key? key,
    this.tag,
    this.child,
    required this.builder,
    this.shouldRebuildCallback,
    this.autoDispose = true,
    this.onCreate,
  }) : super(key: key);

  final String? tag;
  final DataController<T> Function()? onCreate;
  final Widget Function(
    BuildContext context,
    DataEvent<T> data,
    Widget? child,
  ) builder;
  final bool Function(
    DataEvent<T> previous,
    DataEvent<T> current,
  )? shouldRebuildCallback;
  final Widget? child;
  final bool autoDispose;

  @override
  State<GStreamBuilder> createState() => _GStreamBuilderState<T>();
}

class _GStreamBuilderState<T> extends State<GStreamBuilder<T>> {
  GStore get _store {
    return context.dependOnInheritedWidgetOfExactType<GStoreScope>()!.store;
  }

  DataController<T>? _dataController;
  DataEvent<T> _previousEvent = DataEvent<T>.initial();

  DataController<T> get controller => _dataController!;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    if (widget.autoDispose) {
      controller.dispose();
      _store.remove<T>(widget.tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onCreate != null) {
      _dataController = widget.onCreate!();
    } else {
      _dataController = _store.get<T>(widget.tag);
    }

    controller.on(
      (currentEvent) {
        if (currentEvent == _previousEvent) {
          // dont rebuild if both states are equal
          return;
        }

        final shouldRebuildCallback = widget.shouldRebuildCallback != null &&
            widget.shouldRebuildCallback!(_previousEvent, currentEvent);

        if (shouldRebuildCallback) {
          setState(() {
            _previousEvent = currentEvent;
          });

          return;
        }

        setState(() {
          _previousEvent = currentEvent;
        });
      },
    );

    return widget.builder(
      context,
      _previousEvent,
      widget.child,
    );
  }
}
