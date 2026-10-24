import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:lunch_core/lunch_core.dart';

import '../fetcher.dart';
import '../scraped_menu.dart';
import '../text.dart';
import 'menu_parser.dart';

/// Masala Zone: one accordion tab per weekday ("Monday" or "Måndag/Monday"),
/// each with numbered dishes such as "3. MALWANI GOSHT (LAKTOSFRI) 🌶️🌶️" and
/// a Swedish and an English description line. "2 & 3.KOMBINERAD" combines
/// two of the day's dishes. Every day also lists the same pizzas, after a
/// "… ingår i alla pizzor" heading. The page shows no week number, and the
/// menu is printed more than once.
class MasalaZoneParser implements MenuParser {
  MasalaZoneParser(this.url);

  final Uri url;

  @override
  Future<ScrapedMenu> scrape(Fetcher fetcher, IsoWeek week) async =>
      parseMasalaZonePage(await fetcher.get(url), week);
}

final _numbered = RegExp(r'^(\d+)\s*\.\s*(.+)$');
final _combined = RegExp(
  r'^(\d+)\s*&\s*(\d+)\s*\.?\s*kombinerad',
  caseSensitive: false,
);
final _label = RegExp(r'\(([^)]*)\)');
final _chili = RegExp('\u{1F336}\u{FE0F}?', unicode: true);
final _lunchPrice = RegExp(r'\bfr\.\s*(\d+)', caseSensitive: false);
final _includes = RegExp(r'^I dagens ingår:', caseSensitive: false);

/// English for the "I dagens ingår" lines seen on the page so far.
const _includesEn = {
  'I dagens ingår: Naanbröd, ris salladsbuffé, kaffe & kaka':
      'Included: naan bread, rice, salad buffet, coffee & cake',
};

/// Throws a [FormatException] when the page has no weekday menus.
ScrapedMenu parseMasalaZonePage(String page, IsoWeek week) {
  final document = html.parse(page);
  final lines = textLines(document.body ?? document.documentElement!);
  final lunchPrice = findPrice(
    lines.map(_lunchPrice.firstMatch).nonNulls.firstOrNull?.group(1),
  );

  final days = <int, ScrapedDay>{};
  for (final tab in document.querySelectorAll('.pp-accordion-item')) {
    final title = tab.querySelector('.pp-accordion-title-text')?.text ?? '';
    final weekday = title.split('/').map(weekdayFromName).nonNulls.firstOrNull;
    final content = tab.querySelector('.pp-accordion-tab-content');
    // The menu is printed more than once; the first copy wins.
    if (weekday == null || weekday > 5 || content == null) continue;
    days.putIfAbsent(
      weekday,
      () => ScrapedDay(weekday, _dishes(content, lunchPrice)),
    );
  }
  if (days.isEmpty) {
    throw const FormatException('No weekday menus on the page');
  }

  return ScrapedMenu(
    // The page has no week number; it always shows the current menu.
    week: week.week,
    days: [for (final weekday in days.keys.toList()..sort()) days[weekday]!],
    notes: _notes(lines),
  );
}

List<Dish> _dishes(Element content, int? lunchPrice) {
  final byNumber = <String, Dish>{};
  final dishes = <Dish>[];
  for (final element in content.querySelectorAll(
    'h2, .pp-restaurant-menu-item',
  )) {
    if (element.localName == 'h2') {
      // The pizzas follow; they are summed up in the notes instead.
      if (element.text.toLowerCase().contains('pizz')) break;
      continue;
    }
    final title = cleanText(
      element.querySelector('.pp-restaurant-menu-title-text')?.text ?? '',
    );
    final price =
        findPrice(element.querySelector('.pp-restaurant-menu-price')?.text) ??
        lunchPrice;

    if (_combined.firstMatch(title) case final match?) {
      final parts = [byNumber[match.group(1)], byNumber[match.group(2)]];
      if (parts.nonNulls.length == 2) dishes.add(_combine(parts, price));
      continue;
    }
    final number = _numbered.firstMatch(title);
    final dish = _dish(
      number?.group(2) ?? title,
      element.querySelector('.pp-restaurant-menu-description'),
      price,
    );
    if (dish == null) continue;
    if (number != null) byNumber[number.group(1)!] = dish;
    dishes.add(dish);
  }
  return dishes;
}

Dish? _dish(String title, Element? description, int? price) {
  final name = _titleCase(
    cleanText(title.replaceAll(_label, '').replaceAll(_chili, '')),
  );
  if (name.isEmpty) return null;

  // Swedish line, English line, then lines in neither (such as the names of
  // the vegetarian dishes), which belong to both.
  final lines = description == null ? const <String>[] : textLines(description);
  final shared = lines.skip(2).join(' ');
  String? withShared(String? line) =>
      line == null ? null : cleanText('$line $shared');

  return Dish(
    name: LocalizedText(sv: name),
    description: lines.isEmpty
        ? null
        : LocalizedText(
            sv: withShared(lines.first),
            en: withShared(lines.elementAtOrNull(1)),
          ),
    price: price,
    spice: _spice(_chili.allMatches(title).length),
    tags: [
      for (final match in _label.allMatches(title))
        if (_titleCase(cleanText(match.group(1)!)) case final tag
            when tag.isNotEmpty)
          tag,
    ],
  );
}

/// "2 & 3.KOMBINERAD": both dishes on one plate.
Dish _combine(List<Dish?> parts, int? price) {
  final dishes = parts.nonNulls.toList();
  final spices = dishes.map((dish) => dish.spice).nonNulls;
  return Dish(
    name: LocalizedText(sv: dishes.map((dish) => dish.name.sv).join(' + ')),
    price: price,
    spice: spices.isEmpty
        ? null
        : spices.reduce((a, b) => a.index >= b.index ? a : b),
    // A label holds for the plate only when it holds for every dish.
    tags: [
      for (final tag in dishes.first.tags)
        if (dishes.every((dish) => dish.tags.contains(tag))) tag,
    ],
  );
}

SpiceLevel? _spice(int chilies) => switch (chilies) {
  0 => null,
  1 => SpiceLevel.mild,
  2 => SpiceLevel.medium,
  _ => SpiceLevel.hot,
};

final _wordStart = RegExp(r'(^|[\s./-])(\p{L})', unicode: true);

/// "MIX VEG.TALLRIK" → "Mix Veg.Tallrik".
String _titleCase(String text) => text.toLowerCase().replaceAllMapped(
  _wordStart,
  (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}',
);

LocalizedText? _notes(List<String> lines) {
  final includes = lines.where(_includes.hasMatch).firstOrNull;
  final hasPizza = lines.any(
    (line) => line.toLowerCase().contains('ingår i alla pizzor'),
  );
  String? join(String? first, String? second) {
    final parts = [?first, ?second];
    return parts.isEmpty ? null : parts.join('. ');
  }

  final sv = join(includes, hasPizza ? 'Pizza finns också som lunch.' : null);
  if (sv == null) return null;
  final includesEn = includes == null ? null : _includesEn[includes];
  return LocalizedText(
    sv: sv,
    // Without a known translation, the Swedish note is shown in English too.
    en: includes != null && includesEn == null
        ? null
        : join(
            includesEn,
            hasPizza ? 'Pizza is also available for lunch.' : null,
          ),
  );
}
