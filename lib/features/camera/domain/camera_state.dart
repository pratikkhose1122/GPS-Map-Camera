/// Camera initialization and permission states.
enum CameraState {
  /// Currently loading or initializing the camera.
  initializing,

  /// Camera is ready and preview can be displayed.
  ready,

  /// User denied camera permission.
  permissionDenied,

  /// User permanently denied camera permission (requires opening settings).
  permissionPermanentlyDenied,

  /// No cameras were found on this device.
  noCamera,

  /// An error occurred during initialization.
  error,

  /// The camera has been safely disposed.
  disposed,
}
