import 'dart:convert';

import 'package:lunch_core/lunch_core.dart';
import 'package:lunch_scraper/lunch_scraper.dart';
import 'package:test/test.dart';

import '../testing.dart';

/// Hand-written in the shape Compass's web app reads (no real menu was
/// published while this was written).
String _day(
  String package,
  String meal, {
  String? price,
  List<String> diets = const [],
}) => jsonEncode({
  'dayOfWeek': 'Monday',
  'menuPackages': [
    {
      'name': package,
      'price': price,
      'meals': [
        {'name': meal, 'diets': diets},
        {'name': '  ', 'diets': <String>[]},
      ],
    },
  ],
  'html': null,
  'isManualMenu': false,
});

const _empty =
    '{"dayOfWeek":"Monday","menuPackages":[],"html":null,"isManualMenu":false}';

void main() {
  group('parseCompassDay', () {
    test('reads meals with package name, price and diets', () {
      final dishes = parseCompassDay(
        _day('Vegetariskt', 'Linsgryta', price: '95 kr', diets: ['Vegan']),
        Language.sv,
      );

      expect(dishes, hasLength(1));
      expect(dishes.single.name.sv, 'Linsgryta');
      expect(dishes.single.category?.sv, 'Vegetariskt');
      expect(dishes.single.price, 95);
      expect(dishes.single.tags, ['Vegan']);
    });

    test('reads a manually written menu from html', () {
      final body = jsonEncode({
        'menuPackages': <Object>[],
        'html': '<p>Soup</p><p>Pasta<br>Salad</p>',
      });
      expect(
        [for (final dish in parseCompassDay(body, Language.en)) dish.name.en],
        ['Soup', 'Pasta', 'Salad'],
      );
    });

    test('an empty day has no dishes', () {
      expect(parseCompassDay(_empty, Language.sv), isEmpty);
    });

    test('rejects a body that is not an object', () {
      expect(
        () => parseCompassDay('[]', Language.sv),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test(
    'scrape asks for each weekday in both languages and merges them',
    () async {
      const week = IsoWeek(2026, 42);
      final parser = CompassApiParser('8303999');
      final fetcher = FakeFetcher({
        for (final date in week.weekdays) ...{
          parser.dayUrl(date, Language.sv).toString(): date.weekday == 1
              ? _day('Fisk', 'Torsk')
              : _empty,
          parser.dayUrl(date, Language.en).toString(): date.weekday == 1
              ? _day('Fish', 'Cod')
              : _empty,
        },
      });

      final menu = await parser.scrape(fetcher, week);

      expect(fetcher.requested, hasLength(10));
      expect(
        fetcher.requested.first.toString(),
        'https://www.compass-group.se/menuapi/day-menus?costCenter=8303999&date=2026-10-12T00%3A00%3A00.000Z&language=sv',
      );
      expect(menu.week, 42);
      expect(menu.dishesOn(1).single.name.toJson(), {
        'sv': 'Torsk',
        'en': 'Cod',
      });
      expect(menu.dishesOn(1).single.category?.toJson(), {
        'sv': 'Fisk',
        'en': 'Fish',
      });
      expect(menu.dishesOn(2), isEmpty);
    },
  );
}
