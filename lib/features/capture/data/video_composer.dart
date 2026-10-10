import 'dart:io';
import 'package:camera/camera.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';

class VideoComposer {
  VideoComposer();

  /// Composites the overlay onto the video using FFmpeg.
  Future<File> compositeVideo({
    required XFile originalVideo,
    required CaptureMetadata metadata,
  }) async {
    // FFMPEG processing temporarily disabled due to native build issues.
    // Returning the original video for now.
    return File(originalVideo.path);
  }
}
