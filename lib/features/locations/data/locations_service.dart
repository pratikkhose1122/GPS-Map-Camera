import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geomapcam/features/locations/domain/models/saved_location.dart';

class LocationsService extends ChangeNotifier {
  static const String _savedLocationsKey = 'saved_locations';

  final SharedPreferences _prefs;
  List<SavedLocation> _locations = [];

  SavedLocation? _selectedLocation;

  LocationsService(this._prefs) {
    _loadLocations();
  }

  List<SavedLocation> get locations => List.unmodifiable(_locations);
  SavedLocation? get selectedLocation => _selectedLocation;
  bool get isLiveMode => _selectedLocation == null;

  void _loadLocations() {
    final String? jsonStr = _prefs.getString(_savedLocationsKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final List<SavedLocation> loaded = [];
        for (final item in decoded) {
          try {
            loaded.add(SavedLocation.fromJson(item));
          } catch (e) {
            debugPrint('Failed to parse a saved location: $e');
          }
        }
        _locations = loaded;
        _sortLocations();
      } catch (e) {
        debugPrint('Failed to load saved locations: $e');
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final String encoded = jsonEncode(
      _locations.map((e) => e.toJson()).toList(),
    );
    await _prefs.setString(_savedLocationsKey, encoded);
  }

  Future<void> addLocation(SavedLocation location) async {
    _locations.add(location);
    _sortLocations();
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> updateLocation(SavedLocation location) async {
    final index = _locations.indexWhere((l) => l.id == location.id);
    if (index != -1) {
      _locations[index] = location;
      _sortLocations();
      await _saveToPrefs();
      if (_selectedLocation?.id == location.id) {
        _selectedLocation = location;
      }
      notifyListeners();
    }
  }

  Future<void> deleteLocation(String id) async {
    _locations.removeWhere((l) => l.id == id);
    await _saveToPrefs();
    if (_selectedLocation?.id == id) {
      _selectedLocation = null;
    }
    notifyListeners();
  }

  void selectLocation(SavedLocation? location) {
    if (_selectedLocation?.id == location?.id && location != null) return;
    _selectedLocation = location;
    notifyListeners();
  }

  void _sortLocations() {
    _locations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
