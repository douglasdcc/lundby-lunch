import 'package:lunch_core/lunch_core.dart';

/// Dishes for one weekday (1 = Monday).
final class ScrapedDay {
  const ScrapedDay(this.weekday, this.dishes);

  final int weekday;
  final List<Dish> dishes;
}

/// What a parser read from a restaurant's website.
final class ScrapedMenu {
  const ScrapedMenu({
    required this.week,
    this.days = const [],
    this.weekly = const [],
  });

  /// The week number printed on the page, if any.
  final int? week;
  final List<ScrapedDay> days;
  final List<Dish> weekly;

  bool get hasDishes =>
      days.any((day) => day.dishes.isNotEmpty) || weekly.isNotEmpty;

  List<Dish> dishesOn(int weekday) => [
    for (final day in days)
      if (day.weekday == weekday) ...day.dishes,
  ];
}

/// Combines a Swedish-only and an English-only reading of the same menu,
/// pairing dishes by weekday and position.
///
/// When the two pages show different weeks, the one for [targetWeek] wins,
/// falling back to the Swedish page.
ScrapedMenu mergeLanguages({
  required ScrapedMenu sv,
  required ScrapedMenu en,
  required int targetWeek,
}) {
  if (sv.week != en.week) return en.week == targetWeek ? en : sv;
  final weekdays = {
    for (final day in [...sv.days, ...en.days]) day.weekday,
  }.toList()..sort();
  return ScrapedMenu(
    week: sv.week,
    days: [
      for (final weekday in weekdays)
        ScrapedDay(
          weekday,
          mergeDishes(sv.dishesOn(weekday), en.dishesOn(weekday)),
        ),
    ],
    weekly: mergeDishes(sv.weekly, en.weekly),
  );
}

/// Pairs [sv] and [en] dishes by position. Unpaired dishes are kept as they are.
List<Dish> mergeDishes(List<Dish> sv, List<Dish> en) => [
  for (var i = 0; i < sv.length || i < en.length; i++)
    if (i >= en.length)
      sv[i]
    else if (i >= sv.length)
      en[i]
    else
      Dish(
        name: LocalizedText(sv: sv[i].name.sv, en: en[i].name.en),
        description: _merge(sv[i].description, en[i].description),
        category: _merge(sv[i].category, en[i].category),
        price: sv[i].price ?? en[i].price,
        spice: sv[i].spice ?? en[i].spice,
        tags: {...sv[i].tags, ...en[i].tags}.toList(),
      ),
];

LocalizedText? _merge(LocalizedText? sv, LocalizedText? en) =>
    sv == null && en == null ? null : LocalizedText(sv: sv?.sv, en: en?.en);

/// Builds a dish from text in a single [language].
Dish dishIn(
  Language language,
  String name, {
  String? description,
  String? category,
  int? price,
  SpiceLevel? spice,
  List<String> tags = const [],
}) => Dish(
  name: _text(language, name),
  description: description == null || description.isEmpty
      ? null
      : _text(language, description),
  category: category == null || category.isEmpty
      ? null
      : _text(language, category),
  price: price,
  spice: spice,
  tags: tags,
);

LocalizedText _text(Language language, String text) => switch (language) {
  Language.sv => LocalizedText(sv: text),
  Language.en => LocalizedText(en: text),
};
