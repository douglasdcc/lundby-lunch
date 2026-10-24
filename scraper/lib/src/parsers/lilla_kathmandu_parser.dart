import 'dart:convert';

import 'package:lunch_core/lunch_core.dart';

import '../fetcher.dart';
import '../scraped_menu.dart';
import '../text.dart';
import 'menu_parser.dart';

/// Lilla Kathmandu: a fixed menu for even weeks and one for odd weeks,
/// in Swedish only. The page is built with Next.js and carries the menu as
/// JSON in `self.__next_f.push([1, "..."])` scripts.
class LillaKathmanduParser implements MenuParser {
  LillaKathmanduParser(this.url);

  final Uri url;

  @override
  Future<ScrapedMenu> scrape(Fetcher fetcher, IsoWeek week) async =>
      parseLillaKathmanduPage(await fetcher.get(url), week);
}

final _pushPattern = RegExp(
  r'self\.__next_f\.push\(\[1,("(?:[^"\\]|\\.)*")\]\)',
);
final _rowIdPattern = RegExp('^[0-9a-f]+:');

const _weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];

/// Throws a [FormatException] when the page has no menu for [week].
ScrapedMenu parseLillaKathmanduPage(String page, IsoWeek week) {
  final block = _findMenuBlock(page);
  final groupWord = week.week.isEven ? 'jämn' : 'udda';
  final group = (block['primaryGroups'] as List<Object?>? ?? const [])
      .whereType<JsonMap>()
      .where(
        (group) => (group['groupTitle'] as String? ?? '')
            .toLowerCase()
            .contains(groupWord),
      )
      .firstOrNull;
  if (group == null) {
    throw FormatException('No "$groupWord" menu group on the page');
  }

  final sharedPrice = _price(block['sharedPrice']);
  return ScrapedMenu(
    // The menu repeats every other week, so it always fits the target week.
    week: week.week,
    days: [
      for (final (index, weekday) in _weekdays.indexed)
        if (group[weekday] case final JsonMap day)
          ScrapedDay(index + 1, [
            for (final dish
                in (day['dishes'] as List<Object?>? ?? const [])
                    .whereType<JsonMap>())
              if (_dish(dish, sharedPrice) case final Dish parsed) parsed,
          ]),
    ],
  );
}

Dish? _dish(JsonMap json, int? sharedPrice) {
  final name = cleanText(json['name'] as String? ?? '');
  if (name.isEmpty) return null;
  final label = cleanText(json['dietaryLabel'] as String? ?? '');
  final spice = _spice(label);
  return dishIn(
    Language.sv,
    name,
    description: cleanText(json['description'] as String? ?? ''),
    price: _price(json['price']) ?? sharedPrice,
    spice: spice,
    tags: [if (spice == null && label.isNotEmpty) label],
  );
}

SpiceLevel? _spice(String label) => switch (label.toLowerCase()) {
  'mild' => SpiceLevel.mild,
  'mellan' || 'medium' => SpiceLevel.medium,
  'stark' => SpiceLevel.hot,
  _ => null,
};

int? _price(Object? value) => switch (value) {
  final num price => price.round(),
  _ => null,
};

/// Finds the `weeklyLunchMenu` block in the page's Next.js data. The pushed
/// strings join into lines of `id:json`; the block is inside one of them.
JsonMap _findMenuBlock(String page) {
  final data = _pushPattern
      .allMatches(page)
      .map((match) => jsonDecode(match.group(1)!) as String)
      .join();
  for (final line in const LineSplitter().convert(data)) {
    if (!line.contains('"weeklyLunchMenu"')) continue;
    final id = _rowIdPattern.matchAsPrefix(line);
    if (id == null) continue;
    final Object? row;
    try {
      row = jsonDecode(line.substring(id.end));
    } on FormatException {
      continue;
    }
    if (_findBlock(row) case final JsonMap block) return block;
  }
  throw const FormatException('No weekly lunch menu on the page');
}

JsonMap? _findBlock(Object? value) {
  if (value is JsonMap) {
    if (value['blockType'] == 'weeklyLunchMenu' &&
        value['primaryGroups'] is List<Object?>) {
      return value;
    }
    return value.values.map(_findBlock).nonNulls.firstOrNull;
  }
  if (value is List<Object?>) {
    return value.map(_findBlock).nonNulls.firstOrNull;
  }
  return null;
}
