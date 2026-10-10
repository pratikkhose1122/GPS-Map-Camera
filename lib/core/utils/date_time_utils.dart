/// Date/time formatting utilities for GPS Map Camera.
///
/// Centralized so both the live overlay and the frozen
/// OverlaySnapshot use identical formatting.
class DateTimeUtils {
  DateTimeUtils._();

  /// Format a DateTime for display in the overlay.
  ///
  /// Example: "04 Oct 2026 • 02:30 PM"
  static String formatOverlayDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _monthAbbr[dt.month] ?? '';
    final year = dt.year;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day $month $year • ${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  static const _monthAbbr = {
    1: 'Jan',
    2: 'Feb',
    3: 'Mar',
    4: 'Apr',
    5: 'May',
    6: 'Jun',
    7: 'Jul',
    8: 'Aug',
    9: 'Sep',
    10: 'Oct',
    11: 'Nov',
    12: 'Dec',
  };
}
