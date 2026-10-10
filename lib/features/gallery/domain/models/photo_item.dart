import 'dart:io';

class PhotoItem {
  final String filePath;
  final String filename;
  final DateTime createdAt;
  final int fileSize;

  const PhotoItem({
    required this.filePath,
    required this.filename,
    required this.createdAt,
    required this.fileSize,
  });

  File get file => File(filePath);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhotoItem &&
        other.filePath == filePath &&
        other.filename == filename &&
        other.createdAt == createdAt &&
        other.fileSize == fileSize;
  }

  @override
  int get hashCode {
    return filePath.hashCode ^
        filename.hashCode ^
        createdAt.hashCode ^
        fileSize.hashCode;
  }
}
