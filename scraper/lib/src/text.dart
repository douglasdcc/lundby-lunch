import 'package:html/dom.dart';
import 'package:lunch_core/lunch_core.dart';

const _blockTags = {
  'p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'ul', 'ol', //
  'article', 'section', 'aside', 'header', 'footer', 'main', 'tr', 'td',
};

/// Collapses whitespace and removes non-breaking and zero-width spaces.
String cleanText(String text) => text
    .replaceAll('\u200b', '')
    .replaceAll('\u00a0', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// The text of [root] split into clean, non-empty lines. Lines break at
/// `<br>` and at block elements such as `<p>` and `<div>`.
List<String> textLines(Node root) {
  final lines = <String>[];
  final buffer = StringBuffer();

  void flush() {
    final line = cleanText(buffer.toString());
    if (line.isNotEmpty) lines.add(line);
    buffer.clear();
  }

  void visit(Node node) {
    if (node is Text) {
      buffer.write(node.text);
      return;
    }
    final tag = node is Element ? node.localName : null;
    if (tag == 'br') return flush();
    if (tag == 'script' || tag == 'style') return;
    final isBlock = _blockTags.contains(tag);
    if (isBlock) flush();
    for (final child in node.nodes) {
      visit(child);
    }
    if (isBlock) flush();
  }

  visit(root);
  flush();
  return lines;
}

const _weekdays = {
  'måndag': 1, 'monday': 1, //
  'tisdag': 2, 'tuesday': 2,
  'onsdag': 3, 'wednesday': 3,
  'torsdag': 4, 'thursday': 4,
  'fredag': 5, 'friday': 5,
  'lördag': 6, 'saturday': 6,
  'söndag': 7, 'sunday': 7,
};

/// The ISO weekday (1 = Monday) when [text] is just a weekday name, in
/// Swedish or English, optionally followed by `:` or `;`.
int? weekdayFromName(String text) =>
    _weekdays[cleanText(text).toLowerCase().replaceAll(RegExp(r'[:;.]+$'), '')];

final _weekPattern = RegExp(
  r'\b(?:vecka|week)\s*(\d{1,2})(?!\d)',
  caseSensitive: false,
);

/// The first week number written as "Vecka 41" or "Week 41" in [text].
int? findWeekNumber(String text) =>
    switch (_weekPattern.firstMatch(text)?.group(1)) {
      final String number => int.parse(number),
      null => null,
    };

/// The first whole number in [text], such as the 115 in "115 kr".
int? findPrice(String? text) =>
    switch (RegExp(r'\d+').firstMatch(text ?? '')?.group(0)) {
      final String number => int.parse(number),
      null => null,
    };

final _tagPattern = RegExp(r'\s*\(([A-ZÅÄÖ]{1,3})\)');

/// Splits diet labels such as "(L)" or "(G)(L)" off a dish name.
({String name, List<String> tags}) extractTags(String text) {
  final tags = [
    for (final match in _tagPattern.allMatches(text)) match.group(1)!,
  ];
  return (name: cleanText(text.replaceAll(_tagPattern, '')), tags: tags);
}

const _swedishWords = {
  'med', 'och', 'samt', 'serveras', 'eller', 'på', 'av', 'till', 'rostad', //
  'rostade', 'kokt', 'stekt', 'ugnsbakad', 'sås', 'dagens',
};
const _englishWords = {
  'with', 'and', 'served', 'or', 'of', 'the', 'roasted', 'boiled', 'fried', //
  'baked', 'sauce', 'day',
};

/// Guesses whether [text] is Swedish or English from common words and
/// Swedish letters. Returns null when it can't tell.
Language? guessLanguage(String text) {
  var score = RegExp('[åäöÅÄÖ]').hasMatch(text) ? 2 : 0;
  for (final word in text.toLowerCase().split(RegExp(r'[^a-zåäöéü]+'))) {
    if (_swedishWords.contains(word)) score++;
    if (_englishWords.contains(word)) score--;
  }
  if (score > 0) return Language.sv;
  if (score < 0) return Language.en;
  return null;
}
