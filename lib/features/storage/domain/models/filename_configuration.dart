import 'package:flutter/foundation.dart';

enum FilenameComponent {
  date,
  time,
  sequence,
  customName1,
  customName2,
  customName3,
  address,
  latitude,
  longitude,
  plusCode,
  timeZone,
  note,
}

/// Immutable configuration for generating filenames.
@immutable
class FilenameConfiguration {
  final List<FilenameComponent> components;
  final String separator;

  const FilenameConfiguration({required this.components, this.separator = '_'});

  /// The default configuration if none is provided.
  static const FilenameConfiguration defaultConfig = FilenameConfiguration(
    components: [FilenameComponent.date, FilenameComponent.time],
  );

  FilenameConfiguration copyWith({
    List<FilenameComponent>? components,
    String? separator,
  }) {
    return FilenameConfiguration(
      components: components ?? List.unmodifiable(this.components),
      separator: separator ?? this.separator,
    );
  }

  Map<String, dynamic> toJson() => {
    'components': components.map((e) => e.name).toList(),
    'separator': separator,
  };

  factory FilenameConfiguration.fromJson(Map<String, dynamic> json) {
    try {
      final comps = (json['components'] as List)
          .map((e) {
            try {
              return FilenameComponent.values.firstWhere((v) => v.name == e);
            } catch (_) {
              return null;
            }
          })
          .whereType<FilenameComponent>()
          .toList();
      return FilenameConfiguration(
        components: comps.isNotEmpty ? comps : defaultConfig.components,
        separator: json['separator'] as String? ?? '_',
      );
    } catch (_) {
      return defaultConfig;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilenameConfiguration &&
          runtimeType == other.runtimeType &&
          listEquals(components, other.components) &&
          separator == other.separator;

  @override
  int get hashCode => Object.hash(Object.hashAll(components), separator);
}
