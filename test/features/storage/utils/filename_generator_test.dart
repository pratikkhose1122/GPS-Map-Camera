import 'package:flutter_test/flutter_test.dart';
import 'package:geomapcam/features/storage/utils/filename_generator.dart';
import 'package:geomapcam/features/storage/domain/models/filename_configuration.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';
import 'package:geomapcam/features/overlay/domain/overlay_snapshot.dart';
import 'package:geomapcam/features/overlay/domain/models/overlay_template.dart';

void main() {
  group('FilenameGenerator Phase 16 Audit', () {
    final baseSnapshot = OverlaySnapshot(
      latitude: 12.345678,
      longitude: -98.765432,
      accuracy: 5.0,
      timestamp: DateTime(2026, 10, 6, 15, 30, 45),
      address: '123 Main St, Springfield',
    );

    CaptureMetadata createMetadata({
      FilenameConfiguration? config,
      String? customName1,
      String? customName2,
      String? customName3,
      String? note,
      String? plusCode,
      String? timezone,
      int? sequenceNumber,
      OverlaySnapshot? snapshot,
    }) {
      return CaptureMetadata(
        snapshot: snapshot ?? baseSnapshot,
        template: OverlayTemplate.values.first,
        photoQuality: PhotoQuality.standard,
        saveOriginal: false,
        note: note,
        plusCode: plusCode,
        timezone: timezone,
        customName1: customName1,
        customName2: customName2,
        customName3: customName3,
        filenameConfiguration: config,
        sequenceNumber: sequenceNumber,
      );
    }

    test('Generates deterministic components in exact order', () {
      final config = FilenameConfiguration(
        components: [
          FilenameComponent.customName1,
          FilenameComponent.date,
          FilenameComponent.time,
          FilenameComponent.sequence,
        ],
        separator: '-',
      );

      final metadata = createMetadata(
        config: config,
        customName1: 'ProjectA',
        sequenceNumber: 42,
      );

      final result = FilenameGenerator.generateBaseName(metadata);
      expect(result, 'ProjectA-20261006-153045-000042');
    });

    test('Supports all required FilenameComponent values safely', () {
      final config = FilenameConfiguration(
        components: [
          FilenameComponent.date,
          FilenameComponent.time,
          FilenameComponent.sequence,
          FilenameComponent.customName1,
          FilenameComponent.customName2,
          FilenameComponent.customName3,
          FilenameComponent.address,
          FilenameComponent.latitude,
          FilenameComponent.longitude,
          FilenameComponent.plusCode,
          FilenameComponent.timeZone,
          FilenameComponent.note,
        ],
        separator: '_',
      );

      final metadata = createMetadata(
        config: config,
        customName1: 'C1',
        customName2: 'C2',
        customName3: 'C3',
        note: 'Test Note',
        plusCode: '85V3+4X',
        timezone: 'EST',
        sequenceNumber: 1,
      );

      final result = FilenameGenerator.generateBaseName(metadata);
      // Date_Time_Sequence_C1_C2_C3_Address_Lat_Lng_PlusCode_TZ_Note
      expect(
        result,
        '20261006_153045_000001_C1_C2_C3_123_Main_St,_Springfield_12.345678_-98.765432_85V3+4X_EST_Test_Note',
      );
    });

    test('Sanitizes dangerous path traversal inputs', () {
      final config = FilenameConfiguration(
        components: [FilenameComponent.customName1],
        separator: '_',
      );

      final tests = {
        '../escaped': 'escaped',
        '..\\escaped': 'escaped',
        '../../../etc/passwd': 'etcpasswd',
        'C:\\Windows\\System32': 'CWindowsSystem32',
        '/tmp/photo': 'tmpphoto',
        'foo..bar': 'foobar',
        'foo....bar': 'foobar',
      };

      for (var entry in tests.entries) {
        final metadata = createMetadata(config: config, customName1: entry.key);
        expect(
          FilenameGenerator.generateBaseName(metadata),
          entry.value,
          reason: 'Failed for ${entry.key}',
        );
      }
    });

    test('Sanitizes forbidden OS characters and reserved names', () {
      final config = FilenameConfiguration(
        components: [FilenameComponent.customName1],
      );

      // We mainly test characters since exact reserved names like CON.jpg aren't fully handled by simple replace,
      // but characters \ / : * ? " < > | are stripped.
      final invalidChars = r'\/:*?"<>|';
      for (var i = 0; i < invalidChars.length; i++) {
        final char = invalidChars[i];
        final metadata = createMetadata(
          config: config,
          customName1: 'test${char}name',
        );
        expect(FilenameGenerator.generateBaseName(metadata), 'testname');
      }

      // Control characters
      final metadata2 = createMetadata(
        config: config,
        customName1: 'test\x00\x09\nname',
      );
      expect(FilenameGenerator.generateBaseName(metadata2), 'test_name');
    });

    test('Handles spaces and empty values correctly', () {
      final config = FilenameConfiguration(
        components: [
          FilenameComponent.customName1,
          FilenameComponent.customName2,
          FilenameComponent.customName3,
        ],
        separator: '_',
      );

      final metadata = createMetadata(
        config: config,
        customName1: '  leading space',
        customName2: 'trailing space  ',
        customName3: '   ', // Only spaces
      );

      // Should be leading_space_trailing_space (customName3 is skipped or collapsed)
      final result = FilenameGenerator.generateBaseName(metadata);
      expect(result, 'leading_space_trailing_space');
    });

    test('Fallback when all components are empty or disabled', () {
      final config = FilenameConfiguration(components: [], separator: '_');
      final metadata = createMetadata(config: config);

      final result = FilenameGenerator.generateBaseName(metadata);
      expect(result, 'GPSMapCamera_20261006_153045');
    });

    test('Maximum length enforcement does not introduce path separators', () {
      final config = FilenameConfiguration(
        components: [FilenameComponent.customName1, FilenameComponent.sequence],
        separator: '_',
      );

      final longName = 'A' * 150;
      final metadata = createMetadata(
        config: config,
        customName1: longName,
        sequenceNumber: 123,
      );

      final result = FilenameGenerator.generateBaseName(metadata);
      expect(
        result.length,
        lessThanOrEqualTo(FilenameGenerator.maxFilenameLength),
      );
      // First pass truncates A to 25 chars.
      expect(result, '${'A' * 25}_000123');
      expect(result.contains('/'), isFalse);
      expect(result.contains('\\'), isFalse);
    });
  });
}
