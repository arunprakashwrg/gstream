/// The mode in which the controller should be disposed.
enum ControllerDisposeMode {
  /// The controller will be forced to dispose when the associated widget is unmounted.
  force,

  /// The controller will only be disposed if the associated widget is unmounted and there are no more listeners associated to the controller.
  auto,

  /// The data in the controller will be encoded and saved into local storage and the allocated memory will be cleared. When accessing again, the data will be loaded from storage.
  persist,

  /// The data will not be disposed and stays in the memory until app close.
  cached,
}
