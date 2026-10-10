import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geomapcam/core/utils/format_utils.dart';
import 'package:geomapcam/features/capture/domain/capture_metadata.dart';
import 'package:geomapcam/features/overlay/domain/models/overlay_template.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OverlayRenderer {
  /// Renders the overlay into a PNG byte array of [width] x [height].
  /// The overlay will be drawn at the bottom, matching metadata configuration.
  static Future<List<int>> renderOverlayPng(
    CaptureMetadata metadata,
    int width,
    int height, [
    Uint8List? mapBytes,
  ]) async {
    final template = metadata.template;
    final snapshot = metadata.snapshot;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    // Handle Stamp Orientation
    int layoutWidth = width;
    int layoutHeight = height;

    if (metadata.stampOrientation == StampOrientation.portrait &&
        width > height) {
      // Image is landscape, stamp should be portrait. Rotate canvas -90 degrees.
      layoutWidth = height;
      layoutHeight = width;
      canvas.translate(0, height.toDouble());
      canvas.rotate(-math.pi / 2);
    } else if (metadata.stampOrientation == StampOrientation.landscape &&
        height > width) {
      // Image is portrait, stamp should be landscape. Rotate canvas 90 degrees.
      layoutWidth = height;
      layoutHeight = width;
      canvas.translate(width.toDouble(), 0);
      canvas.rotate(math.pi / 2);
    }

    ui.Image? appLogoUiImage;
    if (metadata.showAppLogo) {
      try {
        final ByteData data = await rootBundle.load(
          'assets/images/app_logo.png',
        );
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        appLogoUiImage = frame.image;
      } catch (e) {
        debugPrint('Failed to load app logo: $e');
      }
    }

    final double scale = layoutWidth / 1080.0;

    // Prepare styles
    final double paddingX = 40.0 * scale;
    final double paddingY = 40.0 * scale;

    final addressStyle = TextStyle(
      color: Colors.white,
      fontSize: template.typography.addressSize * scale,
      fontWeight: FontWeight.w600,
      shadows: const [
        Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2)),
      ],
    );

    final coordsStyle = TextStyle(
      color: Colors.white70,
      fontSize: template.typography.coordsSize * scale,
      fontFamily: 'monospace',
      shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
    );

    final timeStyle = TextStyle(
      color: Colors.white,
      fontSize: template.typography.timeSize * scale,
      fontWeight: FontWeight.w500,
      shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
    );

    // Prepare Text Layouts (bottom to top)
    List<_DrawnText> textsToDraw = [];
    double currentY = layoutHeight - paddingY;

    Offset? logoImageOffset;
    double logoImageSize = 0;

    final bool mapOnLeft =
        mapBytes != null &&
        template.showMap &&
        template.mapPosition != MapPosition.hidden;

    final double mapW = mapOnLeft ? 260 * scale : 320 * scale;
    final double mapH = mapOnLeft ? 260 * scale : 240 * scale;

    final double textStartX = mapOnLeft
        ? paddingX + mapW + (20 * scale)
        : paddingX;
    final double availableTextWidth = layoutWidth - textStartX - paddingX;

    // Helper to add text row
    void addTextRow(String left, [String right = '']) {
      final pLeft = TextPainter(
        text: TextSpan(text: left, style: coordsStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: availableTextWidth);
      final pRight = TextPainter(
        text: TextSpan(text: right, style: coordsStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      currentY -= pLeft.height;
      textsToDraw.add(_DrawnText(pLeft, Offset(textStartX, currentY)));
      if (right.isNotEmpty) {
        textsToDraw.add(
          _DrawnText(
            pRight,
            Offset(layoutWidth - paddingX - pRight.width, currentY),
          ),
        );
      }
      currentY -= (4 * scale); // spacing
    }

    // 1. Custom Fields (Bottom)
    if (template.showCustomFields) {
      for (final field in metadata.customFields.reversed) {
        if (field.enabled) addTextRow('${field.label}:', field.value);
      }
    }

    // 2. Note
    if (template.showNote &&
        metadata.note != null &&
        metadata.note!.isNotEmpty) {
      addTextRow('Note:', metadata.note!);
    }

    // 3. Time & Compass
    if (template.showDateTime || template.showHeading || template.showCompass) {
      if (template.showCompass) {
        // Bottom: Time
        if (template.showDateTime) {
          String timeStr = DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).format(snapshot.timestamp);
          if (template.showTimezone && metadata.timezone != null) {
            timeStr += ' (${metadata.timezone})';
          }
          final pTime = TextPainter(
            text: TextSpan(text: timeStr, style: timeStyle),
            textDirection: ui.TextDirection.ltr,
          )..layout();
          currentY -= pTime.height;
          textsToDraw.add(_DrawnText(pTime, Offset(textStartX, currentY)));
          currentY -= (4 * scale);
        }
        // Top: Prominent Compass
        if (snapshot.headingDegrees != null &&
            snapshot.cardinalDirection != null) {
          final compStyle = TextStyle(
            color: Colors.white,
            fontSize: template.typography.timeSize * scale * 1.2,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
          );
          final pCompass = TextPainter(
            text: TextSpan(
              text:
                  '${snapshot.cardinalDirection} ${snapshot.headingDegrees!.toStringAsFixed(0)}°',
              style: compStyle,
            ),
            textDirection: ui.TextDirection.ltr,
          )..layout();
          currentY -= pCompass.height;
          textsToDraw.add(_DrawnText(pCompass, Offset(textStartX, currentY)));
          currentY -= (4 * scale);
        }
      } else {
        // Combined Time & Heading
        String timeStr = '';
        if (template.showDateTime) {
          timeStr = DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).format(snapshot.timestamp);
          if (template.showTimezone && metadata.timezone != null) {
            timeStr += ' (${metadata.timezone})';
          }
        }
        String headingStr = '';
        if (template.showHeading) {
          headingStr =
              (snapshot.headingDegrees != null &&
                  snapshot.cardinalDirection != null)
              ? FormatUtils.formatHeading(
                  snapshot.headingDegrees,
                  snapshot.cardinalDirection,
                )
              : 'Heading unavailable';
        }

        final pTime = TextPainter(
          text: TextSpan(text: timeStr, style: timeStyle),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        final pHeading = TextPainter(
          text: TextSpan(text: headingStr, style: timeStyle),
          textDirection: ui.TextDirection.ltr,
        )..layout();

        double rowHeight = math.max(pTime.height, pHeading.height);
        if (rowHeight == 0) rowHeight = timeStyle.fontSize!; // fallback

        currentY -= rowHeight;
        if (timeStr.isNotEmpty) {
          textsToDraw.add(_DrawnText(pTime, Offset(textStartX, currentY)));
        }
        if (headingStr.isNotEmpty) {
          textsToDraw.add(
            _DrawnText(
              pHeading,
              Offset(layoutWidth - paddingX - pHeading.width, currentY),
            ),
          );
        }
        currentY -= (4 * scale);
      }
    }

    // 4. Plus Code
    if (template.showPlusCode && metadata.plusCode != null) {
      addTextRow('Plus Code:', metadata.plusCode!);
    }

    // 5. Location
    if (template.showCoordinates || template.showAltitudeAndAccuracy) {
      final hasLocation =
          snapshot.latitude != null && snapshot.longitude != null;
      final latStr = hasLocation
          ? FormatUtils.formatLatitude(snapshot.latitude!)
          : 'Lat: —';
      final lonStr = hasLocation
          ? FormatUtils.formatLongitude(snapshot.longitude!)
          : 'Lon: —';
      final accStr = 'Acc: ${FormatUtils.formatAccuracy(snapshot.accuracy)}';
      final altStr = 'Alt: ${FormatUtils.formatAltitude(snapshot.altitude)}';

      final leftLoc = template.showCoordinates ? '$latStr  $lonStr' : '';
      final rightLoc =
          template.showAltitudeAndAccuracy &&
              template.grouping != MetadataGrouping.compact
          ? '$accStr  $altStr'
          : '';
      addTextRow(leftLoc, rightLoc);
      currentY -= (4 * scale); // extra spacing before address
    }

    // 6. Address
    if (template.showAddress) {
      String addressText = snapshot.address ?? 'Address unavailable';
      final pAddress = TextPainter(
        text: TextSpan(text: addressText, style: addressStyle),
        textDirection: ui.TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: availableTextWidth);
      currentY -= pAddress.height;
      textsToDraw.add(_DrawnText(pAddress, Offset(textStartX, currentY)));
      currentY -= (4 * scale); // spacing
    }

    // 7. App Logo & Camera Indicator
    if (metadata.showAppLogo || metadata.showCameraIndicator) {
      String logoStr = '';
      if (metadata.showAppLogo) logoStr = 'GPS Map Camera';

      String indStr = '';
      if (metadata.showCameraIndicator) indStr = '📷';

      if (logoStr.isNotEmpty || indStr.isNotEmpty) {
        final pLogo = TextPainter(
          text: TextSpan(
            text: logoStr,
            style: TextStyle(
              color: Colors.white,
              fontSize: template.typography.coordsSize * scale * 0.9,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();

        final pInd = TextPainter(
          text: TextSpan(
            text: indStr,
            style: TextStyle(
              color: Colors.white,
              fontSize: template.typography.coordsSize * scale * 0.9,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();

        double rowHeight = math.max(pLogo.height, pInd.height);
        if (rowHeight == 0) rowHeight = 12 * scale;

        currentY -= rowHeight;
        if (logoStr.isNotEmpty) {
          double spaceForLogo = 0;
          if (appLogoUiImage != null) {
            logoImageSize = pLogo.height * 1.5;
            logoImageOffset = Offset(
              textStartX,
              currentY - (logoImageSize - pLogo.height) / 2,
            );
            spaceForLogo = logoImageSize + (8 * scale);
          }
          textsToDraw.add(
            _DrawnText(pLogo, Offset(textStartX + spaceForLogo, currentY)),
          );
        }
        if (indStr.isNotEmpty) {
          textsToDraw.add(
            _DrawnText(
              pInd,
              Offset(layoutWidth - paddingX - pInd.width, currentY),
            ),
          );
        }
        currentY -= (8 * scale);
      }
    }

    // Now currentY is the top of the text block.
    final double contentTop = currentY - paddingY;
    double bgTop = math.max(0.0, contentTop);

    if (mapOnLeft) {
      final double mapNeededBgTop = layoutHeight - paddingY - mapH - paddingY;
      if (mapNeededBgTop < bgTop) {
        bgTop = mapNeededBgTop;
      }
    }

    final double bgHeight = layoutHeight - bgTop;

    // Draw Background
    if (template.background == BackgroundTreatment.gradient) {
      final Rect bgRect = Rect.fromLTWH(
        0,
        bgTop,
        layoutWidth.toDouble(),
        bgHeight,
      );
      final Paint bgPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, bgTop),
          Offset(0, layoutHeight.toDouble()),
          [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.7),
          ],
        );
      canvas.drawRect(bgRect, bgPaint);
    } else if (template.background == BackgroundTreatment.solidBox) {
      final Rect bgRect = Rect.fromLTWH(
        paddingX / 2,
        bgTop,
        layoutWidth - paddingX,
        bgHeight - paddingX / 2,
      );
      final Paint bgPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, Radius.circular(8 * scale)),
        bgPaint,
      );
    }

    // Draw Map if provided
    if (mapBytes != null &&
        template.showMap &&
        template.mapPosition != MapPosition.hidden) {
      try {
        final codec = await ui.instantiateImageCodec(mapBytes);
        final frame = await codec.getNextFrame();
        final mapUiImage = frame.image;

        final double mapX;
        final double mapY;

        if (mapOnLeft) {
          mapX = paddingX;
          mapY = bgTop + (bgHeight - mapH) / 2;
        } else {
          mapX = layoutWidth - paddingX - mapW;
          mapY = template.mapPosition == MapPosition.topRight
              ? paddingY
              : bgTop - paddingY - mapH;
        }

        final Rect mapDestRect = Rect.fromLTWH(mapX, mapY, mapW, mapH);
        final RRect roundedMapRect = RRect.fromRectAndRadius(
          mapDestRect,
          Radius.circular(12 * scale),
        );

        canvas.drawRRect(
          roundedMapRect.inflate(4 * scale),
          Paint()..color = Colors.white,
        );
        final Rect mapSrcRect = Rect.fromLTWH(
          0,
          0,
          mapUiImage.width.toDouble(),
          mapUiImage.height.toDouble(),
        );
        canvas.save();
        canvas.clipRRect(roundedMapRect);
        canvas.drawImageRect(
          mapUiImage,
          mapSrcRect,
          mapDestRect,
          Paint()..isAntiAlias = true,
        );
        canvas.restore();
      } catch (e) {
        debugPrint('Failed to draw map image: $e');
      }
    }

    // Draw QR Code for Scan Location Template
    if (template == OverlayTemplate.scanLocation &&
        snapshot.latitude != null &&
        snapshot.longitude != null) {
      try {
        final String qrData =
            '${snapshot.latitude}, ${snapshot.longitude}\n${snapshot.address ?? ''}';
        final qrPainter = QrPainter(
          data: qrData,
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Colors.black,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.black,
          ),
        );

        final double qrSize = 200 * scale;
        final double qrX = layoutWidth - paddingX - qrSize;
        final double qrY = currentY; // Top of the text block

        canvas.save();
        canvas.translate(qrX, qrY);

        // Draw white background box with padding
        final bgPadding = 10 * scale;
        final Rect qrBgRect = Rect.fromLTWH(
          -bgPadding,
          -bgPadding,
          qrSize + bgPadding * 2,
          qrSize + bgPadding * 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(qrBgRect, Radius.circular(8 * scale)),
          Paint()..color = Colors.white,
        );

        qrPainter.paint(canvas, Size(qrSize, qrSize));
        canvas.restore();
      } catch (e) {
        debugPrint('Failed to draw QR code: $e');
      }
    }

    // Draw Texts
    for (final dt in textsToDraw) {
      dt.painter.paint(canvas, dt.offset);
    }

    // Draw App Logo Image
    if (appLogoUiImage != null && logoImageOffset != null) {
      final Rect logoDestRect = Rect.fromLTWH(
        logoImageOffset.dx,
        logoImageOffset.dy,
        logoImageSize,
        logoImageSize,
      );
      final RRect roundedLogoRect = RRect.fromRectAndRadius(
        logoDestRect,
        Radius.circular(8 * scale),
      );

      canvas.save();
      canvas.clipRRect(roundedLogoRect);
      canvas.drawImageRect(
        appLogoUiImage,
        Rect.fromLTWH(
          0,
          0,
          appLogoUiImage.width.toDouble(),
          appLogoUiImage.height.toDouble(),
        ),
        logoDestRect,
        Paint()..isAntiAlias = true,
      );
      canvas.restore();
    }

    // Finish recording
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}

class _DrawnText {
  final TextPainter painter;
  final Offset offset;
  _DrawnText(this.painter, this.offset);
}
