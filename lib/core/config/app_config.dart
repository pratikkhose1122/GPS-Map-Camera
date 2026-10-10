import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Centralizes access to configuration such as API keys.
class AppConfig {
  static const MethodChannel _channel = MethodChannel(
    'com.geomapcam.geotag/config',
  );

  static String? _googleMapsApiKey;
  static String? _geocodingApiKey;
  static String? _staticMapsApiKey;

  /// Retrieves the Google Maps API Key securely mapped from Android local.properties.
  ///
  /// The key is cached in memory after the first successful retrieval.
  static Future<String?> getGoogleMapsApiKey() async {
    if (_googleMapsApiKey != null) {
      return _googleMapsApiKey;
    }

    try {
      final String? key = await _channel.invokeMethod('getApiKey');
      if (key != null && key.isNotEmpty) {
        _googleMapsApiKey = key;
        return key;
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to get API key from native: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error reading API key: $e');
    }
    return null;
  }

  /// Retrieves the Geocoding API Key securely mapped from Android local.properties.
  ///
  /// The key is cached in memory after the first successful retrieval.
  static Future<String?> getGeocodingApiKey() async {
    if (_geocodingApiKey != null) {
      debugPrint(
        'AppConfig: Geocoding key from cache (length=${_geocodingApiKey!.length})',
      );
      return _geocodingApiKey;
    }

    try {
      final String? key = await _channel.invokeMethod('getGeocodingApiKey');
      if (key != null && key.isNotEmpty) {
        debugPrint(
          'AppConfig: Geocoding key retrieved from native (length=${key.length})',
        );
        _geocodingApiKey = key;
        return key;
      } else {
        debugPrint('AppConfig: Geocoding key was null or empty from native');
      }
    } on PlatformException catch (e) {
      debugPrint(
        'AppConfig: PlatformException getting Geocoding key: ${e.code} - ${e.message}',
      );
    } catch (e) {
      debugPrint('AppConfig: Unexpected error reading Geocoding API key: $e');
    }
    return null;
  }

  /// Retrieves the Static Maps API Key securely mapped from Android local.properties.
  ///
  /// The key is cached in memory after the first successful retrieval.
  static Future<String?> getStaticMapsApiKey() async {
    if (_staticMapsApiKey != null) {
      debugPrint(
        'AppConfig: Static Maps key from cache (length=${_staticMapsApiKey!.length})',
      );
      return _staticMapsApiKey;
    }

    try {
      final String? key = await _channel.invokeMethod('getStaticMapsApiKey');
      if (key != null && key.isNotEmpty) {
        debugPrint(
          'AppConfig: Static Maps key retrieved from native (length=${key.length})',
        );
        _staticMapsApiKey = key;
        return key;
      } else {
        debugPrint('AppConfig: Static Maps key was null or empty from native');
      }
    } on PlatformException catch (e) {
      debugPrint(
        'AppConfig: PlatformException getting Static Maps key: ${e.code} - ${e.message}',
      );
    } catch (e) {
      debugPrint('AppConfig: Unexpected error reading Static Maps API key: $e');
    }
    return null;
  }
}
