import 'package:geomapcam/features/storage/domain/models/filename_configuration.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';
import 'package:intl/intl.dart';

class FilenameGenerator {
  static const int maxFilenameLength = 100;

  /// Sanitizes text to be safe for Windows and Android filesystems.
  static String sanitize(String input) {
    // Replace whitespace with underscores
    String sanitized = input.replaceAll(RegExp(r'\s+'), '_');

    // Remove invalid characters: \ / : * ? " < > | and control characters
    sanitized = sanitized.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '');

    // Remove .. to prevent path traversal
    while (sanitized.contains('..')) {
      sanitized = sanitized.replaceAll('..', '');
    }

    // Strip leading/trailing dots and underscores
    sanitized = sanitized.replaceAll(RegExp(r'^[\._]+|[\._]+$'), '');

    return sanitized;
  }

  /// Generates the base filename (without extension) from frozen metadata.
  static String generateBaseName(CaptureMetadata metadata) {
    final config =
        metadata.filenameConfiguration ?? FilenameConfiguration.defaultConfig;
    final components = <String>[];

    for (final comp in config.components) {
      String? value;
      switch (comp) {
        case FilenameComponent.date:
          value = DateFormat('yyyyMMdd').format(metadata.snapshot.timestamp);
          break;
        case FilenameComponent.time:
          value = DateFormat('HHmmss').format(metadata.snapshot.timestamp);
          break;
        case FilenameComponent.sequence:
          if (metadata.sequenceNumber != null) {
            value = metadata.sequenceNumber!.toString().padLeft(6, '0');
          }
          break;
        case FilenameComponent.customName1:
          value = metadata.customName1;
          break;
        case FilenameComponent.customName2:
          value = metadata.customName2;
          break;
        case FilenameComponent.customName3:
          value = metadata.customName3;
          break;
        case FilenameComponent.address:
          value = metadata.snapshot.address;
          break;
        case FilenameComponent.latitude:
          if (metadata.snapshot.latitude != null) {
            value = metadata.snapshot.latitude!.toStringAsFixed(6);
          }
          break;
        case FilenameComponent.longitude:
          if (metadata.snapshot.longitude != null) {
            value = metadata.snapshot.longitude!.toStringAsFixed(6);
          }
          break;
        case FilenameComponent.plusCode:
          value = metadata.plusCode;
          break;
        case FilenameComponent.timeZone:
          value = metadata.timezone;
          break;
        case FilenameComponent.note:
          value = metadata.note;
          break;
      }

      if (value != null && value.trim().isNotEmpty) {
        final sanitizedValue = sanitize(value);
        if (sanitizedValue.isNotEmpty) {
          components.add(sanitizedValue);
        }
      }
    }

    if (components.isEmpty) {
      // Safe fallback
      final timeString = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(metadata.snapshot.timestamp);
      return 'GPSMapCamera_$timeString';
    }

    String baseName = components.join(config.separator);

    // Truncation policy: if length exceeds maxFilenameLength, try to truncate human text (custom names, address, note)
    // For simplicity in this implementation, we will just substring the end if it's too long,
    // but a better policy is to trim from the end of the joined string, ensuring we don't truncate the sequence.
    // However, since components are ordered by user, substringing the end might truncate the sequence if it's at the end.
    // Instead, we will aggressively truncate long components first if needed.

    // Pass 1: truncate individual components that are very long (like address or note)
    if (baseName.length > maxFilenameLength) {
      final truncatedComponents = <String>[];
      for (var compStr in components) {
        if (compStr.length > 25) {
          truncatedComponents.add(compStr.substring(0, 25));
        } else {
          truncatedComponents.add(compStr);
        }
      }
      baseName = truncatedComponents.join(config.separator);
    }

    if (baseName.length > maxFilenameLength) {
      baseName = baseName.substring(0, maxFilenameLength);
    }

    // Strip trailing separators just in case truncation left them
    baseName = baseName.replaceAll(RegExp('${config.separator}\$'), '');

    return baseName;
  }
}
