import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geomapcam/core/utils/format_utils.dart';
import 'package:geomapcam/features/overlay/presentation/overlay_controller.dart';
import 'package:geomapcam/features/overlay/domain/models/overlay_template.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LiveMetadataOverlay extends StatelessWidget {
  final OverlayController controller;
  final Widget? mapWidget;

  const LiveMetadataOverlay({
    super.key,
    required this.controller,
    this.mapWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final metadata = controller.metadata;

        return Container(
          padding:
              (mapWidget != null || metadata.template.id == 'scan_location')
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: _buildDecoration(metadata.template),
          child: _buildLayout(metadata),
        );
      },
    );
  }

  BoxDecoration? _buildDecoration(OverlayTemplate template) {
    switch (template.background) {
      case BackgroundTreatment.gradient:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.0),
            ],
          ),
        );
      case BackgroundTreatment.solidBox:
        return BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8.0),
        );
      case BackgroundTreatment.none:
        return null;
    }
  }

  Widget _buildLayout(CaptureMetadata metadata) {
    final template = metadata.template;
    final snapshot = metadata.snapshot;

    List<Widget> children = [];

    // The logo will be handled outside the textColumn now

    // 1. Core Location Data
    if (template.showAddress) {
      children.add(_buildAddress(snapshot.address, template));
      children.add(const SizedBox(height: 8));
    }

    // 2. Coordinates & Altitude/Accuracy
    if (template.showCoordinates || template.showAltitudeAndAccuracy) {
      if (template.grouping == MetadataGrouping.compact) {
        children.add(
          _buildCompactLocationRow(
            snapshot.latitude,
            snapshot.longitude,
            template,
          ),
        );
      } else {
        children.add(
          _buildLocationRow(
            snapshot.latitude,
            snapshot.longitude,
            snapshot.accuracy,
            snapshot.altitude,
            template,
          ),
        );
      }
    }

    // 3. Plus Code
    if (template.showPlusCode && metadata.plusCode != null) {
      children.add(const SizedBox(height: 4));
      children.add(_buildTextRow('Plus Code', metadata.plusCode!, template));
    }

    // 4. Time & Compass Row
    if (template.showDateTime || template.showHeading || template.showCompass) {
      children.add(const SizedBox(height: 4));
      if (template.showCompass) {
        children.add(
          _buildProminentCompassRow(
            snapshot.headingDegrees,
            snapshot.cardinalDirection,
            template,
          ),
        );
        if (template.showDateTime) {
          children.add(const SizedBox(height: 4));
          children.add(
            _buildTimeAndCompassRow(
              snapshot.timestamp,
              metadata.timezone,
              null,
              null,
              template,
            ),
          );
        }
      } else {
        children.add(
          _buildTimeAndCompassRow(
            template.showDateTime ? snapshot.timestamp : null,
            template.showTimezone ? metadata.timezone : null,
            template.showHeading ? snapshot.headingDegrees : null,
            template.showHeading ? snapshot.cardinalDirection : null,
            template,
          ),
        );
      }
    }

    // 5. Additional Fields (Note, Custom Fields)
    final bool hasNote = template.showNote && metadata.note != null;
    final bool hasCustom =
        template.showCustomFields && metadata.customFields.isNotEmpty;
    if (hasNote || hasCustom) {
      children.add(const SizedBox(height: 8));
      children.add(
        Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
      );
      children.add(const SizedBox(height: 8));

      if (hasNote) {
        children.add(_buildTextRow('Note', metadata.note!, template));
      }

      if (template.showCustomFields) {
        for (final field in metadata.customFields) {
          if (field.enabled) {
            children.add(const SizedBox(height: 4));
            children.add(_buildTextRow(field.label, field.value, template));
          }
        }
      }
    }

    final textColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );

    Widget mainLayout;
    if (mapWidget != null && template.id != 'scan_location') {
      mainLayout = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft:
                      (metadata.showAppLogo || metadata.showCameraIndicator)
                      ? Radius.zero
                      : const Radius.circular(8.0),
                  bottomLeft: const Radius.circular(8.0),
                ),
                child: mapWidget,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: textColumn,
              ),
            ),
          ],
        ),
      );
    } else if (template.id == 'scan_location') {
      final String qrData =
          snapshot.latitude != null && snapshot.longitude != null
          ? '${snapshot.latitude}, ${snapshot.longitude}\n${snapshot.address ?? ''}'
          : 'Location Unavailable';

      mainLayout = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mapWidget != null)
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft:
                        (metadata.showAppLogo || metadata.showCameraIndicator)
                        ? Radius.zero
                        : const Radius.circular(8.0),
                    bottomLeft: const Radius.circular(8.0),
                  ),
                  child: mapWidget,
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: textColumn,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2), // Very small white border
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight:
                      (metadata.showAppLogo || metadata.showCameraIndicator)
                      ? Radius.zero
                      : const Radius.circular(8.0),
                  bottomRight: const Radius.circular(8.0),
                  topLeft: mapWidget == null
                      ? ((metadata.showAppLogo || metadata.showCameraIndicator)
                            ? Radius.zero
                            : const Radius.circular(8.0))
                      : Radius.zero,
                  bottomLeft: mapWidget == null
                      ? const Radius.circular(8.0)
                      : Radius.zero,
                ),
              ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  padding: EdgeInsets.zero,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      mainLayout = textColumn;
    }

    if (metadata.showAppLogo || metadata.showCameraIndicator) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 12.0,
              top: 12.0,
              right: 12.0,
              bottom: 8.0,
            ),
            child: Row(
              children: [
                if (metadata.showAppLogo) ...[
                  const Icon(Icons.camera, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'GPS Map Camera',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (metadata.showAppLogo && metadata.showCameraIndicator)
                  const Spacer(),
                if (metadata.showCameraIndicator)
                  const Icon(Icons.camera_alt, color: Colors.white, size: 14),
              ],
            ),
          ),
          mainLayout,
        ],
      );
    }

    return mainLayout;
  }

  Widget _buildAddress(String? address, OverlayTemplate template) {
    if (address == null || address.isEmpty) {
      return Text(
        'Address unavailable',
        style: TextStyle(
          color: Colors.white70,
          fontSize: template.typography.addressSize / 2.5,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    return Text(
      address,
      style: TextStyle(
        color: Colors.white,
        fontSize: template.typography.addressSize / 2.5,
        fontWeight: FontWeight.w600,
        shadows: const [
          Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTextRow(String label, String value, OverlayTemplate template) {
    return DefaultTextStyle(
      style: TextStyle(
        color: Colors.white70,
        fontSize: template.typography.coordsSize / 2.5,
        fontFamily: 'monospace',
        shadows: const [Shadow(color: Colors.black87, blurRadius: 1)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    double? lat,
    double? lon,
    double? accuracy,
    double? altitude,
    OverlayTemplate template,
  ) {
    final hasLocation = lat != null && lon != null;
    final latStr = hasLocation ? 'Lat ${lat.toStringAsFixed(6)}°' : 'Lat: —';
    final lonStr = hasLocation ? 'Long ${lon.toStringAsFixed(6)}°' : 'Long: —';

    final accStr = 'Acc: ${FormatUtils.formatAccuracy(accuracy)}';
    final altStr = 'Alt: ${FormatUtils.formatAltitude(altitude)}';

    return DefaultTextStyle(
      style: TextStyle(
        color: Colors.white70,
        fontSize: template.typography.coordsSize / 2.5,
        fontFamily: 'monospace',
        shadows: const [Shadow(color: Colors.black87, blurRadius: 1)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text('$latStr $lonStr')),
          if (template.showAltitudeAndAccuracy) Text('$accStr  $altStr'),
        ],
      ),
    );
  }

  Widget _buildCompactLocationRow(
    double? lat,
    double? lon,
    OverlayTemplate template,
  ) {
    final hasLocation = lat != null && lon != null;
    final latStr = hasLocation ? 'Lat ${lat.toStringAsFixed(6)}°' : 'Lat: —';
    final lonStr = hasLocation ? 'Long ${lon.toStringAsFixed(6)}°' : 'Long: —';

    return Text(
      '$latStr $lonStr',
      style: TextStyle(
        color: Colors.white70,
        fontSize: template.typography.coordsSize / 2.5,
        fontFamily: 'monospace',
        shadows: const [Shadow(color: Colors.black87, blurRadius: 1)],
      ),
    );
  }

  Widget _buildTimeAndCompassRow(
    DateTime? timestamp,
    String? timezone,
    double? heading,
    String? cardinal,
    OverlayTemplate template,
  ) {
    String timeStr = '';
    if (timestamp != null) {
      timeStr = DateFormat('EEEE, MM/dd/yyyy hh:mm a').format(timestamp);
      if (timezone != null) {
        timeStr += ' $timezone';
      }
    }

    final headingStr = (heading != null && cardinal != null)
        ? FormatUtils.formatHeading(heading, cardinal)
        : (template.showHeading ? 'Heading unavailable' : '');

    return DefaultTextStyle(
      style: TextStyle(
        color: Colors.white,
        fontSize: template.typography.timeSize / 2.5,
        fontWeight: FontWeight.w500,
        shadows: const [Shadow(color: Colors.black87, blurRadius: 1)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (timeStr.isNotEmpty) Expanded(child: Text(timeStr)),
          if (headingStr.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (heading != null)
                  Icon(
                    Icons.explore,
                    color: Colors.white,
                    size: template.typography.timeSize / 2.0,
                  ),
                if (heading != null) const SizedBox(width: 4),
                Text(headingStr),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProminentCompassRow(
    double? heading,
    String? cardinal,
    OverlayTemplate template,
  ) {
    if (heading == null || cardinal == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.explore,
          color: Colors.redAccent,
          size: template.typography.timeSize,
        ),
        const SizedBox(width: 8),
        Text(
          '$cardinal ${heading.toStringAsFixed(0)}°',
          style: TextStyle(
            color: Colors.white,
            fontSize: template.typography.timeSize / 1.5,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
          ),
        ),
      ],
    );
  }
}
