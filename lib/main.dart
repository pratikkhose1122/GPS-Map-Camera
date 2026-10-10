import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geomapcam/app/app.dart';
import 'package:geomapcam/features/settings/data/settings_service.dart';

import 'package:geomapcam/features/locations/data/locations_service.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  final prefs = await SharedPreferences.getInstance();
  final settingsService = SettingsService(prefs);
  final locationsService = LocationsService(prefs);
  runApp(
    GPSMapCameraApp(
      settingsService: settingsService,
      locationsService: locationsService,
    ),
  );
}
