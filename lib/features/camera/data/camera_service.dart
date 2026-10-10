import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:permission_handler/permission_handler.dart';
import '../domain/camera_state.dart';

/// Manages camera lifecycle, permissions, and device selection.
class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;

  CameraState _state = CameraState.initializing;
  String? _errorMessage;
  ResolutionPreset _resolutionPreset = ResolutionPreset.veryHigh;

  CameraState get state => _state;
  String? get errorMessage => _errorMessage;
  CameraController? get controller => _controller;

  bool get hasMultipleCameras => _cameras.length > 1;

  // Capabilities
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _currentZoomLevel = 1.0;

  double _minExposureOffset = 0.0;
  double _maxExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;

  double get minZoomLevel => _minZoomLevel;
  double get maxZoomLevel => _maxZoomLevel;
  double get currentZoomLevel => _currentZoomLevel;

  double get minExposureOffset => _minExposureOffset;
  double get maxExposureOffset => _maxExposureOffset;
  double get currentExposureOffset => _currentExposureOffset;

  /// Starts the camera initialization and permission flow.
  Future<void> initialize({
    ResolutionPreset preset = ResolutionPreset.veryHigh,
  }) async {
    _resolutionPreset = preset;
    if (_state != CameraState.initializing) {
      _setState(CameraState.initializing);
    }

    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        await _setupCamera();
      } else if (status.isPermanentlyDenied) {
        _setState(CameraState.permissionPermanentlyDenied);
      } else {
        _setState(CameraState.permissionDenied);
      }
    } catch (e) {
      _setError('Failed to request permission: $e');
    }
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _setState(CameraState.noCamera);
        return;
      }

      // Prefer rear camera initially
      _currentCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_currentCameraIndex == -1) {
        _currentCameraIndex = 0; // fallback to first available
      }

      await _initController(_cameras[_currentCameraIndex]);
    } catch (e) {
      _setError('Failed to setup camera: $e');
    }
  }

  Future<void> _initController(CameraDescription description) async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    final newController = CameraController(
      description,
      _resolutionPreset,
      enableAudio: false, // We only take photos
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = newController;

    try {
      await newController.initialize();

      // Fetch capabilities
      _minZoomLevel = await newController.getMinZoomLevel();
      _maxZoomLevel = await newController.getMaxZoomLevel();
      _currentZoomLevel = 1.0; // Reset to 1x on init

      _minExposureOffset = await newController.getMinExposureOffset();
      _maxExposureOffset = await newController.getMaxExposureOffset();
      _currentExposureOffset = 0.0; // Reset exposure on init

      _setState(CameraState.ready);
    } on CameraException catch (e) {
      _controller = null;
      _setError('Camera error: ${e.description}');
    } catch (e) {
      _controller = null;
      _setError('Unexpected error initializing camera: $e');
    }
  }

  /// Sets the resolution preset and re-initializes the camera.
  Future<void> setResolutionPreset(ResolutionPreset preset) async {
    if (_resolutionPreset == preset) return;
    _resolutionPreset = preset;
    if (_cameras.isNotEmpty && _state == CameraState.ready) {
      _setState(CameraState.initializing);
      await _initController(_cameras[_currentCameraIndex]);
    }
  }

  /// Sets the camera zoom level
  Future<void> setZoomLevel(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final clampedZoom = zoom.clamp(_minZoomLevel, _maxZoomLevel);
      await _controller!.setZoomLevel(clampedZoom);
      _currentZoomLevel = clampedZoom;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to set zoom level: $e');
    }
  }

  /// Sets the camera exposure offset
  Future<void> setExposureOffset(double offset) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final clampedOffset = offset.clamp(
        _minExposureOffset,
        _maxExposureOffset,
      );
      await _controller!.setExposureOffset(clampedOffset);
      _currentExposureOffset = clampedOffset;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to set exposure offset: $e');
    }
  }

  /// Sets focus point [0..1, 0..1]
  Future<void> setFocusPoint(Offset point) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      await _controller!.setFocusPoint(point);
      // We don't notifyListeners here because focus point is just a hardware command,
      // the UI focus indicator is handled locally in CameraScreen.
    } catch (e) {
      debugPrint('Failed to set focus point: $e');
    }
  }

  /// Switches to the next available camera (front/back).
  Future<void> switchCamera() async {
    if (_cameras.length <= 1 || _state != CameraState.ready) return;

    _setState(CameraState.initializing);

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _initController(_cameras[_currentCameraIndex]);
  }

  /// Toggles through available flash modes.
  Future<void> toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final currentMode = _controller!.value.flashMode;
    FlashMode nextMode;

    switch (currentMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.off;
        break;
    }

    try {
      await _controller!.setFlashMode(nextMode);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to set flash mode: $e');
    }
  }

  Future<void> startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isRecordingVideo) return;

    try {
      await _controller!.startVideoRecording();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to start video recording: $e');
    }
  }

  Future<XFile?> stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    if (!_controller!.value.isRecordingVideo) return null;

    try {
      final file = await _controller!.stopVideoRecording();
      notifyListeners();
      return file;
    } catch (e) {
      debugPrint('Failed to stop video recording: $e');
      return null;
    }
  }

  /// Opens system settings for permanently denied permissions.
  Future<void> openSettings() async {
    await openAppSettings();
  }

  void _setState(CameraState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _state = CameraState.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _state = CameraState.disposed;
    _controller?.dispose();
    super.dispose();
  }
}
