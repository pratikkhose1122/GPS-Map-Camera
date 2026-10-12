import 'package:geomapcam/features/overlay/domain/overlay_snapshot.dart';

enum CaptureStatus {
  idle,
  capturing,
  recording,
  processing,
  saving,
  success,
  error,
}

class CaptureState {
  final CaptureStatus status;
  final String? filePath;
  final String? errorMessage;
  final String? warningMessage;
  final String? processingMessage;
  final OverlaySnapshot? snapshot;
  final String? templateName;

  const CaptureState({
    this.status = CaptureStatus.idle,
    this.filePath,
    this.errorMessage,
    this.warningMessage,
    this.processingMessage,
    this.snapshot,
    this.templateName,
  });

  CaptureState copyWith({
    CaptureStatus? status,
    String? filePath,
    String? errorMessage,
    String? warningMessage,
    String? processingMessage,
    OverlaySnapshot? snapshot,
    String? templateName,
    bool clearError = false,
    bool clearWarning = false,
    bool clearFilePath = false,
  }) {
    return CaptureState(
      status: status ?? this.status,
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      warningMessage:
          clearWarning ? null : (warningMessage ?? this.warningMessage),
      processingMessage: processingMessage ?? this.processingMessage,
      snapshot: snapshot ?? this.snapshot,
      templateName: templateName ?? this.templateName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaptureState &&
          other.status == status &&
          other.filePath == filePath &&
          other.errorMessage == errorMessage &&
          other.warningMessage == warningMessage &&
          other.processingMessage == processingMessage &&
          other.snapshot == snapshot &&
          other.templateName == templateName;

  @override
  int get hashCode =>
      status.hashCode ^
      filePath.hashCode ^
      errorMessage.hashCode ^
      warningMessage.hashCode ^
      processingMessage.hashCode ^
      snapshot.hashCode ^
      templateName.hashCode;
}
