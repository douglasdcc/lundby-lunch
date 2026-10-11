import 'package:lunch_core/lunch_core.dart';
import 'package:lunch_scraper/lunch_scraper.dart';
import 'package:test/test.dart';

ScrapedMenu _menu(Language language, int week, List<String> mondayDishes) =>
    ScrapedMenu(
      week: week,
      days: [
        ScrapedDay(1, [
          for (final name in mondayDishes)
            dishIn(language, name, category: 'c-${language.name}'),
        ]),
      ],
    );

void main() {
  test('mergeLanguages pairs dishes by weekday and position', () {
    final merged = mergeLanguages(
      sv: _menu(Language.sv, 41, ['Soppa', 'Fisk']),
      en: _menu(Language.en, 41, ['Soup', 'Fish']),
      targetWeek: 41,
    );

    final dishes = merged.dishesOn(1);
    expect(merged.week, 41);
    expect(
      [for (final dish in dishes) (dish.name.sv, dish.name.en)],
      [('Soppa', 'Soup'), ('Fisk', 'Fish')],
    );
    expect(dishes.first.category?.toJson(), {'sv': 'c-sv', 'en': 'c-en'});
  });

  test('mergeLanguages keeps unpaired dishes', () {
    final merged = mergeLanguages(
      sv: _menu(Language.sv, 41, ['Soppa', 'Extra']),
      en: _menu(Language.en, 41, ['Soup']),
      targetWeek: 41,
    );

    expect(merged.dishesOn(1).last.name.toJson(), {'sv': 'Extra'});
  });

  test('mergeLanguages prefers the page showing the target week', () {
    final sv = _menu(Language.sv, 41, ['Gammal']);
    final en = _menu(Language.en, 42, ['New']);

    expect(mergeLanguages(sv: sv, en: en, targetWeek: 42).week, 42);
    expect(mergeLanguages(sv: sv, en: en, targetWeek: 41).week, 41);
    expect(mergeLanguages(sv: sv, en: en, targetWeek: 43).week, 41);
  });

  test('mergeDishes combines price and tags', () {
    final merged = mergeDishes(
      [
        dishIn(Language.sv, 'Soppa', price: 100, tags: ['G']),
      ],
      [
        dishIn(Language.en, 'Soup', tags: ['G', 'L']),
      ],
    );

    expect(merged.single.price, 100);
    expect(merged.single.tags, ['G', 'L']);
  });

  test('hasDishes is false for an empty menu', () {
    expect(
      const ScrapedMenu(week: 41, days: [ScrapedDay(1, [])]).hasDishes,
      isFalse,
    );
    expect(_menu(Language.sv, 41, ['Soppa']).hasDishes, isTrue);
  });
}
