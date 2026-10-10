/// Application-wide constants.
class AppConstants {
  AppConstants._();

  /// Application name displayed to users.
  static const String appName = 'GPS Map Camera';

  /// Android package / application ID.
  static const String packageId = 'com.geomapcam.geotag';

  /// Directory name for saved GPS photos.
  static const String photoDirectoryName = 'GPSMapCamera';

  /// JPEG quality for final composite photos (0–100).
  static const int jpegQuality = 92;

  /// Minimum distance change (meters) before triggering a new geocode request.
  static const double geocodeDistanceThreshold = 50.0;

  /// Geocode retry cooldown after failure.
  static const Duration geocodeRetryCooldown = Duration(seconds: 10);
}
