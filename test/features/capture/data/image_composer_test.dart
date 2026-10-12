import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:geomapcam/features/capture/data/image_composer.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';
import 'package:geomapcam/features/overlay/domain/overlay_snapshot.dart';
import 'package:geomapcam/features/overlay/domain/models/overlay_template.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageComposer Phase 14 Audit', () {
    late List<int> dummyJpgBytes;

    setUp(() {
      final dummyImage = img.Image(width: 100, height: 100);
      img.fill(dummyImage, color: img.ColorRgb8(255, 0, 0));
      dummyJpgBytes = img.encodeJpg(dummyImage, quality: 100);
    });

    test('PhotoQuality changes the final JPEG encoder behavior', () async {
      final composer = ImageComposer();
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

    test(
      'composite succeeds and returns valid JPEG even when map generation throws',
      () async {
        final composer = ImageComposer();
        final metadata = CaptureMetadata(
          snapshot: OverlaySnapshot(
            latitude: null,
            longitude: null,
            timestamp: DateTime(2026, 10, 12, 12, 0, 0),
          ),
          template: OverlayTemplate.classic,
        );

        final resultBytes = await composer.composite(dummyJpgBytes, metadata);

        expect(resultBytes, isNotEmpty);
        expect(composer.lastMapFailed, isTrue);

        // Verify result is a valid JPEG
        final decoded = img.decodeJpg(Uint8List.fromList(resultBytes));
        expect(decoded, isNotNull);
        expect(decoded!.width, 100);
        expect(decoded.height, 100);
      },
    );

    test(
      'composite succeeds without map when HTTP client returns 403 Forbidden',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            '{\n  "error_message" : "The provided API key is invalid.",\n  "status" : "REQUEST_DENIED"\n}',
            403,
          );
        });

        final composer = ImageComposer(httpClient: mockClient);
        final metadata = CaptureMetadata(
          snapshot: OverlaySnapshot(
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: DateTime(2026, 10, 12, 12, 0, 0),
          ),
          template: OverlayTemplate.classic,
        );

        final resultBytes = await composer.composite(dummyJpgBytes, metadata);

        expect(resultBytes, isNotEmpty);
        expect(composer.lastMapFailed, isTrue);

        final decoded = img.decodeJpg(Uint8List.fromList(resultBytes));
        expect(decoded, isNotNull);
      },
    );

    test(
      'composite succeeds and incorporates map when HTTP client returns 200 OK',
      () async {
        final mapImg = img.Image(width: 100, height: 100);
        img.fill(mapImg, color: img.ColorRgb8(0, 0, 255));
        final mapPngBytes = img.encodePng(mapImg);

        final mockClient = MockClient((request) async {
          return http.Response.bytes(mapPngBytes, 200);
        });

        final composer = ImageComposer(httpClient: mockClient);
        final metadata = CaptureMetadata(
          snapshot: OverlaySnapshot(
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: DateTime(2026, 10, 12, 12, 0, 0),
          ),
          template: OverlayTemplate.classic,
        );

        final resultBytes = await composer.composite(dummyJpgBytes, metadata);

        expect(resultBytes, isNotEmpty);
        expect(composer.lastMapFailed, isFalse);

        final decoded = img.decodeJpg(Uint8List.fromList(resultBytes));
        expect(decoded, isNotNull);
      },
    );
  });
}
