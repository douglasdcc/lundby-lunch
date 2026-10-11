import 'package:html/parser.dart' as html;
import 'package:lunch_core/lunch_core.dart';

import '../fetcher.dart';
import '../scraped_menu.dart';
import '../text.dart';
import 'menu_parser.dart';

/// Mashie / Matilda Platform menu app (used by Compass for Z:äta). The page
/// lists one or more weeks; each dish appears twice, in Swedish then English.
class MashieParser implements MenuParser {
  MashieParser(this.url);

  final Uri url;

  @override
  Future<ScrapedMenu> scrape(Fetcher fetcher, IsoWeek week) async =>
      parseMashiePage(await fetcher.get(url), week.week);
}

/// Returns the week numbered [targetWeek], or the last week on the page when
/// it isn't there.
ScrapedMenu parseMashiePage(String page, int targetWeek) {
  final weeks = <int, List<ScrapedDay>>{};
  int? currentWeek;

  for (final element
      in html.parse(page).querySelectorAll('h4.app-week, div.panel')) {
    if (element.localName == 'h4') {
      currentWeek = findWeekNumber(element.text);
      continue;
    }
    final week = currentWeek;
    if (week == null) continue;
    final heading = textLines(
      element.querySelector('.panel-heading') ?? element,
    );
    final weekday = heading.map(weekdayFromName).nonNulls.firstOrNull;
    if (weekday == null || weekday > 5) continue;

    final items = <_Item>[];
    for (final item in element.querySelectorAll('.list-group-item-menu')) {
      final name = cleanText(
        item.querySelector('.app-daymenu-name')?.text ?? '',
      );
      if (name.isEmpty) continue;
      final category = cleanText(
        item.querySelector('.app-alternative-name')?.text ?? '',
      );
      items.add(_Item(category, name));
    }
    weeks.putIfAbsent(week, () => []).add(ScrapedDay(weekday, _pair(items)));
  }

  if (weeks.isEmpty) return const ScrapedMenu(week: null);
  final week = weeks.containsKey(targetWeek) ? targetWeek : weeks.keys.last;
  return ScrapedMenu(week: week, days: weeks[week]!);
}

final _languageSuffix = RegExp(r'\s+(sv|en)$', caseSensitive: false);

/// One listed alternative, in a single language.
final class _Item {
  _Item(String category, this.name)
    : category = category.replaceAll(_languageSuffix, ''),
      language =
          switch (_languageSuffix.firstMatch(category)?.group(1)?.toLowerCase()) {
            'sv' => Language.sv,
            'en' => Language.en,
            _ => guessLanguage(name),
          };

  final String category;
  final String name;

  /// From an "Sv"/"En" category suffix, or guessed from the words.
  final Language? language;
}

/// Each Swedish alternative is listed right before its English version.
/// Alternatives without a partner become single-language dishes.
List<Dish> _pair(List<_Item> items) {
  final dishes = <Dish>[];
  for (var i = 0; i < items.length; i++) {
    final sv = items[i];
    final en = i + 1 < items.length ? items[i + 1] : null;
    if ((sv.language ?? Language.sv) == Language.sv &&
        en != null &&
        (en.language ?? Language.en) == Language.en) {
      dishes.add(
        Dish(
          name: LocalizedText(sv: sv.name, en: en.name),
          category: LocalizedText(sv: sv.category, en: en.category),
        ),
      );
      i++;
    } else {
      dishes.add(
        dishIn(sv.language ?? Language.sv, sv.name, category: sv.category),
      );
    }
  }
  return dishes;
}
