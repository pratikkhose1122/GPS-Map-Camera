import 'package:flutter/material.dart';
import 'package:geomapcam/features/settings/data/settings_service.dart';

class SettingsProvider extends InheritedNotifier<SettingsService> {
  const SettingsProvider({
    super.key,
    required SettingsService settingsService,
    required super.child,
  }) : super(notifier: settingsService);

  static SettingsService of(BuildContext context) {
    final SettingsProvider? result = context
        .dependOnInheritedWidgetOfExactType<SettingsProvider>();
    assert(result != null, 'No SettingsProvider found in context');
    return result!.notifier!;
  }
}
