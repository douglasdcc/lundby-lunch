import 'dates.dart';

/// An ISO-8601 week (weeks start on Monday; week 1 contains January 4th).
final class IsoWeek implements Comparable<IsoWeek> {
  const IsoWeek(this.year, this.week);

  factory IsoWeek.fromDate(DateTime date) {
    final day = dateOnly(date);
    // The ISO year and week are those of the Thursday in the same week.
    final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
    final januaryFirst = DateTime.utc(thursday.year);
    final week = thursday.difference(januaryFirst).inDays ~/ 7 + 1;
    return IsoWeek(thursday.year, week);
  }

  /// The week whose lunch menu matters on [date]: the current week on
  /// weekdays, the next week on Saturdays and Sundays.
  factory IsoWeek.targetFor(DateTime date) {
    final day = dateOnly(date);
    if (day.weekday >= DateTime.saturday) {
      return IsoWeek.fromDate(day.add(Duration(days: 8 - day.weekday)));
    }
    return IsoWeek.fromDate(day);
  }

  final int year;
  final int week;

  DateTime get monday {
    final januaryFourth = DateTime.utc(year, 1, 4);
    final firstMonday = januaryFourth.subtract(
      Duration(days: januaryFourth.weekday - DateTime.monday),
    );
    return firstMonday.add(Duration(days: (week - 1) * 7));
  }

  /// Monday to Friday of this week.
  List<DateTime> get weekdays => [
    for (var i = 0; i < 5; i++) monday.add(Duration(days: i)),
  ];

  bool contains(DateTime date) => IsoWeek.fromDate(date) == this;

  /// A stable identifier such as `2026-W41`.
  String get key => '$year-W${week.toString().padLeft(2, '0')}';

  @override
  int compareTo(IsoWeek other) => year != other.year
      ? year.compareTo(other.year)
      : week.compareTo(other.week);

  bool operator <(IsoWeek other) => compareTo(other) < 0;
  bool operator >(IsoWeek other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is IsoWeek && other.year == year && other.week == week;

  @override
  int get hashCode => Object.hash(year, week);

  @override
  String toString() => key;
}
