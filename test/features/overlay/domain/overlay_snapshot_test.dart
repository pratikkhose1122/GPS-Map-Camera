import 'package:flutter_test/flutter_test.dart';
import 'package:geomapcam/features/overlay/domain/overlay_snapshot.dart';

void main() {
  group('OverlaySnapshot', () {
    test('creates with only timestamp', () {
      final snapshot = OverlaySnapshot(
        timestamp: DateTime(2026, 10, 4, 14, 30),
      );

      expect(snapshot.latitude, isNull);
      expect(snapshot.longitude, isNull);
      expect(snapshot.accuracy, isNull);
      expect(snapshot.altitude, isNull);
      expect(snapshot.headingDegrees, isNull);
      expect(snapshot.cardinalDirection, isNull);
      expect(snapshot.address, isNull);
    });

    test('creates with all fields', () {
      final snapshot = OverlaySnapshot(
        latitude: 18.6298,
        longitude: 73.7997,
        timestamp: DateTime(2026, 10, 4, 14, 30),
        accuracy: 4.2,
        altitude: 568.0,
        headingDegrees: 42.0,
        cardinalDirection: 'NE',
        address: 'Pimpri-Chinchwad, Maharashtra, India',
      );

      expect(snapshot.accuracy, 4.2);
      expect(snapshot.altitude, 568.0);
      expect(snapshot.headingDegrees, 42.0);
      expect(snapshot.cardinalDirection, 'NE');
      expect(snapshot.address, 'Pimpri-Chinchwad, Maharashtra, India');
    });

    test('nullable fields remain null when unavailable', () {
      final snapshot = OverlaySnapshot(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
      );

      // These must be null, NOT zero
      expect(snapshot.altitude, isNull);
      expect(snapshot.accuracy, isNull);
      expect(snapshot.headingDegrees, isNull);
    });
    test(
      'Test 1: No location available: capture disabled (hasRequiredLocation is false)',
      () {
        final snapshot = OverlaySnapshot(timestamp: DateTime.now());
        expect(snapshot.hasRequiredLocation, isFalse);
      },
    );

    test(
      'Test 2: Valid coordinates available: capture enabled (hasRequiredLocation is true)',
      () {
        final snapshot = OverlaySnapshot(
          latitude: 18.6298,
          longitude: 73.7997,
          timestamp: DateTime.now(),
        );
        expect(snapshot.hasRequiredLocation, isTrue);
      },
    );

    test('Test 7: Coordinates are never 0,0 as a fake readiness signal', () {
      final snapshot = OverlaySnapshot(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
      );
      expect(snapshot.hasRequiredLocation, isFalse);
    });
  });
}
