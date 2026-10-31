import 'package:lunch_core/lunch_core.dart';
import 'package:lunch_scraper/lunch_scraper.dart';
import 'package:test/test.dart';

import '../testing.dart';

List<(String?, String?)> _names(List<Dish> dishes) => [
  for (final dish in dishes) (dish.name.sv, dish.name.en),
];

void main() {
  group('Roots', () {
    final menu = mergeLanguages(
      sv: parseRootsPage(fixture('roots_sv.html'), Language.sv),
      en: parseRootsPage(fixture('roots_en.html'), Language.en),
      targetWeek: 41,
    );

    test('reads the week and four categories for each weekday', () {
      expect(menu.week, 41);
      expect([for (final day in menu.days) day.weekday], [1, 2, 3, 4, 5]);
      for (final day in menu.days) {
        expect(
          [for (final dish in day.dishes) dish.category?.en],
          ['Vegetarian', 'Fish', 'Meat', 'Street Food'],
          reason: 'weekday ${day.weekday}',
        );
      }
      expect(menu.dishesOn(1).first.category?.sv, 'Vegetariskt');
    });

    test('joins dish names that wrap onto the next line', () {
      final fish = menu.dishesOn(1)[1];
      expect(
        fish.name.en,
        'Brown butter-baked catch of the day with potato purée, shellfish cream sauce, '
        'shaved vegetables & crispy potatoes',
      );
      expect(fish.name.sv, startsWith('Brynt smörbakad dagens fångst'));
      expect(fish.name.sv, endsWith('hyvlade grönsaker & potatis krisp'));
    });

    test('a page without a menu block has no week', () {
      expect(parseRootsPage('<p>Closed</p>', Language.en).week, isNull);
    });
  });

  group('Spira', () {
    final menu = parseSpiraPage(fixture('spira.html'));

    test('reads the week and three or four dishes per weekday', () {
      expect(menu.week, 41);
      expect([for (final day in menu.days) day.dishes.length], [3, 3, 3, 4, 3]);
    });

    test('pairs Swedish and English lines by language, not position', () {
      // Thursday lists two Swedish lines before their English versions.
      final thursday = _names(menu.dishesOn(4));
      expect(thursday[0].$1, startsWith('Ärtsoppa med fläsk'));
      expect(thursday[0].$2, startsWith('Yellow pea soup'));
      expect(thursday[1].$1, startsWith('Mustig kycklinggryta'));
      expect(thursday[1].$2, startsWith('Chicken stew'));
      expect(thursday[3].$1, startsWith('Yam Tofu-Krispig'));
      expect(thursday[3].$2, startsWith('Yam Tofu – Crispy'));
    });

    test('ignores the address and other non-menu text', () {
      final all = [for (final day in menu.days) ...day.dishes];
      expect(
        all.where(
          (dish) =>
              '${dish.name.sv}${dish.name.en}'.contains('Gropegårdsgatan'),
        ),
        isEmpty,
      );
    });
  });

  group('Spira with all days in one heading', () {
    final menu = parseSpiraPage('''
      <h3>Lunchmeny vecka 42</h3>
      <h6><strong>Måndag</strong><br>Köttbullar med potatismos och gräddsås<br>
      Meatballs with mashed potatoes and cream<br>gravy<br>
      <strong>Tisdag</strong><br>Burrito med nötfärs, ris samt mexikansk<br>
      majssallad<br>Beef burrito with rice and Mexican corn<br>salad<br>
      Örtbakad torsk med potatis<br>Herb-baked cod with potatoes</h6>
    ''');

    test('splits the heading at each weekday name', () {
      expect(menu.week, 42);
      expect([for (final day in menu.days) day.weekday], [1, 2]);
      expect([for (final day in menu.days) day.dishes.length], [1, 2]);
    });

    test('joins dish names that wrap onto a new line', () {
      expect(_names(menu.dishesOn(1)), [
        (
          'Köttbullar med potatismos och gräddsås',
          'Meatballs with mashed potatoes and cream gravy',
        ),
      ]);
      expect(_names(menu.dishesOn(2)), [
        (
          'Burrito med nötfärs, ris samt mexikansk majssallad',
          'Beef burrito with rice and Mexican corn salad',
        ),
        ('Örtbakad torsk med potatis', 'Herb-baked cod with potatoes'),
      ]);
    });
  });

  group('Bar Centro', () {
    final menu = mergeLanguages(
      sv: parseBarCentroPage(fixture('barcentro_sv.html'), Language.sv),
      en: parseBarCentroPage(fixture('barcentro_en.html'), Language.en),
      targetWeek: 41,
    );

    test('reads the dish of the day and the daily vegetarian special', () {
      expect(menu.week, 41);
      expect([for (final day in menu.days) day.weekday], [1, 2, 3, 4, 5]);

      final tuesday = menu.dishesOn(2);
      expect(tuesday, hasLength(2));
      expect(
        tuesday[0].name.en,
        'Chicken tikka masala with basmati rice, mango chutney and coriander',
      );
      expect(
        tuesday[0].name.sv,
        'Chicken tikka masala med basmatiris, mango chutney och koriander',
      );
      expect(tuesday[0].price, 115);
      expect(tuesday[0].tags, ['L']);
      expect(tuesday[1].category?.toJson(), {
        'sv': 'Dagens vegetariska',
        'en': 'Daily vegetarian',
      });
      expect(tuesday[1].name.en, startsWith('Tofu tikka masala'));
    });

    test('reads the weekly specials with prices and tags', () {
      expect(
        [for (final dish in menu.weekly) dish.category?.en],
        [
          'Pasta of the Week',
          'Salad of the Week',
          'Soup of the Week',
          'Pie of the Week',
        ],
      );
      expect(
        [for (final dish in menu.weekly) dish.price],
        [115, 110, 100, 105],
      );
      expect(menu.weekly[2].tags, ['G', 'L']);
      expect(
        menu.weekly[2].name.sv,
        'Potatis- och purjolökssoppa med krutonger',
      );
    });

    test('drops a label in front of a weekly special', () {
      const page = '''
<article class="section lunchmenu">
  <header><h6>Vecka 44</h6></header>
  <article class="section specials">
    <article class="day">
      <aside class="price">110</aside>
      <h4>Veckans Sallad;</h4>
      <section><p>Dagens Sallad; Pulled pork med äggnudlar, koriander (G)</p></section>
    </article>
  </article>
</article>''';
      final weekly = parseBarCentroPage(page, Language.sv).weekly;
      expect(weekly.single.name.sv, 'Pulled pork med äggnudlar, koriander');
      expect(weekly.single.category?.sv, 'Veckans Sallad');
      expect(weekly.single.tags, ['G']);
    });

    test('a page without the lunch section has no week', () {
      expect(parseBarCentroPage('<p>Hello</p>', Language.sv).week, isNull);
    });
  });

  group('Mashie', () {
    final page = fixture('mashie_zata.html');

    test(
      'reads the requested week, pairing each dish with its translation',
      () {
        final menu = parseMashiePage(page, 41);

        expect(menu.week, 41);
        expect([for (final day in menu.days) day.weekday], [1, 2, 3, 4, 5]);
        final monday = menu.dishesOn(1);
        expect(monday.first.category?.toJson(), {'sv': 'Vego', 'en': 'Vego'});
        expect(monday.first.name.sv, startsWith('Rostad pumpa med bönragu'));
        expect(
          monday.first.name.en,
          startsWith('Roasted pumpkin with bean mix'),
        );
        expect(monday[1].category?.toJson(), {'sv': 'Fisk', 'en': 'Fish'});
      },
    );

    test('skips alternatives without a dish', () {
      final monday = parseMashiePage(page, 41).dishesOn(1);
      expect(
        [for (final dish in monday) dish.category?.sv],
        ['Vego', 'Fisk', 'Kött'],
      );
    });

    test('picks the next week when it is already published', () {
      final menu = parseMashiePage(page, 42);
      expect(menu.week, 42);
      expect(menu.hasDishes, isTrue);
      expect(
        menu.dishesOn(1).first.name.sv,
        isNot(parseMashiePage(page, 41).dishesOn(1).first.name.sv),
      );
    });

    test('falls back to the last week shown when the target is missing', () {
      expect(parseMashiePage(page, 43).week, 42);
      expect(parseMashiePage('<p>Nothing</p>', 41).week, isNull);
    });
  });
}
