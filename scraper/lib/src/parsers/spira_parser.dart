import 'package:html/parser.dart' as html;
import 'package:lunch_core/lunch_core.dart';

import '../fetcher.dart';
import '../scraped_menu.dart';
import '../text.dart';
import 'menu_parser.dart';

/// Spira: one heading per day, with Swedish and English lines mixed in the
/// same block. Each line's language is guessed from its words.
class SpiraParser implements MenuParser {
  SpiraParser(this.url);

  final Uri url;

  @override
  Future<ScrapedMenu> scrape(Fetcher fetcher, IsoWeek week) async =>
      parseSpiraPage(await fetcher.get(url));
}

ScrapedMenu parseSpiraPage(String page) {
  final document = html.parse(page);
  final days = <ScrapedDay>[];

  for (final element in document.querySelectorAll(
    'h1, h2, h3, h4, h5, h6, p',
  )) {
    final lines = textLines(element);
    if (lines.length < 2) continue;
    final weekday = weekdayFromName(lines.first);
    if (weekday == null || weekday > 5) continue;
    days.add(ScrapedDay(weekday, _pairLanguages(lines.skip(1).toList())));
  }

  return ScrapedMenu(
    week: findWeekNumber(textLines(document).join('\n')),
    days: days,
  );
}

/// Sorts lines into Swedish and English, then pairs them in order. A line
/// whose language can't be guessed is assumed to differ from the previous one.
List<Dish> _pairLanguages(List<String> lines) {
  final sv = <Dish>[];
  final en = <Dish>[];
  Language? previous;
  for (final line in lines) {
    final language =
        guessLanguage(line) ??
        (previous == Language.sv ? Language.en : Language.sv);
    (language == Language.sv ? sv : en).add(dishIn(language, line));
    previous = language;
  }
  return mergeDishes(sv, en);
}
