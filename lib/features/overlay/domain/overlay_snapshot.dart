/// Immutable snapshot of all overlay data captured at the moment
/// the shutter is pressed.
///
/// This is the SINGLE SOURCE OF TRUTH for both the on-screen overlay
/// and the image compositor. Both must use the SAME snapshot instance.
///
/// When capture is pressed:
///   1. Create ONE OverlaySnapshot
///   2. Show it in the UI freeze
///   3. Pass the same instance to the compositor
///
/// Do NOT read fields independently after capture.
class OverlaySnapshot {
  const OverlaySnapshot({
    this.latitude,
    this.longitude,
    required this.timestamp,
    this.accuracy,
    this.altitude,
    this.headingDegrees,
    this.cardinalDirection,
    this.address,
  });

  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? altitude;
  final double? headingDegrees;
  final String? cardinalDirection;
  final String? address;

  /// Returns true if the minimum required location data is available and valid.
  bool get hasRequiredLocation =>
      latitude != null &&
      longitude != null &&
      latitude != 0.0 &&
      longitude != 0.0;

  @override
  String toString() =>
      'OverlaySnapshot(lat: $latitude, lon: $longitude, '
      'heading: $headingDegrees° $cardinalDirection, '
      'addr: $address, time: $timestamp)';
}
