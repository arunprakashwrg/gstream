/// Exposes [dispose] method, which provides a standard interface to dispose unused resources.
mixin DisposableMixin {
  /// This is called as soon as the resources are no longer required for the associated class.
  ///
  /// Incase of DataController's, Dispose is called when the associated context is no longer mounted and there are no more listeners to the target.
  void dispose() {}
}
