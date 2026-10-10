import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geomapcam/features/overlay/domain/models/overlay_template.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';
import 'package:geomapcam/features/storage/domain/models/filename_configuration.dart';

class SettingsService extends ChangeNotifier {
  static const String _templateKey = 'selected_template_id';
  static const String _plusCodeKey = 'plus_code_enabled';
  static const String _timeZoneKey = 'time_zone_enabled';
  static const String _noteKey = 'user_note';
  static const String _customFieldsKey = 'custom_fields';
  static const String _stampOrientationKey = 'stamp_orientation';
  static const String _photoQualityKey = 'photo_quality';
  static const String _saveOriginalKey = 'save_original';
  static const String _filenameConfigKey = 'filename_configuration';
  static const String _customName1Key = 'custom_name_1';
  static const String _customName2Key = 'custom_name_2';
  static const String _customName3Key = 'custom_name_3';
  static const String _sequenceNumberKey = 'filename_sequence_number';

  // New settings keys
  static const String _languageKey = 'app_language';
  static const String _themeModeKey = 'app_theme_mode';
  static const String _videoQualityKey = 'video_quality';
  static const String _volumeActionKey = 'volume_button_action';
  static const String _tapActionKey = 'screen_tap_action';
  static const String _qrDetectionKey = 'qr_code_detection';
  static const String _showAppLogoKey = 'show_app_logo';
  static const String _showCameraIndKey = 'show_camera_indicator';
  static const String _emailPhotoKey = 'email_photo';
  static const String _sharePhotoToggleKey = 'share_photo_toggle';
  static const String _showReportsKey = 'show_reports_toggle';

  final SharedPreferences _prefs;

  OverlayTemplate _selectedTemplate = OverlayTemplate.classic;
  bool _plusCodeEnabled = true;
  bool _timeZoneEnabled = true;
  String? _note;
  List<CustomField> _customFields = [];
  StampOrientation _stampOrientation = StampOrientation.automatic;
  PhotoQuality _photoQuality = PhotoQuality.high;
  bool _saveOriginal = false;

  FilenameConfiguration _filenameConfiguration =
      FilenameConfiguration.defaultConfig;
  String? _customName1;
  String? _customName2;
  String? _customName3;

  // New settings states
  String _language = 'English';
  String _appThemeMode = 'System';
  String _videoQuality = 'HD';
  String _volumeButtonAction = 'Photo Capture';
  String _screenTapAction = 'Focus';
  bool _qrCodeDetection = false;
  bool _showAppLogo = true;
  bool _showCameraIndicator = false;
  String _emailPhoto = 'Off';
  bool _sharePhotoToggle = true;
  bool _showReportsToggle = true;

  SettingsService(this._prefs) {
    _loadSettings();
  }

  OverlayTemplate get selectedTemplate => _selectedTemplate;
  bool get plusCodeEnabled => _plusCodeEnabled;
  bool get timeZoneEnabled => _timeZoneEnabled;
  String? get note => _note;
  List<CustomField> get customFields => List.unmodifiable(_customFields);
  StampOrientation get stampOrientation => _stampOrientation;
  PhotoQuality get photoQuality => _photoQuality;
  bool get saveOriginal => _saveOriginal;

  FilenameConfiguration get filenameConfiguration => _filenameConfiguration;
  String? get customName1 => _customName1;
  String? get customName2 => _customName2;
  String? get customName3 => _customName3;

  String get language => _language;
  String get appThemeMode => _appThemeMode;
  String get videoQuality => _videoQuality;
  String get volumeButtonAction => _volumeButtonAction;
  String get screenTapAction => _screenTapAction;
  bool get qrCodeDetection => _qrCodeDetection;
  bool get showAppLogo => _showAppLogo;
  bool get showCameraIndicator => _showCameraIndicator;
  String get emailPhoto => _emailPhoto;
  bool get sharePhotoToggle => _sharePhotoToggle;
  bool get showReportsToggle => _showReportsToggle;

  void _loadSettings() {
    final String? id = _prefs.getString(_templateKey);
    if (id != null) {
      _selectedTemplate = OverlayTemplate.fromId(id);
    }

    _plusCodeEnabled = _prefs.getBool(_plusCodeKey) ?? true;
    _timeZoneEnabled = _prefs.getBool(_timeZoneKey) ?? true;
    _note = _prefs.getString(_noteKey);

    final String? fieldsJson = _prefs.getString(_customFieldsKey);
    if (fieldsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(fieldsJson);
        _customFields = decoded.map((e) => CustomField.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Failed to load custom fields: $e');
        _customFields = [];
      }
    }

    final int orientationIdx = _prefs.getInt(_stampOrientationKey) ?? 0;
    if (orientationIdx >= 0 &&
        orientationIdx < StampOrientation.values.length) {
      _stampOrientation = StampOrientation.values[orientationIdx];
    }

    final int qualityIdx = _prefs.getInt(_photoQualityKey) ?? 1; // High default
    if (qualityIdx >= 0 && qualityIdx < PhotoQuality.values.length) {
      _photoQuality = PhotoQuality.values[qualityIdx];
    }

    _saveOriginal = _prefs.getBool(_saveOriginalKey) ?? false;

    final String? configJson = _prefs.getString(_filenameConfigKey);
    if (configJson != null) {
      try {
        _filenameConfiguration = FilenameConfiguration.fromJson(
          jsonDecode(configJson),
        );
      } catch (e) {
        debugPrint('Failed to load filename configuration: $e');
      }
    }

    _customName1 = _prefs.getString(_customName1Key);
    _customName2 = _prefs.getString(_customName2Key);
    _customName3 = _prefs.getString(_customName3Key);

    _language = _prefs.getString(_languageKey) ?? 'English';
    _appThemeMode = _prefs.getString(_themeModeKey) ?? 'System';
    _videoQuality = _prefs.getString(_videoQualityKey) ?? 'HD';
    _volumeButtonAction = _prefs.getString(_volumeActionKey) ?? 'Photo Capture';
    _screenTapAction = _prefs.getString(_tapActionKey) ?? 'Focus';
    _qrCodeDetection = _prefs.getBool(_qrDetectionKey) ?? false;
    _showAppLogo = _prefs.getBool(_showAppLogoKey) ?? true;
    _showCameraIndicator = _prefs.getBool(_showCameraIndKey) ?? false;
    _emailPhoto = _prefs.getString(_emailPhotoKey) ?? 'Off';
    _sharePhotoToggle = _prefs.getBool(_sharePhotoToggleKey) ?? true;
    _showReportsToggle = _prefs.getBool(_showReportsKey) ?? true;
  }

  /// Consumes the next sequence number and persists the increment atomically.
  Future<int> consumeNextSequenceNumber() async {
    // Read current directly from prefs in case of cross-instance updates (though it's a singleton mostly)
    final current = _prefs.getInt(_sequenceNumberKey) ?? 1;
    await _prefs.setInt(_sequenceNumberKey, current + 1);
    return current;
  }

  Future<void> setTemplate(OverlayTemplate template) async {
    if (_selectedTemplate == template) return;
    _selectedTemplate = template;
    await _prefs.setString(_templateKey, template.id);
    notifyListeners();
  }

  Future<void> setPlusCodeEnabled(bool enabled) async {
    if (_plusCodeEnabled == enabled) return;
    _plusCodeEnabled = enabled;
    await _prefs.setBool(_plusCodeKey, enabled);
    notifyListeners();
  }

  Future<void> setTimeZoneEnabled(bool enabled) async {
    if (_timeZoneEnabled == enabled) return;
    _timeZoneEnabled = enabled;
    await _prefs.setBool(_timeZoneKey, enabled);
    notifyListeners();
  }

  Future<void> setNote(String? newNote) async {
    if (_note == newNote) return;
    String? cleanNote = newNote?.trim();
    if (cleanNote != null && cleanNote.length > 200) {
      cleanNote = cleanNote.substring(0, 200);
    }
    _note = (cleanNote != null && cleanNote.isNotEmpty) ? cleanNote : null;
    if (_note != null) {
      await _prefs.setString(_noteKey, _note!);
    } else {
      await _prefs.remove(_noteKey);
    }
    notifyListeners();
  }

  Future<void> setLanguage(String val) async {
    _language = val;
    await _prefs.setString(_languageKey, val);
    notifyListeners();
  }

  Future<void> setAppThemeMode(String val) async {
    _appThemeMode = val;
    await _prefs.setString(_themeModeKey, val);
    notifyListeners();
  }

  Future<void> setVideoQuality(String val) async {
    _videoQuality = val;
    await _prefs.setString(_videoQualityKey, val);
    notifyListeners();
  }

  Future<void> setVolumeButtonAction(String val) async {
    _volumeButtonAction = val;
    await _prefs.setString(_volumeActionKey, val);
    notifyListeners();
  }

  Future<void> setScreenTapAction(String val) async {
    _screenTapAction = val;
    await _prefs.setString(_tapActionKey, val);
    notifyListeners();
  }

  Future<void> setQrCodeDetection(bool val) async {
    _qrCodeDetection = val;
    await _prefs.setBool(_qrDetectionKey, val);
    notifyListeners();
  }

  Future<void> setShowAppLogo(bool val) async {
    _showAppLogo = val;
    await _prefs.setBool(_showAppLogoKey, val);
    notifyListeners();
  }

  Future<void> setShowCameraIndicator(bool val) async {
    _showCameraIndicator = val;
    await _prefs.setBool(_showCameraIndKey, val);
    notifyListeners();
  }

  Future<void> setEmailPhoto(String val) async {
    _emailPhoto = val;
    await _prefs.setString(_emailPhotoKey, val);
    notifyListeners();
  }

  Future<void> setSharePhotoToggle(bool val) async {
    _sharePhotoToggle = val;
    await _prefs.setBool(_sharePhotoToggleKey, val);
    notifyListeners();
  }

  Future<void> setShowReportsToggle(bool val) async {
    _showReportsToggle = val;
    await _prefs.setBool(_showReportsKey, val);
    notifyListeners();
  }

  Future<void> setCustomFields(List<CustomField> fields) async {
    _customFields = List.of(fields);
    final String encoded = jsonEncode(
      _customFields.map((e) => e.toJson()).toList(),
    );
    await _prefs.setString(_customFieldsKey, encoded);
    notifyListeners();
  }

  Future<void> setStampOrientation(StampOrientation orientation) async {
    if (_stampOrientation == orientation) return;
    _stampOrientation = orientation;
    await _prefs.setInt(_stampOrientationKey, orientation.index);
    notifyListeners();
  }

  Future<void> setPhotoQuality(PhotoQuality quality) async {
    if (_photoQuality == quality) return;
    _photoQuality = quality;
    await _prefs.setInt(_photoQualityKey, quality.index);
    notifyListeners();
  }

  Future<void> setSaveOriginal(bool save) async {
    if (_saveOriginal == save) return;
    _saveOriginal = save;
    await _prefs.setBool(_saveOriginalKey, save);
    notifyListeners();
  }

  Future<void> setFilenameConfiguration(FilenameConfiguration config) async {
    if (_filenameConfiguration == config) return;
    _filenameConfiguration = config;
    await _prefs.setString(_filenameConfigKey, jsonEncode(config.toJson()));
    notifyListeners();
  }

  Future<void> setCustomName1(String? name) async {
    final clean = _sanitizeCustomName(name);
    if (_customName1 == clean) return;
    _customName1 = clean;
    if (clean != null) {
      await _prefs.setString(_customName1Key, clean);
    } else {
      await _prefs.remove(_customName1Key);
    }
    notifyListeners();
  }

  Future<void> setCustomName2(String? name) async {
    final clean = _sanitizeCustomName(name);
    if (_customName2 == clean) return;
    _customName2 = clean;
    if (clean != null) {
      await _prefs.setString(_customName2Key, clean);
    } else {
      await _prefs.remove(_customName2Key);
    }
    notifyListeners();
  }

  Future<void> setCustomName3(String? name) async {
    final clean = _sanitizeCustomName(name);
    if (_customName3 == clean) return;
    _customName3 = clean;
    if (clean != null) {
      await _prefs.setString(_customName3Key, clean);
    } else {
      await _prefs.remove(_customName3Key);
    }
    notifyListeners();
  }

  String? _sanitizeCustomName(String? name) {
    if (name == null) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length > 50 ? trimmed.substring(0, 50) : trimmed;
  }
}
