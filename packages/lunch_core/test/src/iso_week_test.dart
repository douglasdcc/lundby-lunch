import 'package:lunch_core/lunch_core.dart';
import 'package:test/test.dart';

void main() {
  group('IsoWeek.fromDate', () {
    test('returns the week of a mid-year date', () {
      expect(IsoWeek.fromDate(DateTime(2026, 10, 10)), const IsoWeek(2026, 41));
    });

    test('assigns early January days to the previous ISO year', () {
      // 2027-01-01 is a Friday, so it belongs to 2026-W53.
      expect(IsoWeek.fromDate(DateTime(2027, 1, 1)), const IsoWeek(2026, 53));
    });

    test('assigns late December days to the next ISO year', () {
      // 2025-12-29 is a Monday in the week containing 2026-01-01 (Thursday).
      expect(IsoWeek.fromDate(DateTime(2025, 12, 29)), const IsoWeek(2026, 1));
    });

    test('ignores the time of day', () {
      expect(
        IsoWeek.fromDate(DateTime(2026, 10, 11, 23, 59)),
        const IsoWeek(2026, 41),
      );
    });
  });

  group('IsoWeek.targetFor', () {
    test('returns the current week on a weekday', () {
      expect(IsoWeek.targetFor(DateTime(2026, 10, 9)), const IsoWeek(2026, 41));
    });

    test('returns the next week on Saturday and Sunday', () {
      expect(
        IsoWeek.targetFor(DateTime(2026, 10, 10)),
        const IsoWeek(2026, 42),
      );
      expect(
        IsoWeek.targetFor(DateTime(2026, 10, 11)),
        const IsoWeek(2026, 42),
      );
    });
  });

  test('monday and weekdays return Monday to Friday in UTC', () {
    const week = IsoWeek(2026, 41);
    expect(week.monday, DateTime.utc(2026, 10, 5));
    expect(week.weekdays, [
      DateTime.utc(2026, 10, 5),
      DateTime.utc(2026, 10, 6),
      DateTime.utc(2026, 10, 7),
      DateTime.utc(2026, 10, 8),
      DateTime.utc(2026, 10, 9),
    ]);
  });

  test('monday of week 1 can fall in the previous year', () {
    expect(const IsoWeek(2026, 1).monday, DateTime.utc(2025, 12, 29));
  });

  test('key is zero padded', () {
    expect(const IsoWeek(2026, 3).key, '2026-W03');
  });

  test('compares by year, then week', () {
    expect(const IsoWeek(2026, 1) > const IsoWeek(2025, 52), isTrue);
    expect(const IsoWeek(2026, 40) < const IsoWeek(2026, 41), isTrue);
  });
}
