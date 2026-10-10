import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import '../domain/location_data.dart';
import '../domain/location_state.dart';
import '../domain/address_data.dart';
import 'reverse_geocoding_service.dart';

/// Manages GPS location permissions, service state, and live updates.
class LocationService extends ChangeNotifier {
  LocationState _state = LocationState.initializing;
  LocationData? _locationData;
  AddressData? _addressData;
  String? _errorMessage;
  bool _isFetchingAddress = false;
  bool _addressError = false;

  final ReverseGeocodingService _geocodingService = ReverseGeocodingService();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  LocationState get state => _state;
  LocationData? get locationData => _locationData;
  AddressData? get addressData => _addressData;
  String? get errorMessage => _errorMessage;
  bool get isFetchingAddress => _isFetchingAddress;
  bool get addressError => _addressError;

  /// Start checking permissions and initializing location tracking.
  Future<void> initialize() async {
    if (_state != LocationState.initializing) {
      _setState(LocationState.initializing);
    }

    try {
      // 1. Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setState(LocationState.serviceDisabled);
        _listenToServiceStatus();
        return;
      }

      // 2. Request location permissions
      final status = await Permission.location.request();

      if (status.isGranted) {
        _setState(LocationState.acquiring);
        _startLocationStream();
        _listenToServiceStatus();
      } else if (status.isPermanentlyDenied) {
        _setState(LocationState.permissionPermanentlyDenied);
      } else {
        _setState(LocationState.permissionDenied);
      }
    } catch (e) {
      _setError('Failed to initialize location: $e');
    }
  }

  /// Listen to device GPS toggle (on/off).
  void _listenToServiceStatus() {
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((
      ServiceStatus status,
    ) {
      if (status == ServiceStatus.disabled) {
        _stopLocationStream();
        _setState(LocationState.serviceDisabled);
      } else if (status == ServiceStatus.enabled) {
        if (_state == LocationState.serviceDisabled) {
          // Re-initialize to check permissions again and start stream
          initialize();
        }
      }
    });
  }

  void _startLocationStream() {
    _positionSubscription?.cancel();

    final LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 1, // update every 1 meter
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _handleNewPosition(position);
          },
          onError: (error) {
            _setError('Location stream error: $error');
          },
        );
  }

  void _handleNewPosition(Position position) {
    if (!isValidPosition(position)) {
      debugPrint('Received invalid location data.');
      return;
    }

    _locationData = LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      accuracy: position.accuracy >= 0 ? position.accuracy : null,
      altitude: position.altitude != 0.0
          ? position.altitude
          : null, // Handle geolocator altitude fallbacks if 0
      speed: position.speed >= 0 ? position.speed : null,
      heading: position.heading >= 0 ? position.heading : null,
    );

    _setState(LocationState.available);

    // Asynchronously fetch address
    _fetchAddress(_locationData!);
  }

  Future<void> _fetchAddress(LocationData data) async {
    if (_isFetchingAddress) return;

    _isFetchingAddress = true;
    notifyListeners();

    try {
      final address = await _geocodingService.getAddressForLocation(data);
      if (address != null && address != _addressData) {
        _addressData = address;
        _addressError = false;
      }
    } catch (e) {
      debugPrint('ReverseGeocoding failed: $e');
      if (_addressData == null) {
        _addressError = true;
      }
    } finally {
      _isFetchingAddress = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  bool isValidPosition(Position position) {
    if (position.latitude < -90.0 || position.latitude > 90.0) return false;
    if (position.longitude < -180.0 || position.longitude > 180.0) return false;
    if (position.accuracy < 0.0) return false;
    return true;
  }

  void _stopLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _locationData = null;
  }

  /// Opens system settings for permanently denied permissions.
  Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Pauses the location stream (e.g. when app is backgrounded).
  void pause() {
    _positionSubscription?.pause();
  }

  /// Resumes the location stream (e.g. when app returns to foreground).
  void resume() {
    if (_state == LocationState.serviceDisabled ||
        _state == LocationState.permissionDenied ||
        _state == LocationState.permissionPermanentlyDenied) {
      initialize();
    } else {
      _positionSubscription?.resume();
    }
  }

  void _setState(LocationState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _state = LocationState.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _state = LocationState.disposed;
    _positionSubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    super.dispose();
  }
}
