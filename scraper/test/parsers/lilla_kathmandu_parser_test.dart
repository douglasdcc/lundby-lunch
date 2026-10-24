import 'dart:convert';

import 'package:lunch_core/lunch_core.dart';
import 'package:lunch_scraper/lunch_scraper.dart';
import 'package:test/test.dart';

import '../testing.dart';

/// A page whose Next.js data holds [block], split over two pushed strings.
String _page(Map<String, Object?> block) {
  final data =
      '1:"x"\n24:${jsonEncode([
        r'$',
        'div',
        {'children': block},
      ])}\n';
  final half = data.length ~/ 2;
  String push(String part) =>
      '<script>self.__next_f.push([1,${jsonEncode(part)}])</script>';
  return push(data.substring(0, half)) + push(data.substring(half));
}

Map<String, Object?> _block(List<Map<String, Object?>> mondayDishes) => {
  'blockType': 'weeklyLunchMenu',
  'sharedPrice': 115,
  'primaryGroups': [
    {
      'groupTitle': 'Jämna veckor',
      'monday': {'dishes': mondayDishes},
    },
    {
      'groupTitle': 'Udda veckor',
      'monday': {
        'dishes': [
          {'name': 'Odd'},
        ],
      },
    },
  ],
};

void main() {
  group('Lilla Kathmandu page', () {
    final page = fixture('lillakathmandu.html');

    test('reads the even-week menu in an even week', () {
      final menu = parseLillaKathmanduPage(page, const IsoWeek(2026, 44));

      expect(menu.week, 44);
      expect([for (final day in menu.days) day.weekday], [1, 2, 3, 4, 5]);
      expect([for (final day in menu.days) day.dishes.length], [4, 4, 4, 4, 4]);
      expect(
        [for (final dish in menu.dishesOn(1)) dish.name.sv],
        ['Butter Chicken', 'Lamm Achari', 'Palak Paneer', 'Chicken Piri Piri'],
      );

      final butterChicken = menu.dishesOn(1).first;
      expect(
        butterChicken.description?.sv,
        'Tandoori marinerade kycklingfilébitar i en krämig sås av smör och '
        'russin.',
      );
      expect(butterChicken.description?.en, isNull);
      expect(butterChicken.price, 115);
      expect(butterChicken.tags, isEmpty);
    });

    test('reads the odd-week menu in an odd week, with the shared price', () {
      final menu = parseLillaKathmanduPage(page, const IsoWeek(2026, 43));

      expect(menu.week, 43);
      final first = menu.dishesOn(1).first;
      expect(first.name.sv, 'Nauni Chicken');
      expect(first.price, 115);
    });

    test('reads Mild, Mellan, Medium and Stark as spice levels', () {
      final menu = parseLillaKathmanduPage(page, const IsoWeek(2026, 44));

      expect(
        [for (final dish in menu.dishesOn(1)) dish.spice],
        [
          SpiceLevel.mild,
          SpiceLevel.hot,
          SpiceLevel.mild,
          SpiceLevel.medium, // "Medium"
        ],
      );
      expect(menu.dishesOn(3)[1].spice, SpiceLevel.medium); // "Mellan"
    });
  });

  test('keeps an unknown label as a tag', () {
    final menu = parseLillaKathmanduPage(
      _page(
        _block([
          {'name': 'Dal', 'dietaryLabel': 'Vegansk'},
        ]),
      ),
      const IsoWeek(2026, 44),
    );

    final dish = menu.dishesOn(1).single;
    expect(dish.spice, isNull);
    expect(dish.tags, ['Vegansk']);
  });

  test('rejects a page without the menu or the week group', () {
    expect(
      () => parseLillaKathmanduPage('<p>Hej</p>', const IsoWeek(2026, 44)),
      throwsA(isA<FormatException>()),
    );
    final block = _block([])
      ..['primaryGroups'] = [
        {'groupTitle': 'Vecka A'},
      ];
    expect(
      () => parseLillaKathmanduPage(_page(block), const IsoWeek(2026, 44)),
      throwsA(isA<FormatException>()),
    );
  });

  test('downloads the configured page', () async {
    const url = 'https://www.lillakathmandu.se/sv/lunch';
    final fetcher = FakeFetcher({
      url: _page(
        _block([
          {'name': 'Dal'},
        ]),
      ),
    });

    final menu = await LillaKathmanduParser(Uri.parse(url))
        .scrape(fetcher, const IsoWeek(2026, 44));

    expect(fetcher.requested, [Uri.parse(url)]);
    expect(menu.dishesOn(1).single.name.sv, 'Dal');
  });
}
