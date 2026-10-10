import 'package:uuid/uuid.dart';

class SavedLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? plusCode;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.plusCode,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedLocation.create({
    required String name,
    required double latitude,
    required double longitude,
    String? address,
    String? plusCode,
    String? note,
  }) {
    final now = DateTime.now();
    return SavedLocation(
      id: const Uuid().v4(),
      name: name,
      latitude: latitude,
      longitude: longitude,
      address: address,
      plusCode: plusCode,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'plusCode': plusCode,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    // Defensive parsing for malformed data
    return SavedLocation(
      id: json['id']?.toString() ?? const Uuid().v4(),
      name: json['name']?.toString() ?? 'Unknown',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address']?.toString(),
      plusCode: json['plusCode']?.toString(),
      note: json['note']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  SavedLocation copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    String? plusCode,
    String? note,
    DateTime? updatedAt,
  }) {
    return SavedLocation(
      id: id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      plusCode: plusCode ?? this.plusCode,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedLocation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
