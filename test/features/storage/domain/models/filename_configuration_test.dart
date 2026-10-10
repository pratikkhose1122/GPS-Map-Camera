import 'package:flutter_test/flutter_test.dart';
import 'package:geomapcam/features/storage/domain/models/filename_configuration.dart';

void main() {
  group('FilenameConfiguration Phase 16 Audit', () {
    test('Default configuration is date and time', () {
      expect(FilenameConfiguration.defaultConfig.components, [
        FilenameComponent.date,
        FilenameComponent.time,
      ]);
      expect(FilenameConfiguration.defaultConfig.separator, '_');
    });

    test('Serialization to/from JSON', () {
      final config = FilenameConfiguration(
        components: [FilenameComponent.customName1, FilenameComponent.sequence],
        separator: '-',
      );

      final json = config.toJson();
      expect(json['components'], ['customName1', 'sequence']);
      expect(json['separator'], '-');

      final restored = FilenameConfiguration.fromJson(json);
      expect(restored.components, config.components);
      expect(restored.separator, config.separator);
      expect(restored, config);
    });

    test('fromJson recovers gracefully from unknown components', () {
      final json = {
        'components': ['date', 'unknown_future_component', 'time'],
        'separator': '_',
      };

      final restored = FilenameConfiguration.fromJson(json);
      expect(restored.components, [
        FilenameComponent.date,
        FilenameComponent.time,
      ]);
    });

    test('fromJson recovers safely from completely malformed data', () {
      final json = {
        'components': 'not a list',
        'separator': 123, // not a string
      };

      final restored = FilenameConfiguration.fromJson(json);
      expect(restored, FilenameConfiguration.defaultConfig);
    });

    test('fromJson recovers if all components are invalid', () {
      final json = {
        'components': ['unknown1', 'unknown2'],
        'separator': '_',
      };

      final restored = FilenameConfiguration.fromJson(json);
      // Because comps becomes empty, it should fall back to default components.
      expect(
        restored.components,
        FilenameConfiguration.defaultConfig.components,
      );
    });
  });
}
