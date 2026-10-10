import 'package:geomapcam/features/overlay/domain/overlay_snapshot.dart';

class CaptureResult {
  final String filePath;
  final OverlaySnapshot snapshot;
  final int width;
  final int height;
  final DateTime createdAt;

  const CaptureResult({
    required this.filePath,
    required this.snapshot,
    required this.width,
    required this.height,
    required this.createdAt,
  });
}
