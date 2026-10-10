import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geomapcam/app/router/app_router.dart';
import 'package:geomapcam/core/utils/format_utils.dart';
import '../data/camera_service.dart';
import '../domain/camera_state.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:geomapcam/features/compass/data/compass_service.dart';
import 'package:geomapcam/features/overlay/presentation/overlay_controller.dart';
import 'package:geomapcam/features/overlay/presentation/live_metadata_overlay.dart';
import '../../location/data/location_service.dart';
import '../../location/domain/location_state.dart';
import 'package:geomapcam/features/capture/data/capture_service.dart';
import 'package:geomapcam/features/capture/domain/capture_state.dart';
import 'package:geomapcam/core/providers/settings_provider.dart';
import 'package:geomapcam/features/settings/data/settings_service.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';
import 'package:geomapcam/features/overlay/domain/models/overlay_template.dart';
import 'package:geomapcam/core/providers/locations_provider.dart';
import 'package:geomapcam/features/locations/data/locations_service.dart';
import 'package:open_location_code/open_location_code.dart' as olc;
import 'package:geomapcam/features/overlay/domain/overlay_snapshot.dart';
import 'package:geomapcam/features/locations/domain/models/saved_location.dart';

import 'package:geomapcam/core/localization/app_localizations.dart';

/// Camera screen displaying the real device camera preview and live location.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  late final CameraService _cameraService;
  late final LocationService _locationService;
  late final CompassService _compassService;
  late final OverlayController _overlayController;
  late final CaptureService _captureService;

  GoogleMapController? _mapController;
  LatLng? _lastMapCenter;

  static const EventChannel _volumeChannel = EventChannel(
    'com.geomapcam.geotag/volume',
  );
  StreamSubscription? _volumeSubscription;

  Offset? _focusPoint;
  Timer? _focusTimer;
  bool _showExposureControl = false;
  bool _initialized = false;
  PhotoQuality? _lastPhotoQuality;
  String? _lastVideoQuality;

  bool _isVideoMode = false;
  bool _isShareMode = false;
  Timer? _videoTimer;
  int _videoSeconds = 0;

  double _baseZoomLevel = 1.0;
  String _aspectRatio = '4:3';

  void _toggleAspectRatio() {
    setState(() {
      if (_aspectRatio == '4:3') {
        _aspectRatio = '16:9';
      } else if (_aspectRatio == '16:9') {
        _aspectRatio = '1:1';
      } else if (_aspectRatio == '1:1') {
        _aspectRatio = 'Full';
      } else {
        _aspectRatio = '4:3';
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cameraService = CameraService();
    _locationService = LocationService();
    _compassService = CompassService();
    _captureService = CaptureService();

    _captureService.addListener(_onCaptureStateChanged);

    // Start initializations after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cameraService.initialize();
      _locationService.initialize();
      _compassService.start();
    });

    _volumeSubscription = _volumeChannel.receiveBroadcastStream().listen((
      event,
    ) {
      if (!mounted) return;
      final action = SettingsProvider.of(context).volumeButtonAction;
      if (action == 'Photo Capture') {
        _attemptCapture();
      } else if (action == 'Zoom') {
        if (_cameraService.state == CameraState.ready) {
          final maxZoom = _cameraService.maxZoomLevel;
          final current = _cameraService.currentZoomLevel;
          if (current < 2.0 && maxZoom >= 2.0) {
            _cameraService.setZoomLevel(2.0);
          } else if (current < maxZoom) {
            _cameraService.setZoomLevel(maxZoom);
          } else {
            _cameraService.setZoomLevel(1.0);
          }
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settingsService = SettingsProvider.of(context);

    if (!_initialized) {
      final locationsService = LocationsProvider.of(context);
      _overlayController = OverlayController(
        locationService: _locationService,
        compassService: _compassService,
        settingsService: settingsService,
        locationsService: locationsService,
      );
      _lastPhotoQuality = settingsService.photoQuality;
      _lastVideoQuality = settingsService.videoQuality;
      _initialized = true;
    } else {
      if (_lastPhotoQuality != settingsService.photoQuality ||
          _lastVideoQuality != settingsService.videoQuality) {
        _lastPhotoQuality = settingsService.photoQuality;
        _lastVideoQuality = settingsService.videoQuality;
        _cameraService.setResolutionPreset(
          _getResolutionPreset(settingsService),
        );
      }
    }
  }

  ResolutionPreset _getResolutionPreset(SettingsService settings) {
    if (_isVideoMode) {
      switch (settings.videoQuality) {
        case '4K':
          return ResolutionPreset.ultraHigh;
        case 'Full HD':
          return ResolutionPreset.veryHigh;
        case 'HD':
          return ResolutionPreset.high;
        default:
          return ResolutionPreset.high;
      }
    } else {
      switch (settings.photoQuality) {
        case PhotoQuality.high:
          return ResolutionPreset.max;
        case PhotoQuality.standard:
          return ResolutionPreset.high;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captureService.removeListener(_onCaptureStateChanged);
    _captureService.dispose();
    _overlayController.dispose();
    _compassService.dispose();
    _cameraService.dispose();
    _locationService.dispose();
    _volumeSubscription?.cancel();
    _focusTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraService.state != CameraState.disposed) {
      final controller = _cameraService.controller;
      if (state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused) {
        controller?.dispose();
      } else if (state == AppLifecycleState.resumed) {
        if (_cameraService.state == CameraState.ready ||
            _cameraService.state == CameraState.initializing) {
          _cameraService.initialize();
        }
      }
    }

    if (_locationService.state != LocationState.disposed) {
      if (state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused) {
        _locationService.pause();
        _compassService.stop();
      } else if (state == AppLifecycleState.resumed) {
        _locationService.resume();
        _compassService.start();
      }
    }
  }

  void _onCaptureStateChanged() {
    final state = _captureService.state;
    if (state.status == CaptureStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${state.errorMessage}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsProvider.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Layer
          Positioned.fill(
            child: ListenableBuilder(
              listenable: _cameraService,
              builder: (context, _) {
                return _buildCameraLayer(context);
              },
            ),
          ),

          // Video Timer Pill
          if (_isVideoMode &&
              _captureService.state.status == CaptureStatus.recording)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _formatVideoDuration(_videoSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 2. Top Controls Layer (Flash, Switch, Gallery, Settings)
          ListenableBuilder(
            listenable: _cameraService,
            builder: (context, _) {
              return _buildTopControls(context);
            },
          ),

          // 3. Mini Map Layer
          ListenableBuilder(
            listenable: settingsService,
            builder: (context, _) {
              if (!settingsService.selectedTemplate.showMap ||
                  settingsService.selectedTemplate.mapPosition !=
                      MapPosition.topRight) {
                return const SizedBox.shrink();
              }

              final isTopRight =
                  settingsService.selectedTemplate.mapPosition ==
                  MapPosition.topRight;

              return SafeArea(
                child: Align(
                  alignment: isTopRight
                      ? Alignment.topRight
                      : Alignment.bottomRight,
                  child: Padding(
                    padding: isTopRight
                        ? const EdgeInsets.only(
                            right: 16.0,
                            top: 72.0,
                          ) // below top controls
                        : const EdgeInsets.only(
                            right: 16.0,
                            bottom: 200.0,
                          ), // above bottom overlay
                    child: ListenableBuilder(
                      listenable: _locationService,
                      builder: (context, _) {
                        return _buildLocationOverlay();
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // 4. Professional Live Metadata Overlay
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 160.0,
                ), // above zoom & mode selector
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    settingsService,
                    _locationService,
                  ]),
                  builder: (context, _) {
                    final template = settingsService.selectedTemplate;
                    final isInlineMap =
                        template.showMap &&
                        template.mapPosition != MapPosition.topRight;
                    Widget? mapWidget;
                    if (isInlineMap &&
                        _locationService.state == LocationState.available &&
                        _locationService.locationData != null) {
                      mapWidget = _buildMiniMap(
                        _locationService.locationData!.latitude,
                        _locationService.locationData!.longitude,
                      );
                    }
                    return LiveMetadataOverlay(
                      controller: _overlayController,
                      mapWidget: mapWidget,
                    );
                  },
                ),
              ),
            ),
          ),

          // 5. Processing Overlay
          ListenableBuilder(
            listenable: _captureService,
            builder: (context, _) {
              final status = _captureService.state.status;
              if (status == CaptureStatus.capturing ||
                  status == CaptureStatus.processing ||
                  status == CaptureStatus.saving) {
                return Align(
                  alignment:
                      Alignment.center, // Center is better for visual focus
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status != CaptureStatus.capturing)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        if (status != CaptureStatus.capturing)
                          const SizedBox(width: 16),
                        Text(
                          _getProcessingText(status),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // 6. Exposure Overlay
          ListenableBuilder(
            listenable: _cameraService,
            builder: (context, _) {
              return _buildExposureControls();
            },
          ),

          // 7. Zoom Controls
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 180.0),
                child: ListenableBuilder(
                  listenable: _cameraService,
                  builder: (context, _) {
                    return _buildZoomControls();
                  },
                ),
              ),
            ),
          ),

          // 8. Mode Selector
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 130.0),
                child: _buildModeSelector(context),
              ),
            ),
          ),

          // 9. Bottom Nav Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNavBar(context, settingsService),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, SettingsService settings) {
    return Container(
      decoration: BoxDecoration(
        color: _aspectRatio == 'Full' ? Colors.transparent : Colors.black,
        gradient: _aspectRatio == 'Full'
            ? LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.9),
                  Colors.black.withValues(alpha: 0.0),
                ],
              )
            : null,
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 40),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNavIcon(
              Icons.photo_library,
              'Gallery',
              () => Navigator.pushNamed(context, AppRouter.gallery),
            ),
            _buildNavIcon(
              Icons.grid_view,
              'Template',
              () => Navigator.pushNamed(context, AppRouter.templates),
            ),

            // Shutter Button
            ListenableBuilder(
              listenable: Listenable.merge([
                _cameraService,
                _captureService,
                _locationService,
              ]),
              builder: (context, _) {
                return ScaleTap(
                  onTap: _attemptCapture,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(child: _buildInnerShutter()),
                  ),
                );
              },
            ),

            _buildNavIcon(
              Icons.location_on,
              'Location',
              () =>
                  _showLocationSelector(context, LocationsProvider.of(context)),
            ),
            _buildNavIcon(
              Icons.folder,
              'Storage',
              () => Navigator.pushNamed(context, AppRouter.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, VoidCallback onTap) {
    return ScaleTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLayer(BuildContext context) {
    switch (_cameraService.state) {
      case CameraState.initializing:
        return const Center(child: CircularProgressIndicator());

      case CameraState.permissionDenied:
        return _buildErrorState(
          context,
          'Camera permission is required to use GPS Map Camera.',
          actionText: 'Grant Permission',
          onAction: () => _cameraService.initialize(),
        );

      case CameraState.permissionPermanentlyDenied:
        return _buildErrorState(
          context,
          'Camera permission is permanently denied. Please enable it in system settings.',
          actionText: 'Open Settings',
          onAction: () => _cameraService.openSettings(),
        );

      case CameraState.noCamera:
        return _buildErrorState(context, 'No camera found on this device.');

      case CameraState.error:
        return _buildErrorState(
          context,
          _cameraService.errorMessage ??
              'An error occurred initializing the camera.',
          actionText: 'Retry',
          onAction: () => _cameraService.initialize(),
        );

      case CameraState.ready:
        final controller = _cameraService.controller;
        if (controller == null || !controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final double previewWidth = controller.value.previewSize?.height ?? 1;
        final double previewHeight = controller.value.previewSize?.width ?? 1;

        final previewWidget = FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewWidth,
            height: previewHeight,
            child: GestureDetector(
              onTapDown: (details) => _onTapToFocus(
                details,
                controller,
                previewWidth,
                previewHeight,
              ),
              onScaleStart: (details) {
                _baseZoomLevel = _cameraService.currentZoomLevel;
              },
              onScaleUpdate: (details) {
                if (details.scale == 1.0) return;
                final newZoom = (_baseZoomLevel * details.scale).clamp(
                  _cameraService.minZoomLevel,
                  _cameraService.maxZoomLevel,
                );
                _cameraService.setZoomLevel(newZoom);
              },
              child: Stack(
                children: [
                  CameraPreview(controller),
                  if (_focusPoint != null)
                    Positioned(
                      left: _focusPoint!.dx - 40,
                      top: _focusPoint!.dy - 40,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

        if (_aspectRatio == 'Full') {
          return SizedBox.expand(child: previewWidget);
        } else {
          double ratioValue;
          if (_aspectRatio == '1:1') {
            ratioValue = 1.0;
          } else if (_aspectRatio == '16:9') {
            ratioValue = 9.0 / 16.0;
          } else {
            ratioValue = 3.0 / 4.0;
          }

          return Container(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: ratioValue,
                child: ClipRect(child: previewWidget),
              ),
            ),
          );
        }

      case CameraState.disposed:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLocationOverlay() {
    if (_locationService.state != LocationState.available) {
      return _buildLocationStatus();
    }

    final data = _locationService.locationData;
    if (data == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mini Map
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white70, width: 2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: _buildMiniMap(data.latitude, data.longitude),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMap(double latitude, double longitude) {
    final latLng = LatLng(latitude, longitude);

    if (_mapController != null && _lastMapCenter != null) {
      // Recenter only if moved more than ~5 meters to avoid jitter
      final dist = FormatUtils.haversineDistance(
        _lastMapCenter!.latitude,
        _lastMapCenter!.longitude,
        latitude,
        longitude,
      );
      if (dist > 5.0) {
        _lastMapCenter = latLng;
        _mapController!.animateCamera(CameraUpdate.newLatLng(latLng));
      }
    } else {
      _lastMapCenter = latLng;
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: latLng, zoom: 16.0),
      mapType: MapType.normal,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      rotateGesturesEnabled: false,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: false,
      zoomGesturesEnabled: true,
      markers: {
        Marker(markerId: const MarkerId('current_location'), position: latLng),
      },
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
  }

  Widget _buildLocationStatus() {
    String statusText = '';
    Color statusColor = Colors.black54;

    switch (_locationService.state) {
      case LocationState.initializing:
        statusText = 'Checking location services...';
        break;
      case LocationState.permissionDenied:
        statusText = 'Location permission required';
        statusColor = Colors.red.withValues(alpha: 0.8);
        break;
      case LocationState.permissionPermanentlyDenied:
        statusText = 'Location permanently denied';
        statusColor = Colors.red.withValues(alpha: 0.8);
        break;
      case LocationState.serviceDisabled:
        statusText = 'Location services disabled';
        statusColor = Colors.red.withValues(alpha: 0.8);
        break;
      case LocationState.acquiring:
        statusText = 'Acquiring location...';
        statusColor = Colors.orange.withValues(alpha: 0.8);
        break;
      case LocationState.error:
        statusText = 'Location error';
        statusColor = Colors.red.withValues(alpha: 0.8);
        break;
      case LocationState.disposed:
        statusText = '';
        break;
      case LocationState.available:
        if (!_overlayController.snapshot.hasRequiredLocation) {
          statusText = 'Waiting for location...';
          statusColor = Colors.orange.withValues(alpha: 0.8);
        } else {
          statusText = '';
        }
        break;
    }

    if (statusText.isEmpty) return const SizedBox.shrink();

    IconData? statusIcon;
    if (statusColor == Colors.red.withValues(alpha: 0.8)) {
      statusIcon = Icons.error_outline;
    } else if (statusColor == Colors.orange.withValues(alpha: 0.8)) {
      statusIcon = Icons.location_searching;
    } else {
      statusIcon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(20), // pill shape
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message, {
    String? actionText,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_photography_outlined,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionText)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls(BuildContext context) {
    if (_cameraService.state != CameraState.ready) {
      return const SizedBox.shrink();
    }

    final controller = _cameraService.controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        color: _aspectRatio == 'Full'
            ? Colors.black38
            : Colors.black, // Transparent/translucent overlay if Full
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_cameraService.hasMultipleCameras)
                  _buildTopIcon(
                    Icons.flip_camera_ios_outlined,
                    () => _cameraService.switchCamera(),
                  ),
                _buildTopIcon(
                  _getFlashIcon(controller.value.flashMode),
                  () => _cameraService.toggleFlash(),
                ),
                if (SettingsProvider.of(context).showReportsToggle)
                  _buildTopIcon(
                    Icons.note_add_outlined,
                    () => Navigator.pushNamed(context, AppRouter.reports),
                  ),
                _buildTopIcon(
                  Icons.location_on_outlined,
                  () => _showLocationSelector(
                    context,
                    LocationsProvider.of(context),
                  ),
                ),
                if (_cameraService.minExposureOffset <
                    _cameraService.maxExposureOffset)
                  _buildTopIcon(Icons.exposure_outlined, () {
                    setState(() {
                      _showExposureControl = !_showExposureControl;
                    });
                  }, isActive: _showExposureControl),
                _buildTopRatioIcon(),
                _buildTopIcon(
                  Icons.settings_outlined,
                  () => Navigator.pushNamed(context, AppRouter.settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopIcon(
    IconData icon,
    VoidCallback onPressed, {
    bool isActive = false,
  }) {
    return IconButton(
      icon: Icon(icon),
      color: isActive ? Theme.of(context).colorScheme.primary : Colors.white,
      iconSize: 26,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildTopRatioIcon() {
    return IconButton(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.crop_free, color: Colors.white, size: 28),
          Text(
            _aspectRatio,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      onPressed: _toggleAspectRatio,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
    );
  }

  IconData _getFlashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }

  String _getProcessingText(CaptureStatus status) {
    switch (status) {
      case CaptureStatus.capturing:
        return '';
      case CaptureStatus.processing:
        return 'Processing';
      case CaptureStatus.saving:
        return 'Saving';
      default:
        return 'Processing';
    }
  }

  String _formatVideoDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildInnerShutter() {
    final isRecording = _captureService.state.status == CaptureStatus.recording;
    if (_isVideoMode) {
      if (isRecording) {
        return Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }
      return Container(
        height: 64,
        width: 64,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
        ),
      );
    }
    return Container(
      height: 64,
      width: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
    );
  }

  void _attemptCapture() async {
    final isReady = _cameraService.state == CameraState.ready;
    final isCaptureIdle = _captureService.state.status == CaptureStatus.idle;
    final isLocationReady = _overlayController.snapshot.hasRequiredLocation;
    final status = _captureService.state.status;

    if (_isVideoMode) {
      if (status == CaptureStatus.recording) {
        _videoTimer?.cancel();
        final result = await _captureService.stopVideoRecording(
          cameraService: _cameraService,
        );
        if (mounted) {
          setState(() {
            _videoSeconds = 0;
          });
        }
        if (result != null && mounted) {
          _captureService.resetToIdle();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video saved to Gallery')),
          );
        }
      } else if (status == CaptureStatus.idle && isReady && isLocationReady) {
        setState(() {
          _videoSeconds = 0;
        });
        await _captureService.startVideoRecording(
          cameraService: _cameraService,
          settingsService: SettingsProvider.of(context),
          metadata: _overlayController.metadata,
        );
        _videoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _videoSeconds++;
            });
          }
        });
      }
      return;
    }

    final canCapture = isReady && isCaptureIdle && isLocationReady;

    if (canCapture) {
      final result = await _captureService.capture(
        cameraService: _cameraService,
        settingsService: SettingsProvider.of(context),
        metadata: _overlayController.metadata,
      );
      if (result != null && mounted) {
        if (_isShareMode) {
          await Navigator.pushNamed(
            context,
            AppRouter.captureResult,
            arguments: result,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo saved to Gallery')),
          );
        }
        if (mounted) {
          _captureService.resetToIdle();
        }
      }
    }
  }

  void _onTapToFocus(
    TapDownDetails details,
    CameraController controller,
    double previewWidth,
    double previewHeight,
  ) {
    if (_cameraService.state != CameraState.ready) return;

    final tapAction = SettingsProvider.of(context).screenTapAction;
    if (tapAction == 'Capture') {
      _attemptCapture();
      return;
    }

    // Convert local position within the preview to 0.0-1.0 range
    final double x = details.localPosition.dx / previewWidth;
    final double y = details.localPosition.dy / previewHeight;

    _cameraService.setFocusPoint(Offset(x, y));

    setState(() {
      _focusPoint = details.localPosition;
      _showExposureControl = false; // Hide exposure when tapping to focus
    });

    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _focusPoint = null;
        });
      }
    });
  }

  Widget _buildZoomControls() {
    if (_cameraService.state != CameraState.ready) {
      return const SizedBox.shrink();
    }
    if (_cameraService.maxZoomLevel <= 1.0) return const SizedBox.shrink();

    final has2x = _cameraService.maxZoomLevel >= 2.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildZoomButton(1.0, '1x'),
        if (has2x) ...[const SizedBox(width: 16), _buildZoomButton(2.0, '2x')],
      ],
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    int selectedIndex = _isShareMode ? 0 : (_isVideoMode ? 2 : 1);

    // Pre-calculated shifts to center the active button exactly in the middle of the screen
    final List<double> dxValues = [
      135.0, // SHARE PHOTO
      27.5, // PHOTO
      -57.5, // VIDEO
      -150.0, // REPORTS
    ];

    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            // 192 is half the estimated total row width
            left:
                (MediaQuery.of(context).size.width / 2) -
                192 +
                dxValues[selectedIndex],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeButton(
                  context.tr('SHARE PHOTO'),
                  _isShareMode && !_isVideoMode,
                  () {
                    setState(() {
                      _isShareMode = true;
                      _isVideoMode = false;
                    });
                  },
                ),
                const SizedBox(width: 16),
                _buildModeButton(
                  context.tr('PHOTO'),
                  !_isShareMode && !_isVideoMode,
                  () {
                    setState(() {
                      _isShareMode = false;
                      _isVideoMode = false;
                    });
                  },
                ),
                const SizedBox(width: 16),
                _buildModeButton(context.tr('VIDEO'), _isVideoMode, () {
                  setState(() {
                    _isShareMode = false;
                    _isVideoMode = true;
                  });
                }),
                const SizedBox(width: 16),
                _buildModeButton(context.tr('REPORTS'), false, () {
                  Navigator.pushNamed(context, AppRouter.reports);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String text, bool isSelected, VoidCallback onTap) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFC107)
              : Colors.transparent, // Yellow pill
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildZoomButton(double zoomLevel, String label) {
    final isSelected =
        (_cameraService.currentZoomLevel - zoomLevel).abs() < 0.1;
    final theme = Theme.of(context);

    return Semantics(
      label: 'Zoom $label',
      button: true,
      child: GestureDetector(
        onTap: () => _cameraService.setZoomLevel(zoomLevel),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? theme.colorScheme.primary : Colors.black54,
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : Colors.white,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? theme.colorScheme.onPrimary : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExposureControls() {
    if (_cameraService.state != CameraState.ready) {
      return const SizedBox.shrink();
    }
    if (_cameraService.minExposureOffset == 0 &&
        _cameraService.maxExposureOffset == 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 16,
      top: 160,
      bottom: 240,
      child: AnimatedOpacity(
        opacity: _showExposureControl ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: _showExposureControl
            ? Container(
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.exposure_zero,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _cameraService.setExposureOffset(0.0),
                      tooltip: 'Reset Exposure',
                    ),
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                            activeTrackColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            inactiveTrackColor: Colors.white30,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: _cameraService.currentExposureOffset,
                            min: _cameraService.minExposureOffset,
                            max: _cameraService.maxExposureOffset,
                            onChanged: (value) =>
                                _cameraService.setExposureOffset(value),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        _cameraService.currentExposureOffset.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  void _showLocationSelector(
    BuildContext context,
    LocationsService locationsService,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.place),
                    const SizedBox(width: 8),
                    Text(
                      'Select Location Source',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.my_location,
                  color: Colors.blueAccent,
                ),
                title: const Text('Live GPS'),
                subtitle: const Text('Use current device location'),
                trailing: locationsService.isLiveMode
                    ? const Icon(Icons.check, color: Colors.blueAccent)
                    : null,
                onTap: () {
                  locationsService.selectLocation(null);
                  Navigator.pop(context);
                },
              ),
              if (locationsService.locations.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Saved Locations',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                ...locationsService.locations
                    .take(3)
                    .map(
                      (loc) => ListTile(
                        leading: const Icon(Icons.place, color: Colors.green),
                        title: Text(loc.name),
                        subtitle: Text(
                          loc.address ??
                              '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
                        ),
                        trailing:
                            locationsService.selectedLocation?.id == loc.id
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          locationsService.selectLocation(loc);
                          Navigator.pop(context);
                        },
                      ),
                    ),
              ],
              const Divider(height: 1),
              if (_overlayController.snapshot.hasRequiredLocation)
                ListTile(
                  leading: const Icon(Icons.add_location_alt_outlined),
                  title: const Text('Save Current Location'),
                  onTap: () {
                    Navigator.pop(context);
                    _showSaveLocationDialog(
                      context,
                      locationsService,
                      _overlayController.snapshot,
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('Manage Locations'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRouter.locations);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSaveLocationDialog(
    BuildContext context,
    LocationsService locationsService,
    OverlaySnapshot snapshot,
  ) {
    final nameController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Location Name'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                String? plusCode;
                try {
                  plusCode = olc.PlusCode.encode(
                    olc.LatLng(snapshot.latitude!, snapshot.longitude!),
                  ).toString();
                } catch (e) {
                  debugPrint('PlusCode encode error: $e');
                }

                final savedLoc = SavedLocation.create(
                  name: name,
                  latitude: snapshot.latitude!,
                  longitude: snapshot.longitude!,
                  address: snapshot.address,
                  plusCode: plusCode,
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                );
                locationsService.addLocation(savedLoc);
                locationsService.selectLocation(savedLoc);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Location saved')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const ScaleTap({super.key, required this.child, required this.onTap});

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
