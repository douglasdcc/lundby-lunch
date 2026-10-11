/// Strips the time of day, returning a UTC midnight value.
///
/// Menu dates are calendar days, so they are kept in UTC to avoid
/// daylight-saving shifts when adding days.
DateTime dateOnly(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);

/// Formats [date] as `yyyy-MM-dd`.
String formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
}

/// Parses a `yyyy-MM-dd` string into a UTC midnight value.
DateTime parseDate(String value) => dateOnly(DateTime.parse(value));
