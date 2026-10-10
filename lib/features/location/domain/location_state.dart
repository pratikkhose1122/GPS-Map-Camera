/// GPS Location states.
enum LocationState {
  /// Initializing or determining permissions/service status.
  initializing,

  /// Location permissions denied.
  permissionDenied,

  /// Location permissions permanently denied.
  permissionPermanentlyDenied,

  /// Location service (GPS) is disabled on the device.
  serviceDisabled,

  /// Acquiring location data.
  acquiring,

  /// Real location data is available and live.
  available,

  /// An error occurred fetching location.
  error,

  /// The location service has been safely disposed.
  disposed,
}
