import 'package:flutter_test/flutter_test.dart';
import 'package:geomapcam/core/utils/format_utils.dart';

void main() {
  group('FormatUtils', () {
    group('formatLatitude', () {
      test('positive latitude shows N', () {
        expect(FormatUtils.formatLatitude(18.6298), '18.6298° N');
      });

      test('negative latitude shows S', () {
        expect(FormatUtils.formatLatitude(-33.8688), '33.8688° S');
      });

      test('zero latitude shows N', () {
        expect(FormatUtils.formatLatitude(0), '0.0000° N');
      });
    });

    group('formatLongitude', () {
      test('positive longitude shows E', () {
        expect(FormatUtils.formatLongitude(73.7997), '73.7997° E');
      });

      test('negative longitude shows W', () {
        expect(FormatUtils.formatLongitude(-118.2437), '118.2437° W');
      });
    });

    group('formatAccuracy', () {
      test('null returns dash', () {
        expect(FormatUtils.formatAccuracy(null), '—');
      });

      test('formats with one decimal', () {
        expect(FormatUtils.formatAccuracy(4.2), '±4.2 m');
      });
    });

    group('formatAltitude', () {
      test('null returns dash', () {
        expect(FormatUtils.formatAltitude(null), '—');
      });

      test('formats integer meters', () {
        expect(FormatUtils.formatAltitude(568.3), '568 m');
      });
    });

    group('formatHeading', () {
      test('null degrees returns dash', () {
        expect(FormatUtils.formatHeading(null, 'N'), '—');
      });

      test('null cardinal returns dash', () {
        expect(FormatUtils.formatHeading(42.0, null), '—');
      });

      test('formats heading with cardinal', () {
        expect(FormatUtils.formatHeading(42.0, 'NE'), 'NE 42°');
      });
    });

    group('degreesToCardinal', () {
      test('0° is N', () {
        expect(FormatUtils.degreesToCardinal(0), 'N');
      });

      test('45° is NE', () {
        expect(FormatUtils.degreesToCardinal(45), 'NE');
      });

      test('90° is E', () {
        expect(FormatUtils.degreesToCardinal(90), 'E');
      });

      test('135° is SE', () {
        expect(FormatUtils.degreesToCardinal(135), 'SE');
      });

      test('180° is S', () {
        expect(FormatUtils.degreesToCardinal(180), 'S');
      });

      test('225° is SW', () {
        expect(FormatUtils.degreesToCardinal(225), 'SW');
      });

      test('270° is W', () {
        expect(FormatUtils.degreesToCardinal(270), 'W');
      });

      test('315° is NW', () {
        expect(FormatUtils.degreesToCardinal(315), 'NW');
      });

      test('360° wraps to N', () {
        expect(FormatUtils.degreesToCardinal(360), 'N');
      });

      test('negative angle wraps correctly', () {
        expect(FormatUtils.degreesToCardinal(-45), 'NW');
      });

      test('22° is still N (boundary)', () {
        expect(FormatUtils.degreesToCardinal(22), 'N');
      });

      test('23° is NE (boundary)', () {
        expect(FormatUtils.degreesToCardinal(23), 'NE');
      });
    });

    group('normalizeAngle', () {
      test('positive angle in range', () {
        expect(FormatUtils.normalizeAngle(90), 90);
      });

      test('360 wraps to 0', () {
        expect(FormatUtils.normalizeAngle(360), closeTo(0, 0.001));
      });

      test('negative angle wraps', () {
        expect(FormatUtils.normalizeAngle(-90), closeTo(270, 0.001));
      });

      test('large angle wraps', () {
        expect(FormatUtils.normalizeAngle(720), closeTo(0, 0.001));
      });
    });

    group('shortestAngleDifference', () {
      test('same angle is 0', () {
        expect(FormatUtils.shortestAngleDifference(90, 90), 0);
      });

      test('359 to 1 is +2 (not -358)', () {
        expect(FormatUtils.shortestAngleDifference(359, 1), closeTo(2, 0.001));
      });

      test('1 to 359 is -2 (not +358)', () {
        expect(FormatUtils.shortestAngleDifference(1, 359), closeTo(-2, 0.001));
      });

      test('0 to 180 is +180', () {
        expect(
          FormatUtils.shortestAngleDifference(0, 180),
          closeTo(180, 0.001),
        );
      });
    });

    group('smoothHeading', () {
      test('handles 359 and 1 without averaging to 180', () {
        // If we are at 359 and the new heading is 1, diff is +2.
        // Smoothed by factor 0.5: 359 + 1 = 360 = 0.
        final result = FormatUtils.smoothHeading(359, 1, factor: 0.5);
        expect(result, closeTo(0, 0.0001));
      });

      test('handles wrap around negative', () {
        // If we are at 1 and the new heading is 359, diff is -2.
        // Smoothed by factor 0.5: 1 - 1 = 0.
        final result = FormatUtils.smoothHeading(1, 359, factor: 0.5);
        expect(result, closeTo(0, 0.0001));
      });
    });

    group('haversineDistance', () {
      test('same point is 0', () {
        expect(
          FormatUtils.haversineDistance(18.6298, 73.7997, 18.6298, 73.7997),
          closeTo(0, 0.1),
        );
      });

      test('roughly 111 km per degree of latitude', () {
        final distance = FormatUtils.haversineDistance(0, 0, 1, 0);
        // 1° latitude ≈ 111,195 m
        expect(distance, closeTo(111195, 500));
      });
    });
  });
}
