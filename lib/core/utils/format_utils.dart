import 'dart:math' as math;

/// Formatting utilities for GPS coordinates, headings, and display values.
class FormatUtils {
  FormatUtils._();

  /// Format latitude with degree symbol and N/S indicator.
  ///
  /// Example: "18.6298° N"
  static String formatLatitude(double latitude) {
    final direction = latitude >= 0 ? 'N' : 'S';
    return '${latitude.abs().toStringAsFixed(4)}° $direction';
  }

  /// Format longitude with degree symbol and E/W indicator.
  ///
  /// Example: "73.7997° E"
  static String formatLongitude(double longitude) {
    final direction = longitude >= 0 ? 'E' : 'W';
    return '${longitude.abs().toStringAsFixed(4)}° $direction';
  }

  /// Format accuracy in meters.
  ///
  /// Example: "±4.2 m"
  static String formatAccuracy(double? accuracy) {
    if (accuracy == null) return '—';
    return '±${accuracy.toStringAsFixed(1)} m';
  }

  /// Format altitude in meters.
  ///
  /// Returns "—" if altitude is unavailable (null).
  static String formatAltitude(double? altitude) {
    if (altitude == null) return '—';
    return '${altitude.toStringAsFixed(0)} m';
  }

  /// Format compass heading in degrees.
  ///
  /// Example: "NE 42°"
  static String formatHeading(double? degrees, String? cardinal) {
    if (degrees == null || cardinal == null) return '—';
    return '$cardinal ${degrees.toStringAsFixed(0)}°';
  }

  /// Convert heading degrees (0–360) to cardinal direction string.
  ///
  /// Uses 8-point compass: N, NE, E, SE, S, SW, W, NW.
  static String degreesToCardinal(double degrees) {
    // Normalize to 0–360
    final normalized = ((degrees % 360) + 360) % 360;
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((normalized + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Normalize an angle to [0, 360) range.
  static double normalizeAngle(double degrees) {
    return ((degrees % 360) + 360) % 360;
  }

  /// Compute the shortest angular difference between two angles.
  ///
  /// Returns a value in [-180, 180].
  /// Useful for smooth compass interpolation without jumping at 359°→0°.
  static double shortestAngleDifference(double from, double to) {
    double diff = (to - from) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  /// Smooths a heading using circular interpolation.
  ///
  /// Solves the 359 + 1 problem (which shouldn't average to 180).
  /// [currentHeading] is the current smoothed heading.
  /// [newHeading] is the newly sampled raw heading.
  /// [factor] is the smoothing factor (0.0 to 1.0).
  static double smoothHeading(
    double? currentHeading,
    double newHeading, {
    double factor = 0.2,
  }) {
    if (currentHeading == null) return normalizeAngle(newHeading);

    final diff = shortestAngleDifference(currentHeading, newHeading);
    final smoothed = currentHeading + (diff * factor);
    return normalizeAngle(smoothed);
  }

  /// Haversine distance between two GPS coordinates in meters.
  ///
  /// Used for geocode distance threshold checks.
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
