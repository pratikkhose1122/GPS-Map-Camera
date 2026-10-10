import 'package:flutter_test/flutter_test.dart';
import 'package:geomapcam/features/locations/domain/models/saved_location.dart';

void main() {
  group('SavedLocation Model Phase 17 Audit', () {
    test('serialization and deserialization', () {
      final loc = SavedLocation.create(
        name: 'Site A',
        latitude: 37.422,
        longitude: -122.084,
        address: '1600 Amphitheatre Parkway',
        plusCode: '849VCWC8+R9',
        note: 'Main entrance',
      );

      final json = loc.toJson();
      final decoded = SavedLocation.fromJson(json);

      expect(decoded.id, loc.id);
      expect(decoded.name, loc.name);
      expect(decoded.latitude, loc.latitude);
      expect(decoded.longitude, loc.longitude);
      expect(decoded.address, loc.address);
      expect(decoded.plusCode, loc.plusCode);
      expect(decoded.note, loc.note);
      expect(
        decoded.createdAt.toIso8601String(),
        loc.createdAt.toIso8601String(),
      );
      expect(
        decoded.updatedAt.toIso8601String(),
        loc.updatedAt.toIso8601String(),
      );
    });

    test('malformed persisted data does not crash but falls back', () {
      final json = {
        'id': '123',
        'name': 'Corrupt',
        'latitude': 10, // Not a double in JSON sometimes
        'longitude': 20.0,
        // missing fields
      };

      final decoded = SavedLocation.fromJson(json);
      expect(decoded.id, '123');
      expect(decoded.name, 'Corrupt');
      expect(decoded.latitude, 10.0);
      expect(decoded.longitude, 20.0);
      expect(decoded.address, null);
      expect(decoded.plusCode, null);
    });

    test('immutable behavior and copyWith', () {
      final loc = SavedLocation.create(
        name: 'Initial',
        latitude: 0,
        longitude: 0,
      );

      final updated = loc.copyWith(name: 'Updated', address: 'New Address');

      expect(updated.id, loc.id);
      expect(updated.name, 'Updated');
      expect(updated.address, 'New Address');
      expect(updated.latitude, 0); // unchanged

      // Original is untouched
      expect(loc.name, 'Initial');
      expect(loc.address, null);
    });

    test('equality uses stable ID', () {
      final loc1 = SavedLocation.create(name: 'A', latitude: 0, longitude: 0);
      final loc2 = SavedLocation.create(name: 'A', latitude: 0, longitude: 0);

      // Different IDs despite same contents
      expect(loc1 == loc2, isFalse);

      final loc3 = loc1.copyWith(name: 'B');
      // Same ID, different contents -> equal (as identity is ID)
      expect(loc1 == loc3, isTrue);
    });
  });
}
