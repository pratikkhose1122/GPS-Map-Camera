import 'package:flutter_test/flutter_test.dart';
import 'package:geomapcam/core/utils/date_time_utils.dart';

void main() {
  group('DateTimeUtils', () {
    group('formatOverlayDateTime', () {
      test('formats correctly', () {
        final dt = DateTime(2026, 10, 4, 14, 30); // 2:30 PM
        expect(
          DateTimeUtils.formatOverlayDateTime(dt),
          '04 Oct 2026 • 02:30 PM',
        );
      });

      test('formats AM correctly', () {
        final dt = DateTime(2026, 1, 15, 9, 5); // 9:05 AM
        expect(
          DateTimeUtils.formatOverlayDateTime(dt),
          '15 Jan 2026 • 09:05 AM',
        );
      });

      test('midnight shows 12 AM', () {
        final dt = DateTime(2026, 6, 1, 0, 0);
        expect(
          DateTimeUtils.formatOverlayDateTime(dt),
          '01 Jun 2026 • 12:00 AM',
        );
      });

      test('noon shows 12 PM', () {
        final dt = DateTime(2026, 12, 25, 12, 0);
        expect(
          DateTimeUtils.formatOverlayDateTime(dt),
          '25 Dec 2026 • 12:00 PM',
        );
      });
    });
  });
}
