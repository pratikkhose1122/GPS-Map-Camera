import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geomapcam/features/gallery/data/photo_repository.dart';
import 'package:geomapcam/features/gallery/domain/models/photo_item.dart';
import 'package:geomapcam/features/gallery/presentation/gallery_screen.dart';
import 'package:geomapcam/features/capture/data/photo_storage_service.dart';

class MockPhotoStorageService extends PhotoStorageService {
  final String mockPath;
  MockPhotoStorageService(this.mockPath);

  @override
  Future<String> getAppStorageDirectory() async {
    return mockPath;
  }
}

void main() {
  group('PhotoItem Tests', () {
    test('PhotoItem equality and file path', () {
      final now = DateTime.now();
      final item1 = PhotoItem(
        filePath: '/test/path.jpg',
        filename: 'path.jpg',
        createdAt: now,
        fileSize: 1024,
      );
      final item2 = PhotoItem(
        filePath: '/test/path.jpg',
        filename: 'path.jpg',
        createdAt: now,
        fileSize: 1024,
      );

      expect(item1, equals(item2));
      expect(item1.file.path, equals('/test/path.jpg'));
    });
  });

  group('PhotoRepository Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gallery_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('getPhotos returns empty list when directory is empty', () async {
      final mockStorage = MockPhotoStorageService(tempDir.path);
      final repo = PhotoRepository(storageService: mockStorage);

      final photos = await repo.getPhotos();
      expect(photos, isEmpty);
    });

    test('getPhotos filters non-jpg files and returns newest first', () async {
      final mockStorage = MockPhotoStorageService(tempDir.path);
      final repo = PhotoRepository(storageService: mockStorage);

      // Create dummy files
      final file1 = File('${tempDir.path}/photo1.jpg');
      await file1.writeAsString('dummy data 1');
      await file1.setLastModified(
        DateTime.now().subtract(const Duration(days: 1)),
      );

      final file2 = File('${tempDir.path}/photo2.jpg');
      await file2.writeAsString('dummy data 2 larger');
      await file2.setLastModified(DateTime.now());

      // Non-jpg file
      final file3 = File('${tempDir.path}/video.mp4');
      await file3.writeAsString('dummy video');

      // Temporary file
      final file4 = File('${tempDir.path}/photo3.jpg.tmp');
      await file4.writeAsString('tmp data');

      final photos = await repo.getPhotos();

      // Should only contain 2 jpg files
      expect(photos.length, equals(2));

      // Newest first sorting (file2 created after file1)
      expect(photos.first.filename, equals('photo2.jpg'));
      expect(photos.last.filename, equals('photo1.jpg'));
    });

    test('getPhotos handles missing directory safely', () async {
      final nonExistentDir = '${tempDir.path}/does_not_exist';
      final mockStorage = MockPhotoStorageService(nonExistentDir);
      final repo = PhotoRepository(storageService: mockStorage);

      final photos = await repo.getPhotos();
      expect(photos, isEmpty);
    });

    test('deletePhotos deletes successfully and safely', () async {
      final mockStorage = MockPhotoStorageService(tempDir.path);
      final repo = PhotoRepository(storageService: mockStorage);

      // Create a valid dummy file
      final file1 = File('${tempDir.path}/photo_to_delete.jpg');
      await file1.writeAsString('delete me');

      // Create a file OUTSIDE the allowed directory to simulate path traversal attempt
      final outsideDir = await Directory.systemTemp.createTemp(
        'gallery_outside_',
      );
      final file2 = File('${outsideDir.path}/outside.jpg');
      await file2.writeAsString('do not delete me');

      // Create a file that matches the prefix but is NOT inside the directory
      // e.g. /photos vs /photos_backup
      // We simulate this by appending '_backup' to the tempDir path
      final boundaryDir = Directory('${tempDir.path}_backup');
      await boundaryDir.create(recursive: true);
      final file3 = File('${boundaryDir.path}/boundary.jpg');
      await file3.writeAsString('do not delete boundary');

      final item1 = PhotoItem(
        filePath: file1.path,
        filename: 'photo_to_delete.jpg',
        createdAt: DateTime.now(),
        fileSize: 10,
      );

      final item2 = PhotoItem(
        filePath: file2.path, // Outside
        filename: 'outside.jpg',
        createdAt: DateTime.now(),
        fileSize: 10,
      );

      final item3 = PhotoItem(
        filePath: file3.path, // Boundary vulnerability
        filename: 'boundary.jpg',
        createdAt: DateTime.now(),
        fileSize: 10,
      );

      final result = await repo.deletePhotos([item1, item2, item3]);

      expect(result.successfullyDeleted, equals(1)); // only file1
      expect(result.failed, equals(2)); // file2 and file3 fail safety check
      expect(result.missing, equals(0));

      expect(await file1.exists(), isFalse);
      expect(await file2.exists(), isTrue); // safely protected
      expect(await file3.exists(), isTrue); // boundary safely protected

      await outsideDir.delete(recursive: true);
      await boundaryDir.delete(recursive: true);
    });
  });

  group('GalleryScreen UI Tests', () {
    testWidgets('Shows empty state when no photos', (
      WidgetTester tester,
    ) async {
      // Let's create an inline mock subclass
      final mockEmptyRepo = _MockEmptyPhotoRepository();

      await tester.pumpWidget(
        MaterialApp(home: GalleryScreen(repository: mockEmptyRepo)),
      );

      // Since the mock returns Future.value([]), it completes in the microtask queue
      await tester.pumpAndSettle();

      expect(find.text('No photos yet'), findsOneWidget);
      expect(
        find.text('Capture your first GPS photo to see it here.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    testWidgets('Selection mode works', (WidgetTester tester) async {
      final mockRepo = _MockPopulatedPhotoRepository();

      await tester.pumpWidget(
        MaterialApp(home: GalleryScreen(repository: mockRepo)),
      );

      await tester.pumpAndSettle();

      // Find images
      expect(find.byType(Image), findsNWidgets(2));

      // Enter selection mode via long press on first image
      await tester.longPress(find.byType(Image).first);
      await tester.pumpAndSettle();

      // Should show '1 selected'
      expect(find.text('1 selected'), findsOneWidget);

      // Tap second image
      await tester.tap(find.byType(Image).last, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Should show '2 selected'
      expect(find.text('2 selected'), findsOneWidget);

      // Tap delete
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Delete 2 photos?'), findsOneWidget);

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should still be in selection mode
      expect(find.text('2 selected'), findsOneWidget);

      // Exit selection mode
      await tester.tap(find.byTooltip('Cancel selection'));
      await tester.pumpAndSettle();

      expect(find.text('Gallery'), findsOneWidget);
    });
  });
}

class _MockEmptyPhotoRepository extends PhotoRepository {
  @override
  Future<List<PhotoItem>> getPhotos() async {
    return [];
  }
}

class _MockPopulatedPhotoRepository extends PhotoRepository {
  @override
  Future<List<PhotoItem>> getPhotos() async {
    return [
      PhotoItem(
        filePath: '/dummy/photo1.jpg',
        filename: 'photo1.jpg',
        createdAt: DateTime.now(),
        fileSize: 1024,
      ),
      PhotoItem(
        filePath: '/dummy/photo2.jpg',
        filename: 'photo2.jpg',
        createdAt: DateTime.now(),
        fileSize: 2048,
      ),
    ];
  }
}
