import 'package:html/parser.dart' as html;
import 'package:lunch_core/lunch_core.dart';

import '../fetcher.dart';
import '../scraped_menu.dart';
import '../text.dart';
import 'menu_parser.dart';

/// Bar Centro: an `article.day` per weekday, plus weekly specials. One of
/// the specials lists a vegetarian dish per weekday ("Monday; ...").
class BarCentroParser implements MenuParser {
  BarCentroParser({required this.sv, required this.en});

  final Uri sv;
  final Uri en;

  @override
  Future<ScrapedMenu> scrape(Fetcher fetcher, IsoWeek week) async {
    final pages = await Future.wait([fetcher.get(sv), fetcher.get(en)]);
    return mergeLanguages(
      sv: parseBarCentroPage(pages[0], Language.sv),
      en: parseBarCentroPage(pages[1], Language.en),
      targetWeek: week.week,
    );
  }
}

final _weekdayItem = RegExp(r'^([^;:]+)[;:]\s*(.+)$');

ScrapedMenu parseBarCentroPage(String page, Language language) {
  final section = html.parse(page).querySelector('article.lunchmenu');
  if (section == null) return const ScrapedMenu(week: null);

  final dishesByDay = <int, List<Dish>>{};
  final weekly = <Dish>[];

  for (final day in section.querySelectorAll('article.day')) {
    final title = cleanText(day.querySelector('h4')?.text ?? '');
    final price = findPrice(day.querySelector('.price')?.text);
    final lines = textLines(day.querySelector('section') ?? day);
    final isSpecial = day.parent?.classes.contains('specials') ?? false;

    if (!isSpecial) {
      final weekday = weekdayFromName(title);
      if (weekday == null || weekday > 5) continue;
      for (final line in lines) {
        dishesByDay
            .putIfAbsent(weekday, () => [])
            .add(_dish(language, line, price: price));
      }
      continue;
    }

    final category = title.replaceAll(RegExp(r'[:;]+$'), '').trim();
    final perDay = [for (final line in lines) _weekdayItem.firstMatch(line)];
    if (perDay.isNotEmpty &&
        perDay.every(
          (match) => match != null && weekdayFromName(match.group(1)!) != null,
        )) {
      for (final match in perDay.nonNulls) {
        final weekday = weekdayFromName(match.group(1)!)!;
        dishesByDay
            .putIfAbsent(weekday, () => [])
            .add(
              _dish(
                language,
                match.group(2)!,
                category: category,
                price: price,
              ),
            );
      }
    } else {
      for (final line in lines) {
        weekly.add(_dish(language, line, category: category, price: price));
      }
    }
  }

  return ScrapedMenu(
    week: findWeekNumber(section.querySelector('header')?.text ?? ''),
    days: [
      for (final weekday in dishesByDay.keys.toList()..sort())
        ScrapedDay(weekday, dishesByDay[weekday]!),
    ],
    weekly: weekly,
  );
}

Dish _dish(Language language, String text, {String? category, int? price}) {
  final (:name, :tags) = extractTags(text);
  return dishIn(language, name, category: category, price: price, tags: tags);
}
