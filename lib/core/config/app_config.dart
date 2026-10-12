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

  static const String _defaultGoogleMapsKey =
      'AIzaSyBiEdFrH42CInaSx3J8r62MMBcX8RlGco4';
  static const String _defaultGeocodingKey =
      'AIzaSyBI-iufyFgaBWbJzAVYNyokHsKQWpZ3FWI';
  static const String _defaultStaticMapsKey =
      'AIzaSyAL7aTcaxRxfzD6PCPDEaSNUbQBKlmhw0s';

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
    _googleMapsApiKey = _defaultGoogleMapsKey;
    return _defaultGoogleMapsKey;
  }

  /// Retrieves the Geocoding API Key securely mapped from Android local.properties.
  ///
  /// The key is cached in memory after the first successful retrieval.
  static Future<String?> getGeocodingApiKey() async {
    if (_geocodingApiKey != null) {
      return _geocodingApiKey;
    }

    try {
      final String? key = await _channel.invokeMethod('getGeocodingApiKey');
      if (key != null && key.isNotEmpty) {
        _geocodingApiKey = key;
        return key;
      } else {
        final fallback = await getGoogleMapsApiKey();
        if (fallback != null && fallback.isNotEmpty) {
          _geocodingApiKey = fallback;
          return fallback;
        }
      }
    } on PlatformException catch (e) {
      debugPrint(
        'AppConfig: PlatformException getting Geocoding key: ${e.code} - ${e.message}',
      );
    } catch (e) {
      debugPrint('AppConfig: Unexpected error reading Geocoding API key: $e');
    }
    _geocodingApiKey = _defaultGeocodingKey;
    return _defaultGeocodingKey;
  }

  /// Retrieves the Static Maps API Key securely mapped from Android local.properties.
  ///
  /// The key is cached in memory after the first successful retrieval.
  static Future<String?> getStaticMapsApiKey() async {
    if (_staticMapsApiKey != null) {
      return _staticMapsApiKey;
    }

    try {
      final String? key = await _channel.invokeMethod('getStaticMapsApiKey');
      if (key != null && key.isNotEmpty) {
        _staticMapsApiKey = key;
        return key;
      } else {
        final fallback = await getGoogleMapsApiKey();
        if (fallback != null && fallback.isNotEmpty) {
          _staticMapsApiKey = fallback;
          return fallback;
        }
      }
    } on PlatformException catch (e) {
      debugPrint(
        'AppConfig: PlatformException getting Static Maps key: code=${e.code}, message=${e.message}, details=${e.details}',
      );
    } catch (e, stack) {
      debugPrint(
        'AppConfig: Unexpected error reading Static Maps API key: $e\n$stack',
      );
    }
    _staticMapsApiKey = _defaultStaticMapsKey;
    return _defaultStaticMapsKey;
  }
}
