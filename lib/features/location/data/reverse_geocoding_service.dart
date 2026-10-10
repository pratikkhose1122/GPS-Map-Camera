import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/utils/format_utils.dart';
import '../domain/address_data.dart';
import '../domain/location_data.dart';

/// Handles reverse geocoding via Google Maps API with spatial caching and retries.
class ReverseGeocodingService {
  ReverseGeocodingService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Spatial threshold for caching (in meters).
  static const double cacheDistanceThresholdMeters = 50.0;

  /// Time threshold for retrying failed requests.
  static const Duration retryThrottleDuration = Duration(seconds: 15);

  AddressData? _cachedAddress;
  LocationData? _lastSuccessfulLocation;
  DateTime? _lastAttemptTime;

  bool _isRequestInProgress = false;

  /// Retrieves the address for the given coordinates.
  /// Returns the cached address if the new location is within [cacheDistanceThresholdMeters].
  /// Throws an exception if geocoding fails, so the caller can handle the error state.
  Future<AddressData?> getAddressForLocation(LocationData location) async {
    // 1. Check spatial cache
    if (_lastSuccessfulLocation != null && _cachedAddress != null) {
      final distance = FormatUtils.haversineDistance(
        _lastSuccessfulLocation!.latitude,
        _lastSuccessfulLocation!.longitude,
        location.latitude,
        location.longitude,
      );

      if (distance <= cacheDistanceThresholdMeters) {
        return _cachedAddress; // Still within threshold, return cache
      }
    }

    // 2. Prevent concurrent duplicate requests
    if (_isRequestInProgress) {
      // If we already have a cached address, return it while the new one fetches.
      // Otherwise, return null.
      return _cachedAddress;
    }

    // 3. Time-based retry throttle for failures
    if (_lastAttemptTime != null && _cachedAddress == null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastAttemptTime!);
      if (timeSinceLastAttempt < retryThrottleDuration) {
        throw Exception('Throttled');
      }
    }

    _isRequestInProgress = true;
    _lastAttemptTime = DateTime.now();

    try {
      final apiKey = await AppConfig.getGeocodingApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('No API key available.');
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=$apiKey',
      );

      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 10));
      debugPrint('Geocoding HTTP status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];
        final errorMessage = data['error_message'];
        final resultCount = (data['results'] as List?)?.length ?? 0;

        debugPrint('Geocoding status: $status');
        if (errorMessage != null) {
          debugPrint('Geocoding error_message: $errorMessage');
        }
        debugPrint('Geocoding result count: $resultCount');

        if (status == 'OK' && resultCount > 0) {
          final result = data['results'][0];
          final address = _parseAddressData(result);

          _cachedAddress = address;
          _lastSuccessfulLocation = location;
          return _cachedAddress;
        } else if (status == 'ZERO_RESULTS') {
          // Zero results means the lookup succeeded but there's no address here.
          // We can cache an "unavailable" address so we don't keep retrying.
          _cachedAddress = const AddressData(
            formattedAddress: 'Address unavailable',
          );
          _lastSuccessfulLocation = location;
          return _cachedAddress;
        } else {
          throw Exception('API Error ($status)');
        }
      } else {
        throw Exception('Network Error (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Geocoding exception: $e');
      rethrow;
    } finally {
      _isRequestInProgress = false;
    }
  }

  /// Parses the raw JSON result into an AddressData model.
  AddressData _parseAddressData(Map<String, dynamic> result) {
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
}
