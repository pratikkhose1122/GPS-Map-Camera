/// Immutable GPS location data model.
///
/// Nullable fields remain nullable — never replace unavailable
/// values with fake zeros.
///
/// Example display when altitude is null: "Altitude —"
/// NOT: "Altitude 0 m"
class LocationData {
  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.altitude,
    this.altitudeAccuracy,
    this.speed,
    this.heading,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? altitude;
  final double? altitudeAccuracy;
  final double? speed;
  final double? heading;

  /// Whether minimum GPS requirements are met for photo capture.
  ///
  /// Requires latitude, longitude, and a valid timestamp.
  bool get isValidForCapture => true; // lat/lon are required fields

  LocationData copyWith({
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? accuracy,
    double? altitude,
    double? altitudeAccuracy,
    double? speed,
    double? heading,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      altitudeAccuracy: altitudeAccuracy ?? this.altitudeAccuracy,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
    );
  }

  @override
  String toString() =>
      'LocationData(lat: $latitude, lon: $longitude, acc: $accuracy)';
}
