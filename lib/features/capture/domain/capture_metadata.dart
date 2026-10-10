import 'package:geomapcam/features/overlay/domain/overlay_snapshot.dart';
import 'package:geomapcam/features/overlay/domain/models/overlay_template.dart';
import 'package:geomapcam/features/storage/domain/models/filename_configuration.dart';

enum StampOrientation { automatic, portrait, landscape }

enum PhotoQuality { standard, high }

enum LocationSourceType { live, saved }

class LocationSource {
  final LocationSourceType type;
  final String? savedLocationId;
  final String? savedLocationName;

  const LocationSource.live()
    : type = LocationSourceType.live,
      savedLocationId = null,
      savedLocationName = null;

  const LocationSource.saved({
    required this.savedLocationId,
    required this.savedLocationName,
  }) : type = LocationSourceType.saved;

  bool get isSaved => type == LocationSourceType.saved;
  bool get isLive => type == LocationSourceType.live;
}

class CustomField {
  final String id;
  final String label;
  final String value;
  final bool enabled;

  const CustomField({
    required this.id,
    required this.label,
    required this.value,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'value': value,
    'enabled': enabled,
  };

  factory CustomField.fromJson(Map<String, dynamic> json) => CustomField(
    id: json['id'] as String,
    label: json['label'] as String,
    value: json['value'] as String,
    enabled: json['enabled'] as bool? ?? true,
  );

  CustomField copyWith({
    String? id,
    String? label,
    String? value,
    bool? enabled,
  }) {
    return CustomField(
      id: id ?? this.id,
      label: label ?? this.label,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Immutable snapshot of all capture-time metadata.
class CaptureMetadata {
  final OverlaySnapshot snapshot;
  final OverlayTemplate template;

  final String? plusCode;
  final String? timezone;
  final String? note;
  final List<CustomField> customFields;
  final StampOrientation stampOrientation;
  final PhotoQuality photoQuality;
  final bool saveOriginal;
  final LocationSource locationSource;

  final bool showAppLogo;
  final bool showCameraIndicator;
  final String emailPhoto;
  final bool sharePhotoToggle;
  final bool showReportsToggle;

  // Filename frozen properties
  final FilenameConfiguration? filenameConfiguration;
  final int? sequenceNumber;
  final String? customName1;
  final String? customName2;
  final String? customName3;

  const CaptureMetadata({
    required this.snapshot,
    required this.template,
    this.plusCode,
    this.timezone,
    this.note,
    this.customFields = const [],
    this.stampOrientation = StampOrientation.automatic,
    this.photoQuality = PhotoQuality.high,
    this.saveOriginal = false,
    this.locationSource = const LocationSource.live(),
    this.showAppLogo = true,
    this.showCameraIndicator = false,
    this.emailPhoto = 'Off',
    this.sharePhotoToggle = true,
    this.showReportsToggle = true,
    this.filenameConfiguration,
    this.sequenceNumber,
    this.customName1,
    this.customName2,
    this.customName3,
  });

  CaptureMetadata copyWith({
    OverlaySnapshot? snapshot,
    OverlayTemplate? template,
    String? plusCode,
    String? timezone,
    String? note,
    List<CustomField>? customFields,
    StampOrientation? stampOrientation,
    PhotoQuality? photoQuality,
    bool? saveOriginal,
    LocationSource? locationSource,
    bool? showAppLogo,
    bool? showCameraIndicator,
    String? emailPhoto,
    bool? sharePhotoToggle,
    bool? showReportsToggle,
    FilenameConfiguration? filenameConfiguration,
    int? sequenceNumber,
    String? customName1,
    String? customName2,
    String? customName3,
  }) {
    return CaptureMetadata(
      snapshot: snapshot ?? this.snapshot,
      template: template ?? this.template,
      plusCode: plusCode ?? this.plusCode,
      timezone: timezone ?? this.timezone,
      note: note ?? this.note,
      customFields: customFields ?? this.customFields,
      stampOrientation: stampOrientation ?? this.stampOrientation,
      photoQuality: photoQuality ?? this.photoQuality,
      saveOriginal: saveOriginal ?? this.saveOriginal,
      locationSource: locationSource ?? this.locationSource,
      showAppLogo: showAppLogo ?? this.showAppLogo,
      showCameraIndicator: showCameraIndicator ?? this.showCameraIndicator,
      emailPhoto: emailPhoto ?? this.emailPhoto,
      sharePhotoToggle: sharePhotoToggle ?? this.sharePhotoToggle,
      showReportsToggle: showReportsToggle ?? this.showReportsToggle,
      filenameConfiguration:
          filenameConfiguration ?? this.filenameConfiguration,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      customName1: customName1 ?? this.customName1,
      customName2: customName2 ?? this.customName2,
      customName3: customName3 ?? this.customName3,
    );
  }
}
