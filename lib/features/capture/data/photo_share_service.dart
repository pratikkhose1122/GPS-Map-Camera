import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// Handles sharing the final GPS Map photo via the Android system share sheet.
///
/// Responsibilities:
///   Photo file → Android share intent → system share sheet
///
/// This service is kept separate from CameraService, LocationService,
/// and ImageComposer per the architectural requirement.
class PhotoShareService {
  /// Shares the final GPS Map JPEG at [filePath].
  ///
  /// Throws if the file does not exist or sharing fails.
  static Future<void> sharePhoto(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Photo file not found. It may have been deleted.');
    }

    try {
      final xFile = XFile(filePath, mimeType: 'image/jpeg');
      // ignore: deprecated_member_use
      await Share.shareXFiles([xFile], text: 'GPS Map Camera Photo');
    } catch (e) {
      debugPrint('PhotoShareService error: $e');
      throw Exception('Unable to share the photo.');
    }
  }
}
