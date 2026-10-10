import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:geomapcam/features/capture/data/photo_storage_service.dart';
import 'package:geomapcam/features/gallery/domain/models/photo_item.dart';
import 'package:geomapcam/features/gallery/domain/models/delete_result.dart';

class PhotoRepository {
  final PhotoStorageService _storageService;

  PhotoRepository({PhotoStorageService? storageService})
    : _storageService = storageService ?? PhotoStorageService();

  Future<List<PhotoItem>> getPhotos() async {
    try {
      final dirPath = await _storageService.getAppStorageDirectory();
      final dir = Directory(dirPath);

      if (!await dir.exists()) {
        return [];
      }

      final List<PhotoItem> photos = [];
      final entities = await dir.list().toList();

      for (final entity in entities) {
        if (entity is File && entity.path.toLowerCase().endsWith('.jpg')) {
          try {
            final stat = await entity.stat();
            final filename = entity.path.split(Platform.pathSeparator).last;

            photos.add(
              PhotoItem(
                filePath: entity.path,
                filename: filename,
                createdAt: stat.modified,
                fileSize: stat.size,
              ),
            );
          } catch (e) {
            // Skip missing/corrupt files silently
          }
        }
      }

      // Sort newest first
      photos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return photos;
    } catch (e) {
      return [];
    }
  }

  Future<DeleteResult> deletePhotos(List<PhotoItem> photos) async {
    int success = 0;
    int failed = 0;
    int missing = 0;

    try {
      final dirPath = await _storageService.getAppStorageDirectory();
      final allowedDir = Directory(dirPath);
      final allowedPath = allowedDir.absolute.path;

      for (final photo in photos) {
        try {
          final file = photo.file.absolute;

          // Verify path safety (must be strictly inside allowedDir)
          // path.isWithin handles normalization, slashes, and case-sensitivity issues correctly.
          if (!path.isWithin(allowedPath, file.path)) {
            failed++;
            continue;
          }

          if (await file.exists()) {
            await file.delete();
            success++;
          } else {
            missing++;
          }
        } catch (e) {
          failed++;
        }
      }
    } catch (e) {
      return DeleteResult(
        successfullyDeleted: success,
        failed: photos.length - success - missing,
        missing: missing,
      );
    }

    return DeleteResult(
      successfullyDeleted: success,
      failed: failed,
      missing: missing,
    );
  }
}
