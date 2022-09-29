/// The mode in which the controller should be disposed.
enum ControllerDisposeMode {
  /// The controller will be forced to dispose when the associated widget is unmounted.
  force,

  /// The controller will only be disposed if the associated widget is unmounted and there are no more listeners associated to the controller.
  auto,
}
