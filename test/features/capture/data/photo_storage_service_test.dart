import 'package:flutter_test/flutter_test.dart';
import 'package:geomapcam/features/capture/data/photo_storage_service.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';
import 'package:geomapcam/features/overlay/domain/overlay_snapshot.dart';
import 'package:geomapcam/features/overlay/domain/models/overlay_template.dart';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path/path.dart' as p;

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    return [tempPath];
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempPath;
  }
}

void main() {
  group('PhotoStorageService Phase 16 Audit', () {
    late Directory tempDir;
    late PhotoStorageService storageService;
    late CaptureMetadata baseMetadata;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('storage_test');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
      storageService = PhotoStorageService();

      baseMetadata = CaptureMetadata(
        snapshot: OverlaySnapshot(
          latitude: 1.0,
          longitude: 2.0,
          accuracy: 3.0,
          timestamp: DateTime(2026, 1, 1, 12, 0, 0),
        ),
        template: OverlayTemplate.values.first,
        photoQuality: PhotoQuality.standard,
        saveOriginal: false,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Generates expected filename and saves successfully', () async {
      final path = await storageService.saveImage([1, 2, 3], baseMetadata);
      expect(path, endsWith('.jpg'));
      final file = File(path);
      expect(await file.exists(), isTrue);

      // Verify path safety boundary
      expect(p.isWithin(tempDir.path, path), isTrue);
    });

    test('Collision handling appends zero-padded suffixes', () async {
      // First save
      final path1 = await storageService.saveImage([1], baseMetadata);

      // Second save with exact same metadata
      final path2 = await storageService.saveImage([2], baseMetadata);
      expect(path2, isNot(path1));
      expect(path2, endsWith('_001.jpg'));

      // Third save
      final path3 = await storageService.saveImage([3], baseMetadata);
      expect(path3, isNot(path1));
      expect(path3, isNot(path2));
      expect(path3, endsWith('_002.jpg'));

      // Verify files actually exist
      expect(await File(path1).exists(), isTrue);
      expect(await File(path2).exists(), isTrue);
      expect(await File(path3).exists(), isTrue);
    });

    test('Saves original photo with correct suffix', () async {
      final path = await storageService.saveOriginalImage([
        1,
        2,
        3,
      ], baseMetadata);
      expect(path, endsWith('-original.jpg'));

      // Ensure it uses the Originals directory
      expect(path.contains('Originals'), isTrue);
    });

    test(
      'Original saves do not overwrite processed photos or other originals',
      () async {
        final processedPath = await storageService.saveImage([1], baseMetadata);
        final originalPath = await storageService.saveOriginalImage([
          2,
        ], baseMetadata);

        expect(processedPath, isNot(originalPath));
        expect(await File(processedPath).exists(), isTrue);
        expect(await File(originalPath).exists(), isTrue);

        // Another original with same metadata (simulating collision)
        final originalPath2 = await storageService.saveOriginalImage([
          3,
        ], baseMetadata);
        expect(originalPath2, isNot(originalPath));
        expect(originalPath2, endsWith('_001-original.jpg'));
      },
    );
  });
}
