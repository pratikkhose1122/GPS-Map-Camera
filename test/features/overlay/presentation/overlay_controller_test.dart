import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geomapcam/features/settings/data/settings_service.dart';
import 'package:geomapcam/features/location/data/location_service.dart';
import 'package:geomapcam/features/location/domain/location_data.dart';
import 'package:geomapcam/features/compass/data/compass_service.dart';
import 'package:geomapcam/features/overlay/presentation/overlay_controller.dart';
import 'package:geomapcam/features/location/domain/location_state.dart';
import 'package:geomapcam/features/compass/domain/compass_state.dart';
import 'package:geomapcam/features/locations/data/locations_service.dart';
import 'package:geomapcam/features/locations/domain/models/saved_location.dart';

class MockLocationService extends LocationService {
  @override
  LocationState get state => LocationState.available;

  @override
  LocationData? get locationData => _data;
  LocationData? _data;

  void setLocation(double lat, double lon) {
    _data = LocationData(
      latitude: lat,
      longitude: lon,
      accuracy: 5.0,
      altitude: 0,
      speed: 0,
      heading: 0,
      timestamp: DateTime.now(),
    );
    notifyListeners();
  }
}

class MockCompassService extends CompassService {
  @override
  CompassState get state =>
      const CompassState(headingDegrees: 90, cardinalDirection: 'E');
}

class MockLocationsService extends LocationsService {
  MockLocationsService(super.prefs);

  @override
  bool get isLiveMode => true;

  @override
  SavedLocation? get selectedLocation => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('OverlayController Phase 14 Audit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_timezone'), (
            MethodCall methodCall,
          ) async {
            if (methodCall.method == 'getLocalTimezone') {
              return 'America/New_York';
            }
            return null;
          });
    });

    test(
      'Plus Code generated deterministically from valid coordinates without network',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final settings = SettingsService(prefs);
        final location = MockLocationService();
        final compass = MockCompassService();
        final locationsSvc = MockLocationsService(prefs);

        final controller = OverlayController(
          locationService: location,
          compassService: compass,
          settingsService: settings,
          locationsService: locationsSvc,
        );

        location.setLocation(37.4219983, -122.084);

        expect(controller.metadata.plusCode, '849VCWC8+QC');

        // Should handle invalid without crashing (open_location_code clips/clamps it)
        location.setLocation(200.0, 200.0);
        expect(controller.metadata.plusCode, isNotNull);
      },
    );

    test('Settings changes automatically update metadata', () async {
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final location = MockLocationService();
      final compass = MockCompassService();
      final locationsSvc = MockLocationsService(prefs);

      final controller = OverlayController(
        locationService: location,
        compassService: compass,
        settingsService: settings,
        locationsService: locationsSvc,
      );

      location.setLocation(37.4219983, -122.084);

      expect(controller.metadata.plusCode, '849VCWC8+QC');

      await settings.setPlusCodeEnabled(false);
      expect(controller.metadata.plusCode, isNull);
    });
  });
}
