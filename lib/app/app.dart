import 'package:flutter/material.dart';
import 'package:geomapcam/app/theme/app_theme.dart';
import 'package:geomapcam/app/router/app_router.dart';
import 'package:geomapcam/features/settings/data/settings_service.dart';
import 'package:geomapcam/core/providers/settings_provider.dart';
import 'package:geomapcam/features/locations/data/locations_service.dart';
import 'package:geomapcam/core/providers/locations_provider.dart';

/// Root application widget.
class GPSMapCameraApp extends StatelessWidget {
  final SettingsService settingsService;
  final LocationsService locationsService;

  const GPSMapCameraApp({
    super.key,
    required this.settingsService,
    required this.locationsService,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsProvider(
      settingsService: settingsService,
      child: LocationsProvider(
        locationsService: locationsService,
        child: Builder(
          builder: (context) {
            final settings = SettingsProvider.of(context);
            ThemeMode themeMode = ThemeMode.system;
            if (settings.appThemeMode == 'Light') {
              themeMode = ThemeMode.light;
            } else if (settings.appThemeMode == 'Dark') {
              themeMode = ThemeMode.dark;
            }

            return MaterialApp(
              title: 'GPS Map Camera',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              initialRoute: AppRouter.home,
              onGenerateRoute: AppRouter.onGenerateRoute,
            );
          },
        ),
      ),
    );
  }
}
