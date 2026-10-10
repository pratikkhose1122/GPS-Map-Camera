import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'package:geomapcam/features/camera/data/camera_service.dart';
import 'package:geomapcam/features/settings/data/settings_service.dart';
import 'package:geomapcam/features/storage/domain/models/filename_configuration.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';
import 'package:geomapcam/features/capture/data/image_composer.dart';
import 'package:geomapcam/features/capture/data/video_composer.dart';
import 'package:geomapcam/features/capture/data/photo_storage_service.dart';
import 'package:geomapcam/features/capture/domain/capture_state.dart';
import 'package:geomapcam/features/capture/domain/capture_result.dart';

/// Holds all data needed to process a captured photo.
class CaptureJob {
  final XFile originalFile;
  final CaptureMetadata metadata;

  CaptureJob(this.originalFile, this.metadata);
}

/// Orchestrates the complete capture-to-gallery pipeline.
///
/// State machine:
///   idle → capturing → processing → saving → success
///
/// Failure at any stage → error
/// Error → resetToIdle() or retryProcessing() → idle/processing
/// Success → resetToIdle() → idle
///
/// ONE CAPTURE AT A TIME: new captures blocked until state returns to idle.
class CaptureService extends ChangeNotifier {
  final ImageComposer _composer;
  final VideoComposer _videoComposer;
  final PhotoStorageService _storageService;

  CaptureState _state = const CaptureState();
  CaptureState get state => _state;

  CaptureMetadata? _activeVideoMetadata;

  /// Retained for retry on processing failure.
  CaptureJob? _lastFailedJob;

  CaptureService({
    ImageComposer? composer,
    VideoComposer? videoComposer,
    PhotoStorageService? storageService,
  }) : _composer = composer ?? ImageComposer(),
       _videoComposer = videoComposer ?? VideoComposer(),
       _storageService = storageService ?? PhotoStorageService();

  Future<void> startVideoRecording({
    required CameraService cameraService,
    required SettingsService settingsService,
    required CaptureMetadata metadata,
  }) async {
    if (_state.status != CaptureStatus.idle) return;

    final int? sequenceNum =
        metadata.filenameConfiguration?.components.contains(
              FilenameComponent.sequence,
            ) ==
            true
        ? await settingsService.consumeNextSequenceNumber()
        : null;

    _activeVideoMetadata = metadata.copyWith(sequenceNumber: sequenceNum);

    _updateState(
      CaptureState(
        status: CaptureStatus.recording,
        snapshot: _activeVideoMetadata!.snapshot,
        templateName: _activeVideoMetadata!.template.name,
      ),
    );

    await cameraService.startVideoRecording();
  }

  Future<CaptureResult?> stopVideoRecording({
    required CameraService cameraService,
  }) async {
    if (_state.status != CaptureStatus.recording ||
        _activeVideoMetadata == null) {
      return null;
    }

    final metadata = _activeVideoMetadata!;
    _activeVideoMetadata = null;

    _updateState(
      CaptureState(
        status: CaptureStatus.processing,
        processingMessage: 'Processing video...',
        snapshot: metadata.snapshot,
        templateName: metadata.template.name,
      ),
    );

    try {
      final rawVideoFile = await cameraService.stopVideoRecording();
      if (rawVideoFile == null) throw Exception('Video recording failed.');

      final compositeVideo = await _videoComposer.compositeVideo(
        originalVideo: rawVideoFile,
        metadata: metadata,
      );

      _updateState(
        CaptureState(
          status: CaptureStatus.saving,
          processingMessage: 'Saving video...',
          snapshot: metadata.snapshot,
          templateName: metadata.template.name,
        ),
      );

      final resultPath = await _storageService.saveVideo(
        File(compositeVideo.path),
        metadata,
      );

      _updateState(
        CaptureState(
          status: CaptureStatus.success,
          filePath: resultPath,
          snapshot: metadata.snapshot,
          templateName: metadata.template.name,
        ),
      );

      return CaptureResult(
        filePath: resultPath,
        snapshot: metadata.snapshot,
        width: 1920, // Or extract from video
        height: 1080,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      _updateState(
        CaptureState(
          status: CaptureStatus.error,
          errorMessage: 'Video processing failed: $e',
          snapshot: metadata.snapshot,
          templateName: metadata.template.name,
        ),
      );
      return null;
    }
  }

  /// Captures a photo and processes it through the full pipeline.
  ///
  /// Returns the [CaptureResult] on success, null on failure.
  /// Only one capture can be active at a time.
  Future<CaptureResult?> capture({
    required CameraService cameraService,
    required SettingsService settingsService,
    required CaptureMetadata metadata,
  }) async {
    // ONE CAPTURE AT A TIME - block if not idle
    if (_state.status != CaptureStatus.idle) {
      debugPrint(
        'CaptureService: Blocked capture - current status: ${_state.status}',
      );
      return null;
    }

    // Synchronously mark as capturing to prevent race conditions during early async calls (like sequence number consumption)
    _updateState(
      const CaptureState(
        status: CaptureStatus.capturing,
        processingMessage: 'Preparing capture...',
      ),
    );

    _lastFailedJob = null;

    try {
      // 1. FREEZE SNAPSHOT — "What you see is what you capture"
      // The passed metadata is already an immutable snapshot generated by the OverlayController at the time of button press.
      // We consume the sequence number atomically right before capture.
      final int? sequenceNum =
          metadata.filenameConfiguration?.components.contains(
                FilenameComponent.sequence,
              ) ==
              true
          ? await settingsService.consumeNextSequenceNumber()
          : null;

      final CaptureMetadata frozenMetadata = metadata.copyWith(
        sequenceNumber: sequenceNum,
      );

      // 2. LOCATION READINESS CHECK
      if (!frozenMetadata.snapshot.hasRequiredLocation) {
        _updateState(
          const CaptureState(
            status: CaptureStatus.error,
            errorMessage: 'Waiting for a valid location.',
          ),
        );
        return null;
      }

      // 3. CAMERA CAPTURE
      _updateState(
        CaptureState(
          status: CaptureStatus.capturing,
          processingMessage: 'Capturing...',
          snapshot: frozenMetadata.snapshot,
          templateName: frozenMetadata.template.name,
        ),
      );

      final cameraController = cameraService.controller;
      if (cameraController == null || !cameraController.value.isInitialized) {
        throw Exception('Camera is not initialized.');
      }

      final captureSw = Stopwatch()..start();
      final xFile = await cameraController.takePicture();
      captureSw.stop();
      debugPrint(
        'PERF: Camera capture took ${captureSw.elapsedMilliseconds} ms',
      );

      // 4. VERIFY ORIGINAL FILE
      final originalFile = File(xFile.path);
      if (!await originalFile.exists()) {
        throw Exception('Camera captured but file not found.');
      }
      debugPrint(
        'PERF: Original camera file: ${xFile.path} (${await originalFile.length()} bytes)',
      );

      // 5. ORIGINAL IMAGE IS NOW SAFELY CAPTURED — proceed to processing
      final job = CaptureJob(xFile, frozenMetadata);
      return await _processJob(job);
    } catch (e) {
      _updateState(
        CaptureState(
          status: CaptureStatus.error,
          errorMessage:
              'Unable to capture photo: ${_sanitizeError(e.toString())}',
        ),
      );
      return null;
    }
  }

  /// Processes a capture job through map generation, overlay, composition, and save.
  Future<CaptureResult?> _processJob(CaptureJob job) async {
    try {
      // PROCESSING: Map + Overlay + Composition
      _updateState(
        CaptureState(
          status: CaptureStatus.processing,
          processingMessage: 'Generating map...',
          snapshot: job.metadata.snapshot,
          templateName: job.metadata.template.name,
        ),
      );

      final totalSw = Stopwatch()..start();

      final readSw = Stopwatch()..start();
      final rawBytes = await job.originalFile.readAsBytes();
      readSw.stop();
      debugPrint('PERF: Image file read took ${readSw.elapsedMilliseconds} ms');

      // Update progress message
      _updateState(_state.copyWith(processingMessage: 'Adding metadata...'));

      // COMPOSE IMAGE (includes map fetch, overlay render, composition, JPEG encode)
      final compositedBytes = await _composer.composite(rawBytes, job.metadata);

      if (job.metadata.saveOriginal) {
        try {
          await _storageService.saveOriginalImage(rawBytes, job.metadata);
        } catch (e) {
          debugPrint('Failed to save original image: $e');
        }
      }

      // SAVING
      _updateState(
        _state.copyWith(
          status: CaptureStatus.saving,
          processingMessage: 'Saving...',
        ),
      );

      final writeSw = Stopwatch()..start();
      final savedPath = await _storageService.saveImage(
        compositedBytes,
        job.metadata,
      );

      if (job.metadata.saveOriginal) {
        try {
          await _storageService.saveOriginalImage(rawBytes, job.metadata);
        } catch (e) {
          // Original save failure must NOT corrupt the processed photo.
          // The stamped image is already saved successfully above.
          debugPrint('Warning: Failed to save original image: $e');
        }
      }
      writeSw.stop();
      debugPrint(
        'PERF: Final file write/rename took ${writeSw.elapsedMilliseconds} ms',
      );

      totalSw.stop();
      debugPrint(
        'PERF: Total post-capture processing time: ${totalSw.elapsedMilliseconds} ms',
      );

      // Verify final file
      final savedFile = File(savedPath);
      if (!await savedFile.exists()) {
        throw Exception('Final photo file was not created.');
      }

      // Cleanup temporary original camera file
      _cleanupFile(job.originalFile.path);

      final result = CaptureResult(
        filePath: savedPath,
        snapshot: job.metadata.snapshot,
        width: 0,
        height: 0,
        createdAt: job.metadata.snapshot.timestamp,
      );

      // SUCCESS — state persists until UI calls resetToIdle()
      _updateState(
        CaptureState(
          status: CaptureStatus.success,
          filePath: savedPath,
          processingMessage: 'Photo ready',
          snapshot: job.metadata.snapshot,
          templateName: job.metadata.template.name,
        ),
      );

      _lastFailedJob = null;
      return result;
    } catch (e) {
      // Retain the job for retry
      _lastFailedJob = job;

      final errorMsg = e.toString();
      String userMessage;
      if (errorMsg.contains('Static Maps API key is missing') ||
          errorMsg.contains('Map generation failed')) {
        userMessage = 'Photo captured, but map generation failed.';
      } else if (errorMsg.contains('Failed to decode')) {
        userMessage = 'Unable to create the GPS photo.';
      } else if (errorMsg.contains('Storage error') ||
          errorMsg.contains('save') ||
          errorMsg.contains('write')) {
        userMessage = 'Unable to save the photo.';
      } else {
        userMessage = 'Photo captured, but processing failed.';
      }

      _updateState(
        CaptureState(
          status: CaptureStatus.error,
          errorMessage: userMessage,
          snapshot: job.metadata.snapshot,
          templateName: job.metadata.template.name,
        ),
      );

      debugPrint('CaptureService processing error: $e');
      return null;
    }
  }

  /// Retry processing the last failed capture job.
  /// Only available when state is error and a failed job exists.
  Future<CaptureResult?> retryProcessing() async {
    if (_state.status != CaptureStatus.error || _lastFailedJob == null) {
      return null;
    }

    final job = _lastFailedJob!;

    // Verify the original file still exists
    final originalFile = File(job.originalFile.path);
    if (!await originalFile.exists()) {
      _updateState(
        const CaptureState(
          status: CaptureStatus.error,
          errorMessage: 'Original photo no longer available. Please retake.',
        ),
      );
      _lastFailedJob = null;
      return null;
    }

    return await _processJob(job);
  }

  /// Discard the failed job and return to idle.
  /// Cleans up any temporary files.
  void discardAndReset() {
    if (_lastFailedJob != null) {
      _cleanupFile(_lastFailedJob!.originalFile.path);
      _lastFailedJob = null;
    }
    resetToIdle();
  }

  /// Reset to idle state. Called by result screen / error screen when user is done.
  void resetToIdle() {
    _updateState(const CaptureState());
  }

  /// Clean up abandoned temporary files from interrupted processing.
  /// Call on app startup.
  Future<void> cleanupAbandonedTempFiles() async {
    try {
      final dirPath = await _storageService.getAppStorageDirectory();
      final dir = Directory(dirPath);
      if (!await dir.exists()) return;

      final entities = await dir.list().toList();
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.tmp')) {
          debugPrint('Cleaning up abandoned temp file: ${entity.path}');
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up temp files: $e');
    }
  }

  /// Whether retry is available (in error state with a retained job).
  bool get canRetry =>
      _state.status == CaptureStatus.error && _lastFailedJob != null;

  void _cleanupFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }

  /// Sanitize error messages to avoid showing technical details to users.
  String _sanitizeError(String error) {
    // Remove 'Exception: ' prefix
    final cleaned = error.replaceFirst(RegExp(r'^Exception:\s*'), '');
    // Don't show HTTP codes, stack traces, API endpoints
    if (cleaned.contains('HTTP') ||
        cleaned.contains('Socket') ||
        cleaned.contains('Exception')) {
      return 'An unexpected error occurred.';
    }
    return cleaned;
  }

  void _updateState(CaptureState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }
}
