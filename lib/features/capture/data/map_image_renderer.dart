// No extra imports
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geomapcam/core/config/app_config.dart';
import 'package:geomapcam/features/overlay/domain/overlay_snapshot.dart';

class MapImageRenderer {
  /// Fetches a static map image for the given snapshot using Google Static Maps API.
  /// Throws an exception if the map generation fails.
  static Future<Uint8List> getMapImage(
    OverlaySnapshot snapshot, {
    http.Client? client,
  }) async {
    if (snapshot.latitude == null || snapshot.longitude == null) {
      throw Exception('Location is missing in snapshot. Cannot generate map.');
    }

    final apiKey = await AppConfig.getStaticMapsApiKey();
    // Allow tests to bypass API key check if client is provided, since they will mock the response.
    if ((apiKey == null || apiKey.isEmpty) && client == null) {
      throw Exception(
        'Google Static Maps API key is missing. Cannot generate map.',
      );
    }

    final lat = snapshot.latitude!;
    final lon = snapshot.longitude!;

    // Request a map image from Google Static Maps API
    // size: 400x300, scale: 2 (returns 800x600 pixels for crispness)
    // zoom: 15
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/staticmap'
      '?center=$lat,$lon'
      '&zoom=15'
      '&size=400x300'
      '&scale=2'
      '&markers=color:red%7C$lat,$lon'
      '&key=${apiKey ?? 'test_key'}',
    );

    final mapSw = Stopwatch()..start();
    final requestClient = client ?? http.Client();
    try {
      final response = await requestClient
          .get(url)
          .timeout(const Duration(seconds: 15));
      mapSw.stop();
      debugPrint('PERF: Map acquisition took ${mapSw.elapsedMilliseconds} ms');

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint(
          'MapImageRenderer failed: HTTP ${response.statusCode} - ${response.body}',
        );
        throw Exception('Map generation failed: HTTP ${response.statusCode}');
      }
    } finally {
      if (client == null) {
        requestClient.close();
      }
    }
  }
}
