import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geomapcam/features/locations/data/locations_service.dart';
import 'package:geomapcam/features/locations/domain/models/saved_location.dart';

void main() {
  group('LocationsService Phase 17 Audit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts with live mode and empty list', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = LocationsService(prefs);

      expect(service.isLiveMode, isTrue);
      expect(service.selectedLocation, isNull);
      expect(service.locations, isEmpty);
    });

    test('addLocation persists and sorts by updatedAt descending', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = LocationsService(prefs);

      final loc1 = SavedLocation.create(name: 'A', latitude: 10, longitude: 10);

      // Delay so loc2 has a definitely later updatedAt
      await Future.delayed(const Duration(milliseconds: 10));
      final loc2 = SavedLocation.create(name: 'B', latitude: 20, longitude: 20);

      await service.addLocation(loc1);
      await service.addLocation(loc2);

      // Should be sorted by updatedAt desc, so loc2 is first
      expect(service.locations.first.id, loc2.id);
      expect(service.locations.last.id, loc1.id);

      final str = prefs.getString('saved_locations');
      expect(str, isNotNull);
      expect(str!.contains('A'), isTrue);
      expect(str.contains('B'), isTrue);
    });

    test('updateLocation modifies location and persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = LocationsService(prefs);

      final loc = SavedLocation.create(
        name: 'Initial',
        latitude: 10,
        longitude: 10,
      );
      await service.addLocation(loc);

      final updated = loc.copyWith(
        name: 'Updated',
        updatedAt: DateTime.now().add(const Duration(hours: 1)),
      );
      await service.updateLocation(updated);

      expect(service.locations.first.name, 'Updated');
    });

    test('deleteLocation removes location and persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = LocationsService(prefs);

      final loc = SavedLocation.create(name: 'A', latitude: 10, longitude: 10);
      await service.addLocation(loc);

      expect(service.locations.length, 1);

      await service.deleteLocation(loc.id);
      expect(service.locations, isEmpty);
    });

    test('selectLocation updates state and isLiveMode correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = LocationsService(prefs);

      final loc = SavedLocation.create(name: 'A', latitude: 10, longitude: 10);

      // Select
      service.selectLocation(loc);
      expect(service.isLiveMode, isFalse);
      expect(service.selectedLocation?.id, loc.id);

      // Deselect (back to live mode)
      service.selectLocation(null);
      expect(service.isLiveMode, isTrue);
      expect(service.selectedLocation, isNull);
    });

    test('deleting selected location resets to live mode', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = LocationsService(prefs);

      final loc = SavedLocation.create(name: 'A', latitude: 10, longitude: 10);
      await service.addLocation(loc);
      service.selectLocation(loc);
      expect(service.isLiveMode, isFalse);

      await service.deleteLocation(loc.id);
      expect(service.isLiveMode, isTrue);
      expect(service.selectedLocation, isNull);
    });

    test('malformed persisted JSON is handled gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_locations', '[{"invalid": "data"}]');

      // Should not crash, recovers gracefully and generates a default location
      final service = LocationsService(prefs);
      expect(service.locations, isNotEmpty);
    });

    test('duplicate names and identical coordinates are allowed', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = LocationsService(prefs);

      final loc1 = SavedLocation.create(
        name: 'Same',
        latitude: 10,
        longitude: 10,
      );
      final loc2 = SavedLocation.create(
        name: 'Same',
        latitude: 10,
        longitude: 10,
      );

      await service.addLocation(loc1);
      await service.addLocation(loc2);

      expect(service.locations.length, 2);
    });
  });
}
