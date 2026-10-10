import 'package:flutter/cupertino.dart';
import 'package:geomapcam/features/camera/presentation/camera_screen.dart';
import 'package:geomapcam/features/gallery/presentation/gallery_screen.dart';
import 'package:geomapcam/features/gallery/presentation/photo_viewer_screen.dart';
import 'package:geomapcam/features/settings/presentation/templates_screen.dart';
import 'package:geomapcam/features/gallery/domain/models/photo_item.dart';
import 'package:geomapcam/features/settings/presentation/settings_screen.dart';
import 'package:geomapcam/features/capture/presentation/capture_result_screen.dart';
import 'package:geomapcam/features/capture/domain/capture_result.dart';
import 'package:geomapcam/features/locations/presentation/locations_screen.dart';
import 'package:geomapcam/features/reports/presentation/reports_screen.dart';
import 'package:geomapcam/features/settings/presentation/filename_settings_screen.dart';

/// Centralized named-route configuration.
class AppRouter {
  AppRouter._();

  // Route names
  static const String home = '/';
  static const String gallery = '/gallery';
  static const String settings = '/settings';
  static const String photoViewer = '/photoViewer';
  static const String captureResult = '/captureResult';
  static const String templates = '/templates';
  static const String locations = '/locations';
  static const String reports = '/reports';
  static const String filename = '/filename';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    Widget page;
    switch (routeSettings.name) {
      case home:
        page = const CameraScreen();
        break;
      case gallery:
        page = const GalleryScreen();
        break;
      case settings:
        page = const SettingsScreen();
        break;
      case templates:
        page = const TemplatesScreen();
        break;
      case photoViewer:
        final photo = routeSettings.arguments as PhotoItem;
        page = PhotoViewerScreen(photo: photo);
        break;
      case captureResult:
        final result = routeSettings.arguments as CaptureResult;
        page = CaptureResultScreen(result: result);
        break;
      case locations:
        page = const LocationsScreen();
        break;
      case reports:
        page = const ReportsScreen();
        break;
      case filename:
        page = const FilenameSettingsScreen();
        break;
      default:
        page = const CameraScreen();
    }

    // CupertinoPageRoute gives a much smoother, premium sliding animation
    // and naturally supports swipe-to-go-back gestures.
    return CupertinoPageRoute(builder: (_) => page, settings: routeSettings);
  }
}
