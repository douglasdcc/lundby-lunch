import 'package:lunch_core/lunch_core.dart';
import 'package:lunch_scraper/lunch_scraper.dart';
import 'package:test/test.dart';

import '../testing.dart';

/// An accordion tab titled [day], with one menu item per `(title, price,
/// description)` and optional HTML before and after the items.
String _tab(
  String day,
  List<(String, int?, String?)> items, {
  String before = '',
  String after = '',
}) =>
    '''
<div class="pp-accordion-item">
  <span class="pp-accordion-title-text">$day</span>
  <div class="pp-accordion-tab-content">
    $before
    ${items.map(_item).join()}
    $after
  </div>
</div>''';

String _item((String, int?, String?) item) {
  final (title, price, description) = item;
  return '''
<div class="pp-restaurant-menu-item">
  <span class="pp-restaurant-menu-title-text">$title</span>
  ${price == null ? '' : '<span class="pp-restaurant-menu-price">$price</span>'}
  ${description == null ? '' : '<div class="pp-restaurant-menu-description">$description</div>'}
</div>''';
}

void main() {
  group('Masala Zone page', () {
    final menu = parseMasalaZonePage(
      fixture('masalazone.html'),
      const IsoWeek(2026, 44),
    );

    test('reads every weekday, without the pizzas', () {
      // The page has no week number.
      expect(menu.week, 44);
      expect([for (final day in menu.days) day.weekday], [1, 2, 3, 4, 5]);
      expect([for (final day in menu.days) day.dishes.length], [7, 7, 7, 7, 7]);
      expect(
        [for (final dish in menu.dishesOn(1)) dish.name.sv],
        [
          'Tandoori Chicken',
          'Murgh Methi Malai',
          'Malwani Gosht',
          'Mix Veg. Tallrik',
          'Murgh Methi Malai + Malwani Gosht',
          'Butter Chicken',
          'Prawn Masala',
        ],
      );
      expect(menu.dishesOn(5)[3].name.sv, 'Mix Veg.Tallrik');
    });

    test('uses the lunch price when a dish has none', () {
      expect(
        [for (final dish in menu.dishesOn(1)) dish.price],
        [114, 114, 114, 114, 139, 139, 149],
      );
    });

    test('reads chilies as spice levels and labels as tags', () {
      final monday = menu.dishesOn(1);
      expect(monday[0].spice, isNull);
      expect(monday[0].tags, isEmpty);
      expect(monday[2].spice, SpiceLevel.medium);
      expect(monday[2].tags, ['Laktosfri']);
      expect(monday[3].spice, SpiceLevel.mild);
      expect(menu.dishesOn(4)[5].name.sv, 'Chicken Vindaloo');
      expect(menu.dishesOn(4)[5].spice, SpiceLevel.hot);
    });

    test('splits descriptions into Swedish and English', () {
      final tandoori = menu.dishesOn(1).first;
      expect(
        tandoori.description?.sv,
        'Grillad kycklingklubbs med ben marinrad i yoghurt. Tandoori masala, '
        'ingefära,vitlölk, gräddsås.',
      );
      expect(
        tandoori.description?.en,
        'Grilled chicken leg with bone marinated in yogurt. Tandoori masala, '
        'ginger, garlic cream sauce',
      );

      final butterChicken = menu.dishesOn(1)[5];
      expect(butterChicken.description?.en, isNull);

      final mixVeg = menu.dishesOn(1)[3];
      expect(
        mixVeg.description?.sv,
        'Tre små vegetariska rätter 1. Aloo Gobhi 2. Malai Kofta '
        '3. Paneer Butter Masala',
      );
      expect(
        mixVeg.description?.en,
        'Three small vegetarian dishes 1. Aloo Gobhi 2. Malai Kofta '
        '3. Paneer Butter Masala',
      );
    });

    test('names the combined plate after its dishes', () {
      final combined = menu.dishesOn(1)[4];
      expect(combined.description, isNull);
      // The hotter dish sets the spice; Murgh Methi Malai is not Laktosfri.
      expect(combined.spice, SpiceLevel.medium);
      expect(combined.tags, isEmpty);

      final wednesday = menu.dishesOn(3)[4];
      expect(wednesday.name.sv, 'Murgh Madras + Curry Gosht');
      expect(wednesday.tags, ['Laktosfri']);
    });

    test('notes what is included and that pizza is served', () {
      expect(
        menu.notes?.sv,
        'I dagens ingår: Naanbröd, ris salladsbuffé, kaffe & kaka. '
        'Pizza finns också som lunch.',
      );
      expect(
        menu.notes?.en,
        'Included: naan bread, rice, salad buffet, coffee & cake. '
        'Pizza is also available for lunch.',
      );
    });
  });

  test('keeps the first copy of a day and reads "Måndag/Monday"', () {
    final page =
        '<h2>Lunch fr. 120 kr</h2>'
        '${_tab('Måndag/Monday', [('1.DAL', null, null)])}'
        '${_tab('Monday', [('1.OTHER', null, null)])}'
        '${_tab('Lunch Meny Pizza', [('1.MARGERITHA', null, null)])}';

    final menu = parseMasalaZonePage(page, const IsoWeek(2026, 44));

    expect(menu.days, hasLength(1));
    final dal = menu.dishesOn(1).single;
    expect(dal.name.sv, 'Dal');
    expect(dal.price, 120);
    expect(menu.notes, isNull);
  });

  test('stops at the pizza heading', () {
    final page = _tab(
      'Tuesday',
      [('1.DAL', 99, null)],
      before: '<h2>Stående alternativ:</h2>',
      after:
          '<h2>Tomatsås &amp; Ost ingår i alla pizzor</h2>'
          '${_item(('1.MARGERITHA', null, null))}',
    );

    final menu = parseMasalaZonePage(page, const IsoWeek(2026, 44));

    expect([for (final dish in menu.dishesOn(2)) dish.name.sv], ['Dal']);
    expect(menu.notes?.sv, 'Pizza finns också som lunch.');
    expect(menu.notes?.en, 'Pizza is also available for lunch.');
  });

  test('leaves the English note out when the included line is new', () {
    final page =
        '<p>I dagens ingår: Naanbröd</p>'
        '${_tab('Monday', [('1.DAL', null, null)])}';

    final menu = parseMasalaZonePage(page, const IsoWeek(2026, 44));

    expect(menu.notes?.sv, 'I dagens ingår: Naanbröd');
    expect(menu.notes?.en, isNull);
  });

  test('rejects a page without weekday menus', () {
    expect(
      () => parseMasalaZonePage('<p>Hej</p>', const IsoWeek(2026, 44)),
      throwsA(isA<FormatException>()),
    );
  });

  test('downloads the configured page', () async {
    const url =
        'https://www.masalazone.se/indisk-restaurang-masala-zone-hisingen/';
    final fetcher = FakeFetcher({
      url: _tab('Monday', [('1.DAL', null, null)]),
    });

    final menu = await MasalaZoneParser(Uri.parse(url))
        .scrape(fetcher, const IsoWeek(2026, 44));

    expect(fetcher.requested, [Uri.parse(url)]);
    expect(menu.dishesOn(1).single.name.sv, 'Dal');
  });
}
