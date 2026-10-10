class DeleteResult {
  final int successfullyDeleted;
  final int failed;
  final int missing;

  const DeleteResult({
    required this.successfullyDeleted,
    required this.failed,
    required this.missing,
  });

  bool get isAllSuccess => failed == 0 && missing == 0;
}
