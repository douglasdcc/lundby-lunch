import 'dart:convert';

import 'package:html/parser.dart' as html;
import 'package:lunch_core/lunch_core.dart';

import '../fetcher.dart';
import '../scraped_menu.dart';
import '../text.dart';
import 'menu_parser.dart';

/// Compass Group's menu API, queried one day at a time in each language.
///
/// A day response looks like `{"menuPackages": [{"name", "price", "meals":
/// [{"name", "diets": [...]}]}], "html": null}`; `html` holds a manually
/// written menu instead of packages.
class CompassApiParser implements MenuParser {
  CompassApiParser(this.costCenter);

  final String costCenter;

  static final _base = Uri.parse(
    'https://www.compass-group.se/menuapi/day-menus',
  );

  Uri dayUrl(DateTime date, Language language) => _base.replace(
    queryParameters: {
      'costCenter': costCenter,
      'date': '${formatDate(date)}T00:00:00.000Z',
      'language': language.name,
    },
  );

  @override
  Future<ScrapedMenu> scrape(Fetcher fetcher, IsoWeek week) async {
    final days = <ScrapedDay>[];
    for (final date in week.weekdays) {
      final sv = parseCompassDay(
        await fetcher.get(dayUrl(date, Language.sv)),
        Language.sv,
      );
      final en = parseCompassDay(
        await fetcher.get(dayUrl(date, Language.en)),
        Language.en,
      );
      days.add(ScrapedDay(date.weekday, mergeDishes(sv, en)));
    }
    // The API answers for the requested dates, so the week is always the target.
    return ScrapedMenu(week: week.week, days: days);
  }
}

/// Throws a [FormatException] when [body] is not a day-menu object.
List<Dish> parseCompassDay(String body, Language language) {
  final json = jsonDecode(body);
  if (json is! JsonMap) {
    throw const FormatException('Expected a day-menu object');
  }

  final manual = json['html'];
  if (manual is String && manual.trim().isNotEmpty) {
    return [
      for (final line in textLines(html.parseFragment(manual)))
        dishIn(language, line),
    ];
  }

  return [
    for (final package
        in (json['menuPackages'] as List<Object?>? ?? const [])
            .whereType<JsonMap>())
      for (final meal
          in (package['meals'] as List<Object?>? ?? const [])
              .whereType<JsonMap>())
        if (meal['name'] case final String name when name.trim().isNotEmpty)
          dishIn(
            language,
            cleanText(name),
            category: package['name'] as String?,
            price: findPrice(package['price']?.toString()),
            tags: [
              for (final diet in meal['diets'] as List<Object?>? ?? const [])
                if (diet is String) diet,
            ],
          ),
  ];
}
