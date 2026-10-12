import 'package:html/parser.dart' as html;
import 'package:lunch_core/lunch_core.dart';

import '../fetcher.dart';
import '../scraped_menu.dart';
import '../text.dart';
import 'menu_parser.dart';

/// Spira: a weekday name followed by its dishes, with Swedish and English
/// lines mixed together. Days come one per heading or several in the same
/// heading. Each line's language is guessed from its words.
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
    int? weekday;
    var dishLines = <String>[];

    void addDay() {
      if (weekday != null && weekday <= 5 && dishLines.isNotEmpty) {
        days.add(ScrapedDay(weekday, _pairLanguages(_joinWrapped(dishLines))));
      }
    }

    for (final line in textLines(element)) {
      final name = weekdayFromName(line);
      if (name != null) {
        addDay();
        weekday = name;
        dishLines = [];
      } else if (weekday != null) {
        dishLines.add(line);
      }
    }
    addDay();
  }

  return ScrapedMenu(
    week: findWeekNumber(textLines(document).join('\n')),
    days: days,
  );
}

/// Joins a line that starts in lowercase onto the line before it, since
/// it is the rest of a dish name that wrapped.
List<String> _joinWrapped(List<String> lines) {
  final joined = <String>[];
  for (final line in lines) {
    if (joined.isNotEmpty && line.startsWith(RegExp('[a-zåäö]'))) {
      joined.last = '${joined.last} $line';
    } else {
      joined.add(line);
    }
  }
  return joined;
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
