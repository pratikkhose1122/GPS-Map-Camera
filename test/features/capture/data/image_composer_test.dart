import 'package:flutter_test/flutter_test.dart';
import 'package:geomapcam/features/capture/data/image_composer.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';
import 'package:geomapcam/features/overlay/domain/overlay_snapshot.dart';
import 'package:geomapcam/features/overlay/domain/models/overlay_template.dart';
import 'package:image/image.dart' as img;

void main() {
  group('ImageComposer Phase 14 Audit', () {
    test('PhotoQuality changes the final JPEG encoder behavior', () async {
      final composer = ImageComposer();

      // Create a solid 100x100 dummy JPEG
      final dummyImage = img.Image(width: 100, height: 100);
      img.fill(dummyImage, color: img.ColorRgb8(255, 0, 0));
      final dummyJpgBytes = img.encodeJpg(dummyImage, quality: 100);

      final snapshot = OverlaySnapshot(timestamp: DateTime.now());

      // Test High Quality
      final metadataHigh = CaptureMetadata(
        snapshot: snapshot,
        template: OverlayTemplate.classic,
        photoQuality: PhotoQuality.high,
      );

      final highBytes = await composer.composite(dummyJpgBytes, metadataHigh);

      // Test Standard Quality
      final metadataStandard = CaptureMetadata(
        snapshot: snapshot,
        template: OverlayTemplate.classic,
        photoQuality: PhotoQuality.standard,
      );

      final standardBytes = await composer.composite(
        dummyJpgBytes,
        metadataStandard,
      );

      // High quality (95) should theoretically be larger than standard quality (80)
      // for a composited image with some text/gradients in the overlay
      expect(highBytes.length, greaterThan(standardBytes.length));
    });
  });
}
