import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_location_code/open_location_code.dart' as olc;
import '../../../core/config/app_config.dart';
import '../../../core/utils/format_utils.dart';
import '../domain/address_data.dart';
import '../domain/location_data.dart';

/// Handles reverse geocoding with multi-tier fallback:
/// 1. Google Maps Geocoding API
/// 2. OpenStreetMap Nominatim API
/// 3. BigDataCloud Reverse Geocoding API
/// 4. Offline Geographic Plus Code & Coordinate fallback
class ReverseGeocodingService {
  ReverseGeocodingService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Spatial threshold for caching (in meters).
  static const double cacheDistanceThresholdMeters = 50.0;

  AddressData? _cachedAddress;
  LocationData? _lastSuccessfulLocation;
  DateTime? _lastAttemptTime;
  bool _isRequestInProgress = false;

  /// Retrieves the address for the given coordinates.
  /// Guarantees a valid, human-readable AddressData result.
  Future<AddressData?> getAddressForLocation(LocationData location) async {
    // 1. Check spatial cache (only if valid non-empty address)
    if (_lastSuccessfulLocation != null &&
        _cachedAddress != null &&
        _cachedAddress!.formattedAddress != 'Address unavailable' &&
        _cachedAddress!.formattedAddress.isNotEmpty) {
      final distance = FormatUtils.haversineDistance(
        _lastSuccessfulLocation!.latitude,
        _lastSuccessfulLocation!.longitude,
        location.latitude,
        location.longitude,
      );

      if (distance <= cacheDistanceThresholdMeters) {
        return _cachedAddress;
      }
    }

    // 2. Prevent concurrent duplicate requests
    if (_isRequestInProgress) {
      return _cachedAddress;
    }

    _isRequestInProgress = true;
    _lastAttemptTime = DateTime.now();

    try {
      // Tier 1: Google Maps Geocoding API
      final googleResult = await _tryGoogleGeocoding(location);
      if (googleResult != null) {
        _cachedAddress = googleResult;
        _lastSuccessfulLocation = location;
        return googleResult;
      }

      // Tier 2: OpenStreetMap Nominatim API (Free, high accuracy in India/Global)
      final osmResult = await _tryOsmNominatim(location);
      if (osmResult != null) {
        _cachedAddress = osmResult;
        _lastSuccessfulLocation = location;
        return osmResult;
      }

      // Tier 3: BigDataCloud Reverse Geocoding API (Fast, Free)
      final bdcResult = await _tryBigDataCloud(location);
      if (bdcResult != null) {
        _cachedAddress = bdcResult;
        _lastSuccessfulLocation = location;
        return bdcResult;
      }

      // Tier 4: Offline Geographic Plus Code & Coordinate Fallback
      final offlineResult = _generateOfflineFallback(location);
      _cachedAddress = offlineResult;
      _lastSuccessfulLocation = location;
      return offlineResult;
    } finally {
      _isRequestInProgress = false;
    }
  }

  /// Tier 1: Google Maps Geocoding API
  Future<AddressData?> _tryGoogleGeocoding(LocationData location) async {
    try {
      final apiKey = await AppConfig.getGeocodingApiKey();
      if (apiKey == null || apiKey.isEmpty) return null;

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=$apiKey',
      );

      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];
        final results = data['results'] as List?;

        if (status == 'OK' && results != null && results.isNotEmpty) {
          return _parseGoogleAddressData(results[0]);
        }
      }
    } catch (e) {
      debugPrint('Google Geocoding failed, trying OSM fallback: $e');
    }
    return null;
  }

  /// Tier 2: OpenStreetMap Nominatim API
  Future<AddressData?> _tryOsmNominatim(LocationData location) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1',
      );

      final response = await _client.get(
        url,
        headers: {'User-Agent': 'GeoMapCam/1.0 (Android GPS Camera)'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['display_name'] != null) {
          return _parseOsmAddressData(data);
        }
      }
    } catch (e) {
      debugPrint('OSM Nominatim failed, trying BigDataCloud fallback: $e');
    }
    return null;
  }

  /// Tier 3: BigDataCloud Reverse Geocoding API
  Future<AddressData?> _tryBigDataCloud(LocationData location) async {
    try {
      final url = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${location.latitude}&longitude=${location.longitude}&localityLanguage=en',
      );

      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return _parseBdcAddressData(data, location);
        }
      }
    } catch (e) {
      debugPrint('BigDataCloud geocoding failed: $e');
    }
    return null;
  }

  /// Tier 4: Guaranteed offline fallback using Open Location Code and Coordinates
  AddressData _generateOfflineFallback(LocationData location) {
    String plusCode = '';
    try {
      plusCode = olc.PlusCode.encode(
        olc.LatLng(location.latitude, location.longitude),
      ).toString();
    } catch (_) {}

    final latStr = FormatUtils.formatLatitude(location.latitude);
    final lonStr = FormatUtils.formatLongitude(location.longitude);

    final String formatted = plusCode.isNotEmpty
        ? '$plusCode ($latStr, $lonStr)'
        : '$latStr, $lonStr';

    return AddressData(
      formattedAddress: formatted,
      locality: plusCode.isNotEmpty ? plusCode : 'GPS Fix',
    );
  }

  AddressData _parseGoogleAddressData(Map<String, dynamic> result) {
    final formattedAddress =
        result['formatted_address'] as String? ?? 'Unknown Location';

    String? street;
    String? locality;
    String? administrativeArea;
    String? country;
    String? postalCode;

    final addressComponents =
        result['address_components'] as List<dynamic>? ?? [];

    for (final component in addressComponents) {
      final types = component['types'] as List<dynamic>? ?? [];
      final longName = component['long_name'] as String?;

      if (longName == null) continue;

      if (types.contains('route')) {
        street = longName;
      } else if (types.contains('locality') || types.contains('postal_town')) {
        locality = longName;
      } else if (types.contains('administrative_area_level_1')) {
        administrativeArea = longName;
      } else if (types.contains('country')) {
        country = longName;
      } else if (types.contains('postal_code')) {
        postalCode = longName;
      }
    }

    return AddressData(
      formattedAddress: formattedAddress,
      street: street,
      locality: locality,
      administrativeArea: administrativeArea,
      country: country,
      postalCode: postalCode,
    );
  }

  AddressData _parseOsmAddressData(Map<String, dynamic> data) {
    final displayName = data['display_name'] as String? ?? 'Unknown Location';
    final addr = data['address'] as Map<String, dynamic>? ?? {};

    final street = addr['road'] as String? ?? addr['suburb'] as String?;
    final locality = addr['town'] as String? ??
        addr['city'] as String? ??
        addr['village'] as String? ??
        addr['county'] as String?;
    final administrativeArea = addr['state'] as String? ??
        addr['state_district'] as String?;
    final country = addr['country'] as String?;
    final postalCode = addr['postcode'] as String?;

    return AddressData(
      formattedAddress: displayName,
      street: street,
      locality: locality,
      administrativeArea: administrativeArea,
      country: country,
      postalCode: postalCode,
    );
  }

  AddressData _parseBdcAddressData(
    Map<String, dynamic> data,
    LocationData location,
  ) {
    final locality = data['locality'] as String? ?? data['city'] as String?;
    final adminArea = data['principalSubdivision'] as String?;
    final country = data['countryName'] as String?;
    final postcode = data['postcode'] as String?;

    final parts = [
      if (locality != null && locality.isNotEmpty) locality,
      if (adminArea != null && adminArea.isNotEmpty) adminArea,
      if (postcode != null && postcode.isNotEmpty) postcode,
      if (country != null && country.isNotEmpty) country,
    ];

    final formatted = parts.isNotEmpty
        ? parts.join(', ')
        : '${FormatUtils.formatLatitude(location.latitude)}, ${FormatUtils.formatLongitude(location.longitude)}';

    return AddressData(
      formattedAddress: formatted,
      locality: locality,
      administrativeArea: adminArea,
      country: country,
      postalCode: postcode,
    );
  }
}
