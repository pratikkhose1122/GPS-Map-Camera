import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:open_location_code/open_location_code.dart' as olc;
import 'package:geomapcam/features/location/data/location_service.dart';
import 'package:geomapcam/features/compass/data/compass_service.dart';
import 'package:geomapcam/features/overlay/domain/overlay_snapshot.dart';
import 'package:geomapcam/features/settings/data/settings_service.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';

import 'package:geomapcam/features/locations/data/locations_service.dart';

class OverlayController extends ChangeNotifier {
  final LocationService _locationService;
  final CompassService _compassService;
  final SettingsService _settingsService;
  final LocationsService _locationsService;

  Timer? _clockTimer;
  CaptureMetadata? _currentMetadata;
  String? _localTimezone;

  OverlayController({
    required LocationService locationService,
    required CompassService compassService,
    required SettingsService settingsService,
    required LocationsService locationsService,
  }) : _locationService = locationService,
       _compassService = compassService,
       _settingsService = settingsService,
       _locationsService = locationsService {
    _locationService.addListener(_updateMetadata);
    _compassService.addListener(_updateMetadata);
    _settingsService.addListener(_updateMetadata);
    _locationsService.addListener(_updateMetadata);

    // Fetch timezone async once
    _initTimezone();

    // Update clock every second
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateMetadata(),
    );

    // Initial metadata
    _updateMetadata();
  }

  Future<void> _initTimezone() async {
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      _localTimezone = tzInfo.identifier;
      _updateMetadata();
    } catch (e) {
      debugPrint('Failed to get local timezone: $e');
    }
  }

  CaptureMetadata get metadata => _currentMetadata!;
  OverlaySnapshot get snapshot => _currentMetadata!.snapshot;

  void _updateMetadata() {
    final compState = _compassService.state;
    final isLive = _locationsService.isLiveMode;
    final savedLoc = _locationsService.selectedLocation;

    double? lat;
    double? lng;
    double? accuracy;
    double? altitude;
    String? address;

    if (isLive) {
      final locState = _locationService.locationData;
      final addrState = _locationService.addressData;
      lat = locState?.latitude;
      lng = locState?.longitude;
      accuracy = locState?.accuracy;
      altitude = locState?.altitude;
      address = addrState?.formattedAddress;
    } else if (savedLoc != null) {
      lat = savedLoc.latitude;
      lng = savedLoc.longitude;
      address = savedLoc.address;
    }

    final newSnapshot = OverlaySnapshot(
      latitude: lat,
      longitude: lng,
      accuracy: accuracy,
      altitude: altitude,
      address: address,
      headingDegrees: compState.headingDegrees,
      cardinalDirection: compState.cardinalDirection,
      timestamp: DateTime.now(),
    );

    String? plusCode;
    if (!isLive && savedLoc != null && savedLoc.plusCode != null) {
      // Use saved plus code directly
      plusCode = savedLoc.plusCode;
    } else if (lat != null &&
        lng != null &&
        (isLive ? _settingsService.plusCodeEnabled : true)) {
      // Calculate it if enabled (or if saved location didn't store it but has coordinates)
      try {
        plusCode = olc.PlusCode.encode(olc.LatLng(lat, lng)).toString();
      } catch (e) {
        debugPrint('Failed to encode Plus Code: $e');
      }
    }

    _currentMetadata = CaptureMetadata(
      snapshot: newSnapshot,
      template: _settingsService.selectedTemplate,
      plusCode: plusCode,
      timezone: _settingsService.timeZoneEnabled ? _localTimezone : null,
      note: (!isLive && savedLoc?.note != null && savedLoc!.note!.isNotEmpty)
          ? savedLoc.note
          : _settingsService.note,
      customFields: _settingsService.customFields,
      stampOrientation: _settingsService.stampOrientation,
      photoQuality: _settingsService.photoQuality,
      saveOriginal: _settingsService.saveOriginal,
      locationSource: isLive
          ? const LocationSource.live()
          : LocationSource.saved(
              savedLocationId: savedLoc!.id,
              savedLocationName: savedLoc.name,
            ),
      filenameConfiguration: _settingsService.filenameConfiguration,
      customName1: _settingsService.customName1,
      customName2: _settingsService.customName2,
      customName3: _settingsService.customName3,
      showAppLogo: _settingsService.showAppLogo,
      showCameraIndicator: _settingsService.showCameraIndicator,
      emailPhoto: _settingsService.emailPhoto,
      sharePhotoToggle: _settingsService.sharePhotoToggle,
      showReportsToggle: _settingsService.showReportsToggle,
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _locationService.removeListener(_updateMetadata);
    _compassService.removeListener(_updateMetadata);
    _settingsService.removeListener(_updateMetadata);
    _locationsService.removeListener(_updateMetadata);
    super.dispose();
  }
}
