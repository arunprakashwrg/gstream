import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:gstream/gstream.dart';
import 'package:gstream/src/data_event.dart';
import 'package:gstream/src/utilities/enums.dart';

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
    this.onDispose,
  }) : super(key: key);

  final String? tag;
  final DataController<T> Function()? onCreate;
  final void Function()? onDispose;
  final EventBuilder<T> builder;
  final RebuildCallback<T>? shouldRebuildCallback;
  final Widget? child;

  /// Determines if the associated [DataController] should be disposed as soon as this widget is unmounted.
  final ControllerDisposeMode disposeMode;

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

    SchedulerBinding.instance!.addPostFrameCallback(
      (_) {
        if (_dataController == null) {
          if (widget.onCreate != null) {
            _dataController = widget.onCreate!();
          }

          _dataController ??= DataController.of<T>(context, widget.tag);
        }

        controller.on(
          (currentEvent) {
            if (currentEvent == _previousEvent || !mounted) {
              // dont rebuild if both states are equal
              return;
            }

            if (widget.shouldRebuildCallback != null) {
              final shouldRebuild = widget.shouldRebuildCallback!(
                _previousEvent,
                currentEvent,
              );

              if (shouldRebuild) {
                setState(() {
                  _previousEvent = currentEvent;
                });

                return;
              }
            }

            setState(() {
              _previousEvent = currentEvent;
            });
          },
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();

    switch (widget.disposeMode) {
      case ControllerDisposeMode.force:
        controller.dispose();
        _store.remove<T>(widget.tag);
        widget.onDispose?.call();
        break;

      case ControllerDisposeMode.auto:
      default:
        if (!controller.hasListeners) {
          controller.dispose();
          _store.remove<T>(widget.tag);
          widget.onDispose?.call();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _previousEvent,
      widget.child,
    );
  }
}
