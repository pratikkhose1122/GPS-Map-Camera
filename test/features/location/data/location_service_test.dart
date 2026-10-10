import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geomapcam/features/location/data/location_service.dart';

void main() {
  group('LocationService Validation', () {
    late LocationService service;

    setUp(() {
      service = LocationService();
    });

    test('valid position is accepted', () {
      final position = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      expect(service.isValidPosition(position), isTrue);
    });

    test('invalid latitude (>90) is rejected', () {
      final position = Position(
        latitude: 91.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      expect(service.isValidPosition(position), isFalse);
    });

    test('invalid latitude (<-90) is rejected', () {
      final position = Position(
        latitude: -91.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      expect(service.isValidPosition(position), isFalse);
    });

    test('invalid longitude (>180) is rejected', () {
      final position = Position(
        latitude: 0.0,
        longitude: 181.0,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      expect(service.isValidPosition(position), isFalse);
    });

    test('invalid longitude (<-180) is rejected', () {
      final position = Position(
        latitude: 0.0,
        longitude: -181.0,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      expect(service.isValidPosition(position), isFalse);
    });

    test('negative accuracy is rejected', () {
      final position = Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: -1.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      expect(service.isValidPosition(position), isFalse);
    });
  });
}
