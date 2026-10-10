import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:geomapcam/features/capture/data/map_image_renderer.dart';
import 'package:geomapcam/features/overlay/domain/overlay_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('com.gpsmapcamera.app/config');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (message) async {
          if (message.method == 'getStaticMapsApiKey') {
            return 'test_key';
          }
          return null;
        });
  });

  group('MapImageRenderer Tests', () {
    test('Throws exception if location is missing', () async {
      final snapshot = OverlaySnapshot(
        timestamp: DateTime.now(),
        // lat/lon missing
      );

      expect(
        () => MapImageRenderer.getMapImage(snapshot),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('Location is missing'),
          ),
        ),
      );
    });

    test('Returns bytes if HTTP 200', () async {
      final snapshot = OverlaySnapshot(
        latitude: 12.34,
        longitude: 56.78,
        timestamp: DateTime.now(),
      );

      final mockClient = MockClient((request) async {
        // Verify URL contains coordinates
        expect(request.url.toString(), contains('center=12.34,56.78'));
        expect(
          request.url.toString(),
          contains('markers=color:red%7C12.34,56.78'),
        );
        return http.Response.bytes(Uint8List.fromList([1, 2, 3]), 200);
      });

      final result = await MapImageRenderer.getMapImage(
        snapshot,
        client: mockClient,
      );
      expect(result, equals([1, 2, 3]));
    });

    test('Throws exception if HTTP fails', () async {
      final snapshot = OverlaySnapshot(
        latitude: 12.34,
        longitude: 56.78,
        timestamp: DateTime.now(),
      );

      final mockClient = MockClient((request) async {
        return http.Response('Error', 403);
      });

      expect(
        () => MapImageRenderer.getMapImage(snapshot, client: mockClient),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'msg',
            contains('HTTP 403'),
          ),
        ),
      );
    });
  });
}
