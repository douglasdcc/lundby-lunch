import 'package:lunch_core/lunch_core.dart';
import 'package:lunch_scraper/lunch_scraper.dart';
import 'package:test/test.dart';

import 'testing.dart';

/// Monday of week 42, 2026.
final _monday = DateTime(2026, 10, 12, 7);
const _week42 = IsoWeek(2026, 42);

class _FakeParser implements MenuParser {
  _FakeParser(this.result);

  /// A [ScrapedMenu] to return, or an [Exception] to throw.
  final Object result;
  int calls = 0;

  @override
  Future<ScrapedMenu> scrape(Fetcher fetcher, IsoWeek week) async {
    calls++;
    final result = this.result;
    if (result is Exception) throw result;
    return result as ScrapedMenu;
  }
}

RestaurantConfig _config(String id, Object result, {String? name}) =>
    RestaurantConfig(
      id: id,
      name: name ?? 'Restaurant $id',
      website: LocalizedText(sv: 'https://$id.example'),
      address: 'Street 1',
      lunchHours: '11–13',
      parser: _FakeParser(result),
    );

ScrapedMenu _scraped(int week) => ScrapedMenu(
  week: week,
  days: [
    ScrapedDay(1, [dishIn(Language.sv, 'Måndagsrätt')]),
    const ScrapedDay(2, []),
    ScrapedDay(3, [dishIn(Language.sv, 'Onsdagsrätt')]),
  ],
  weekly: [dishIn(Language.sv, 'Veckans soppa')],
);

Future<WeekMenus> _run(
  List<RestaurantConfig> restaurants, {
  WeekMenus? previous,
  DateTime? now,
}) => MenuScraper(
  restaurants: restaurants,
  fetcher: FakeFetcher(),
  now: () => now ?? _monday,
  log: (_) {},
).run(previous: previous);

RestaurantMenu _only(WeekMenus menus) => menus.restaurants.single;

void main() {
  test('a menu for the target week is ok and dated by weekday', () async {
    final menus = await _run([_config('a', _scraped(42))]);

    expect(menus.week, _week42);
    expect(menus.generatedAt, _monday.toUtc());
    final restaurant = _only(menus);
    expect(restaurant.status, MenuStatus.ok);
    expect(restaurant.fetchedAt, _monday.toUtc());
    expect(
      [for (final day in restaurant.days) day.date],
      [DateTime.utc(2026, 10, 12), DateTime.utc(2026, 10, 14)],
    );
    expect(restaurant.weekly.single.name.sv, 'Veckans soppa');
    expect(restaurant.address, 'Street 1');
    expect(restaurant.lunchHours, '11–13');
  });

  test('a page still showing last week is missing', () async {
    final restaurant = _only(await _run([_config('a', _scraped(41))]));

    expect(restaurant.status, MenuStatus.missing);
    expect(restaurant.days, isEmpty);
  });

  test('a page without dishes is missing', () async {
    final restaurant = _only(
      await _run([_config('a', const ScrapedMenu(week: 42))]),
    );
    expect(restaurant.status, MenuStatus.missing);
  });

  test(
    'a failing restaurant is an error and does not stop the others',
    () async {
      final menus = await _run([
        _config('a', const FetchException('HTTP 500')),
        _config('b', _scraped(42)),
      ]);

      expect(
        [for (final r in menus.restaurants) r.status],
        [MenuStatus.error, MenuStatus.ok],
      );
    },
  );

  test('on Sunday it targets next week', () async {
    final menus = await _run([
      _config('a', _scraped(42)),
    ], now: DateTime(2026, 10, 11, 18));

    expect(menus.week, _week42);
    expect(_only(menus).status, MenuStatus.ok);
  });

  group('with previous menus', () {
    Future<WeekMenus> previousWith(
      MenuStatus status, {
      IsoWeek week = _week42,
    }) async {
      final restaurant = RestaurantMenu(
        id: 'a',
        name: 'Old name',
        website: const LocalizedText(sv: 'https://old.example'),
        status: status,
        fetchedAt: DateTime.utc(2026, 10, 12, 5),
        days: [
          DayMenu(
            date: week.monday,
            dishes: [dishIn(Language.sv, 'Sparad rätt')],
          ),
        ],
      );
      return WeekMenus(
        week: week,
        generatedAt: DateTime.utc(2026, 10, 12, 5),
        restaurants: [restaurant],
      );
    }

    test('scrapes a complete restaurant again and uses the new menu', () async {
      final config = _config('a', _scraped(42));

      final restaurant = _only(
        await _run([config], previous: await previousWith(MenuStatus.ok)),
      );

      expect((config.parser as _FakeParser).calls, 1);
      expect(restaurant.days.first.dishes.single.name.sv, 'Måndagsrätt');
      expect(restaurant.fetchedAt, _monday.toUtc());
    });

    test('keeps when it was fetched if the menu is unchanged', () async {
      final first = await _run([_config('a', _scraped(42))]);

      final restaurant = _only(
        await _run(
          [_config('a', _scraped(42))],
          previous: first,
          now: _monday.add(const Duration(hours: 2)),
        ),
      );

      expect(restaurant.fetchedAt, _monday.toUtc());
    });

    for (final (outcome, result) in [
      ('missing', _scraped(41)),
      ('failing', const FetchException('HTTP 500')),
    ]) {
      test('keeps a complete menu when the new scrape is $outcome', () async {
        final config = _config('a', result, name: 'New name');

        final restaurant = _only(
          await _run([config], previous: await previousWith(MenuStatus.ok)),
        );

        expect(restaurant.status, MenuStatus.ok);
        expect(restaurant.days.single.dishes.single.name.sv, 'Sparad rätt');
        expect(restaurant.fetchedAt, DateTime.utc(2026, 10, 12, 5));
        // Names and links always come from the current config.
        expect(restaurant.name, 'New name');
        expect(restaurant.website.sv, 'https://a.example');
      });
    }

    test('scrapes again a restaurant that was missing', () async {
      final config = _config('a', _scraped(42));

      final restaurant = _only(
        await _run([config], previous: await previousWith(MenuStatus.missing)),
      );

      expect((config.parser as _FakeParser).calls, 1);
      expect(restaurant.days.first.dishes.single.name.sv, 'Måndagsrätt');
    });

    test('ignores menus from an older week', () async {
      final config = _config('a', _scraped(42));

      await _run(
        [config],
        previous: await previousWith(
          MenuStatus.ok,
          week: const IsoWeek(2026, 41),
        ),
      );

      expect((config.parser as _FakeParser).calls, 1);
    });

    test('drops restaurants no longer in the config', () async {
      final menus = await _run([
        _config('b', _scraped(42)),
      ], previous: await previousWith(MenuStatus.ok));

      expect([for (final r in menus.restaurants) r.id], ['b']);
    });
  });
}
