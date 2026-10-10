import 'package:geomapcam/features/storage/utils/filename_generator.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PhotoStorageService {
  Future<String> getAppStorageDirectory() async {
    Directory? dir;
    if (Platform.isAndroid) {
      final dirs = await getExternalStorageDirectories(
        type: StorageDirectory.pictures,
      );
      if (dirs != null && dirs.isNotEmpty) {
        dir = dirs.first;
      }
    }

    dir ??= await getApplicationDocumentsDirectory();

    final customDir = Directory('${dir.path}/GPSMapCamera/Photos');
    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }

    return customDir.path;
  }

  Future<String> generateUniqueFileName(
    CaptureMetadata metadata, {
    String extension = '.jpg',
  }) async {
    final baseDir = await getAppStorageDirectory();
    final baseName = FilenameGenerator.generateBaseName(metadata);

    File file = File('$baseDir/$baseName$extension');
    int suffix = 1;

    while (await file.exists()) {
      // Use zero-padded suffix for collisions (e.g. _001)
      final suffixStr = suffix.toString().padLeft(3, '0');
      file = File('$baseDir/${baseName}_$suffixStr$extension');
      suffix++;
    }

    return file.path;
  }

  /// Atomically saves the image data by writing to a temp file and renaming it.
  Future<String> saveImage(List<int> bytes, CaptureMetadata metadata) async {
    final finalPath = await generateUniqueFileName(metadata);
    final tempPath = '$finalPath.tmp';

    final tempFile = File(tempPath);
    try {
      await tempFile.writeAsBytes(bytes, flush: true);
      final finalFile = await tempFile.rename(finalPath);
      return finalFile.path;
    } catch (e) {
      // Clean up temp file on failure
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  Future<String> saveVideo(File videoFile, CaptureMetadata metadata) async {
    final finalPath = await generateUniqueFileName(metadata, extension: '.mp4');
    final tempPath = '$finalPath.tmp';

    final tempFile = File(tempPath);
    try {
      await videoFile.copy(tempFile.path);
      final finalFile = await tempFile.rename(finalPath);
      return finalFile.path;
    } catch (e) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  Future<String> saveOriginalImage(
    List<int> bytes,
    CaptureMetadata metadata,
  ) async {
    final baseDir = await getAppStorageDirectory();

    // Store originals in an Originals subdirectory
    final customDir = Directory('$baseDir/Originals');
    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }

    // Use the same base name, but with -original suffix
    final baseName = FilenameGenerator.generateBaseName(metadata);
    final extension = '.jpg';

    File file = File('${customDir.path}/$baseName-original$extension');
    int suffix = 1;

    while (await file.exists()) {
      final suffixStr = suffix.toString().padLeft(3, '0');
      file = File(
        '${customDir.path}/${baseName}_$suffixStr-original$extension',
      );
      suffix++;
    }

    final finalPath = file.path;
    final tempPath = '$finalPath.tmp';

    final tempFile = File(tempPath);
    try {
      await tempFile.writeAsBytes(bytes, flush: true);
      final finalFile = await tempFile.rename(finalPath);
      return finalFile.path;
    } catch (e) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }
}
