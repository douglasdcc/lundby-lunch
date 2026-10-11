import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:lunch_core/lunch_core.dart';

import '../fetcher.dart';
import '../scraped_menu.dart';
import '../text.dart';
import 'menu_parser.dart';

/// Roots (Wix site): one rich-text block per language with a "Week 41"
/// heading, weekday headings and "Category: dish" lines.
class RootsParser implements MenuParser {
  RootsParser({required this.sv, required this.en});

  final Uri sv;
  final Uri en;

  @override
  Future<ScrapedMenu> scrape(Fetcher fetcher, IsoWeek week) async {
    final pages = await Future.wait([fetcher.get(sv), fetcher.get(en)]);
    return mergeLanguages(
      sv: parseRootsPage(pages[0], Language.sv),
      en: parseRootsPage(pages[1], Language.en),
      targetWeek: week.week,
    );
  }
}

final _categoryLine = RegExp(r'^([^:,]{2,25}):\s*(.*)$');
final _separatorLine = RegExp(r'^[_\-–—\s]+$');

ScrapedMenu parseRootsPage(String page, Language language) {
  final block = _menuBlock(html.parse(page));
  if (block == null) return const ScrapedMenu(week: null);

  final lines = textLines(block);
  final week = findWeekNumber(lines.join('\n'));
  final days = <ScrapedDay>[];
  List<Dish>? dishes;

  for (final line in lines) {
    if (_separatorLine.hasMatch(line)) continue;
    final weekday = weekdayFromName(line);
    if (weekday != null) {
      dishes = [];
      if (weekday <= 5) days.add(ScrapedDay(weekday, dishes));
      continue;
    }
    if (dishes == null) continue;

    final category = _categoryLine.firstMatch(line);
    if (category != null) {
      dishes.add(
        dishIn(
          language,
          category.group(2)!,
          category: category.group(1)!.trim(),
        ),
      );
    } else if (dishes.isNotEmpty) {
      // A dish name wrapped onto the next line.
      final last = dishes.removeLast();
      final name = cleanText('${last.name[language] ?? ''} $line');
      dishes.add(dishIn(language, name, category: last.category?[language]));
    } else {
      dishes.add(dishIn(language, line));
    }
  }

  return ScrapedMenu(
    week: week,
    days: [
      for (final day in days)
        ScrapedDay(day.weekday, [
          for (final dish in day.dishes)
            if (!dish.name.isEmpty) dish,
        ]),
    ],
  );
}

/// The rich-text block that has both a week number and a weekday heading.
Element? _menuBlock(Document document) {
  final candidates = [
    ...document.querySelectorAll('[data-testid="richTextElement"]'),
    ...document.querySelectorAll('div'),
  ];
  for (final element in candidates) {
    final lines = textLines(element);
    if (findWeekNumber(lines.join('\n')) != null &&
        lines.any((line) => weekdayFromName(line) != null)) {
      return element;
    }
  }
  return null;
}
