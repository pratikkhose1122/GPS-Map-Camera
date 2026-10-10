import 'package:flutter/material.dart';
import 'package:geomapcam/features/locations/data/locations_service.dart';

class LocationsProvider extends InheritedNotifier<LocationsService> {
  const LocationsProvider({
    super.key,
    required LocationsService locationsService,
    required super.child,
  }) : super(notifier: locationsService);

  static LocationsService of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<LocationsProvider>();
    if (provider == null) {
      throw Exception('LocationsProvider not found in context');
    }
    return provider.notifier!;
  }
}
