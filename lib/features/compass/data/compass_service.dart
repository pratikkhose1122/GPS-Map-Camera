import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geomapcam/core/utils/format_utils.dart';
import 'package:geomapcam/features/compass/domain/compass_state.dart';

class CompassService extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  double? _accelX, _accelY, _accelZ;

  CompassState _state = const CompassState();
  CompassState get state => _state;

  // Smoothing properties
  double? _lastSmoothedHeading;
  final double _smoothingFactor = 0.15; // lower is smoother but lags more

  bool _isListening = false;

  // Throttling for UI updates (e.g. max 15 FPS = ~66ms)
  DateTime _lastUpdate = DateTime.now();
  final Duration _updateThrottle = const Duration(milliseconds: 66);

  void start() {
    if (_isListening) return;
    _isListening = true;

    _accelSub = accelerometerEventStream().listen(
      (event) {
        _accelX = event.x;
        _accelY = event.y;
        _accelZ = event.z;
      },
      onError: (e) {
        debugPrint('Accelerometer error: $e');
      },
    );

    _magSub = magnetometerEventStream().listen(
      (event) {
        if (_accelX == null || _accelY == null || _accelZ == null) return;

        _processSensorData(
          _accelX!,
          _accelY!,
          _accelZ!,
          event.x,
          event.y,
          event.z,
        );
      },
      onError: (e) {
        debugPrint('Magnetometer error: $e');
        _updateState(const CompassState()); // Clear on error
      },
    );
  }

  void stop() {
    _isListening = false;
    _accelSub?.cancel();
    _accelSub = null;
    _magSub?.cancel();
    _magSub = null;

    // Clear state when stopped
    _lastSmoothedHeading = null;
    _accelX = null;
    _accelY = null;
    _accelZ = null;
    _updateState(const CompassState());
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  void _processSensorData(
    double ax,
    double ay,
    double az,
    double mx,
    double my,
    double mz,
  ) {
    // 1. Normalize accelerometer vector (Gravity vector A)
    double normA = sqrt(ax * ax + ay * ay + az * az);
    if (normA < 0.1) return; // Prevent division by zero / freefall
    ax /= normA;
    ay /= normA;
    az /= normA;

    // 2. Calculate East vector (E = M x A)
    // This gives a vector pointing East, perpendicular to gravity and magnetic north
    double ex = my * az - mz * ay;
    double ey = mz * ax - mx * az;
    double ez = mx * ay - my * ax;

    // Normalize East vector
    double normE = sqrt(ex * ex + ey * ey + ez * ez);
    if (normE < 0.1) return;
    ex /= normE;
    ey /= normE;
    ez /= normE;

    // 3. Calculate North vector (N = A x E)
    // This gives a vector pointing magnetic North, perpendicular to gravity
    // double nx = ay * ez - az * ey;
    double ny = az * ex - ax * ez;
    // double nz = ax * ey - ay * ex;

    // 4. Determine heading for Android portrait orientation.
    // In Android portrait, the Y axis of the device points out the top of the phone.
    // We project the Y axis (0, 1, 0) onto the East-North plane.
    // East component = E . Y = ey
    // North component = N . Y = ny
    double rawHeadingRad = atan2(ey, ny);

    double rawHeadingDeg = FormatUtils.normalizeAngle(rawHeadingRad * 180 / pi);

    // 5. Circular smoothing
    double smoothedHeading = FormatUtils.smoothHeading(
      _lastSmoothedHeading,
      rawHeadingDeg,
      factor: _smoothingFactor,
    );

    _lastSmoothedHeading = smoothedHeading;

    // 6. Throttle UI updates to prevent rebuilding UI on every raw sensor event
    final now = DateTime.now();
    if (now.difference(_lastUpdate) > _updateThrottle) {
      _lastUpdate = now;
      _updateState(
        CompassState(
          headingDegrees: smoothedHeading,
          cardinalDirection: FormatUtils.degreesToCardinal(smoothedHeading),
        ),
      );
    }
  }

  void _updateState(CompassState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }
}
