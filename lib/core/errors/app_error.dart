/// Base class for application-specific errors.
///
/// Each feature can extend this for typed error handling
/// without exposing raw platform exceptions to the UI.
class AppError implements Exception {
  const AppError(this.message, {this.cause});

  /// Human-readable error message suitable for SnackBar/Dialog.
  final String message;

  /// Original exception, if any (for logging, not for display).
  final Object? cause;

  @override
  String toString() => 'AppError: $message';
}

/// Camera-specific errors.
class CameraError extends AppError {
  const CameraError(super.message, {super.cause});
}

/// Location/GPS-specific errors.
class LocationError extends AppError {
  const LocationError(super.message, {super.cause});
}

/// Permission-specific errors.
class PermissionError extends AppError {
  const PermissionError(super.message, {super.cause});
}

/// Image composition errors.
class CompositionError extends AppError {
  const CompositionError(super.message, {super.cause});
}

/// File storage errors.
class StorageError extends AppError {
  const StorageError(super.message, {super.cause});
}
