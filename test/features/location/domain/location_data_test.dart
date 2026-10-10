import 'package:flutter_test/flutter_test.dart';
import 'package:geomapcam/features/location/domain/location_data.dart';

void main() {
  group('LocationData', () {
    test('creates with required fields and null for unavailable data', () {
      final timestamp = DateTime(2026, 1, 1, 12, 0);
      final location = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: timestamp,
      );

      expect(location.latitude, 37.7749);
      expect(location.longitude, -122.4194);
      expect(location.timestamp, timestamp);

      // Ensure no fake zeros are created
      expect(location.accuracy, isNull);
      expect(location.altitude, isNull);
      expect(location.altitudeAccuracy, isNull);
      expect(location.speed, isNull);
      expect(location.heading, isNull);
    });

    test('creates with all fields provided', () {
      final timestamp = DateTime(2026, 1, 1, 12, 0);
      final location = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: timestamp,
        accuracy: 5.0,
        altitude: 15.5,
        altitudeAccuracy: 1.0,
        speed: 2.5,
        heading: 90.0,
      );

      expect(location.accuracy, 5.0);
      expect(location.altitude, 15.5);
      expect(location.speed, 2.5);
      expect(location.heading, 90.0);
    });

    test('copyWith updates fields while keeping others intact', () {
      final timestamp = DateTime(2026, 1, 1, 12, 0);
      final location = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: timestamp,
        altitude: 10.0,
      );

      final updated = location.copyWith(latitude: 38.0, accuracy: 2.0);

      expect(updated.latitude, 38.0); // Updated
      expect(updated.longitude, -122.4194); // Unchanged
      expect(updated.altitude, 10.0); // Unchanged
      expect(updated.accuracy, 2.0); // Updated
    });
  });
}
