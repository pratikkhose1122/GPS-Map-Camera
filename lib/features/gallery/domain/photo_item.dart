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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoItem &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath;

  @override
  int get hashCode => filePath.hashCode;
}
