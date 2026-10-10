import 'package:flutter/material.dart';
import 'package:geomapcam/core/providers/settings_provider.dart';
import 'package:geomapcam/core/localization/translations.dart';

extension LocalizationExtension on BuildContext {
  String tr(String key) {
    // Read the current language from SettingsService
    final language = SettingsProvider.of(this).language;
    return AppTranslations.get(language, key);
  }
}
