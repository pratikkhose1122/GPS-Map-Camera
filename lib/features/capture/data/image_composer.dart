import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:geomapcam/features/capture/data/overlay_renderer.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';
import 'package:geomapcam/features/capture/data/map_image_renderer.dart';

import 'package:http/http.dart' as http;

class ImageComposer {
  final http.Client? httpClient;
  bool lastMapFailed = false;

  ImageComposer({this.httpClient});

  /// Decodes [cameraImageBytes], generates a high-quality overlay based on [metadata],
  /// composites them, and returns a new JPEG byte array.
  Future<List<int>> composite(
    List<int> cameraImageBytes,
    CaptureMetadata metadata,
  ) async {
    lastMapFailed = false;
    // 1. Fetch map image first (network call) if template requires it
    // Map generation failure will not cancel photo composition; photo will be saved without map.
    Uint8List? mapBytes;
    if (metadata.template.showMap) {
      try {
        mapBytes = await MapImageRenderer.getMapImage(
          metadata.snapshot,
          client: httpClient,
        );
      } catch (e, stack) {
        lastMapFailed = true;
        debugPrint(
          'ImageComposer: Map generation failed, continuing without map: $e',
        );
        if (kDebugMode) {
          debugPrint('ImageComposer map failure stack trace: $stack');
        }
      }
    }

    final decodeSw = Stopwatch()..start();
    // 2. Decode camera image (can be heavy, done in compute isolate)
    final baseImage = await compute(_decodeImage, cameraImageBytes);
    if (baseImage == null) {
      throw Exception('Failed to decode camera image');
    }
    decodeSw.stop();
    debugPrint('PERF: JPEG decode took ${decodeSw.elapsedMilliseconds} ms');

    // Fix orientation if needed based on EXIF (camera package often leaves EXIF orientation intact)
    final orientSw = Stopwatch()..start();
    final orientedImage = await compute(_bakeOrientation, baseImage);
    orientSw.stop();
    debugPrint(
      'PERF: Image orientation took ${orientSw.elapsedMilliseconds} ms',
    );

    debugPrint(
      'PERF: Source image resolution: ${orientedImage.width}x${orientedImage.height}',
    );
    debugPrint('PERF: Source JPEG file size: ${cameraImageBytes.length} bytes');

    // 3. Generate crisp Flutter-rendered overlay matching the image dimensions
    final width = orientedImage.width;
    final height = orientedImage.height;

    final overlayRenderSw = Stopwatch()..start();
    final overlayPngBytes = await OverlayRenderer.renderOverlayPng(
      metadata,
      width,
      height,
      mapBytes,
    );

    // 4. Decode the generated PNG overlay
    final overlayDecodeSw = Stopwatch()..start();
    final overlayImage = await compute(_decodeImage, overlayPngBytes);
    overlayDecodeSw.stop();
    overlayRenderSw.stop();
    debugPrint(
      'PERF: Overlay rendering & decode took ${overlayRenderSw.elapsedMilliseconds} ms (decode alone: ${overlayDecodeSw.elapsedMilliseconds} ms)',
    );

    if (overlayImage == null) {
      throw Exception('Failed to decode generated overlay');
    }

    // 4. Composite the overlay onto the base image
    final compositeSw = Stopwatch()..start();
    final compositedImage = await compute(
      _compositeImages,
      _CompositeArgs(orientedImage, overlayImage),
    );
    compositeSw.stop();
    debugPrint(
      'PERF: Image composition took ${compositeSw.elapsedMilliseconds} ms',
    );

    // 5. Encode back to JPEG
    final encodeSw = Stopwatch()..start();
    final int quality = metadata.photoQuality == PhotoQuality.high ? 95 : 80;
    final jpegBytes = await compute(
      _encodeJpg,
      _EncodeArgs(compositedImage, quality),
    );
    encodeSw.stop();
    debugPrint('PERF: JPEG encoding took ${encodeSw.elapsedMilliseconds} ms');

    debugPrint(
      'PERF: Final image resolution: ${compositedImage.width}x${compositedImage.height}',
    );
    debugPrint('PERF: Final JPEG file size: ${jpegBytes.length} bytes');

    return jpegBytes;
  }
}

// Top-level functions for compute() isolates

img.Image? _decodeImage(List<int> bytes) {
  return img.decodeImage(Uint8List.fromList(bytes));
}

img.Image _bakeOrientation(img.Image image) {
  return img.bakeOrientation(image);
}

class _CompositeArgs {
  final img.Image base;
  final img.Image overlay;
  _CompositeArgs(this.base, this.overlay);
}

img.Image _compositeImages(_CompositeArgs args) {
  return img.compositeImage(args.base, args.overlay);
}

class _EncodeArgs {
  final img.Image image;
  final int quality;
  _EncodeArgs(this.image, this.quality);
}

List<int> _encodeJpg(_EncodeArgs args) {
  return img.encodeJpg(args.image, quality: args.quality);
}
