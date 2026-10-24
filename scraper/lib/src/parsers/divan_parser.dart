import 'package:lunch_core/lunch_core.dart';

import '../fetcher.dart';
import '../pdf_text.dart';
import '../scraped_menu.dart';
import '../text.dart';
import 'menu_parser.dart';

/// Divan: a PDF with "LUNCHMENY V43", numbered dishes served all week at
/// one price ("Pris: 159: -"), a "VECKANSKÖTT: ... 289: -" line and an
/// "INKL: ..." line saying what the price includes. Swedish only.
class DivanParser implements MenuParser {
  DivanParser(this.url, {this._pdfToText = runPdfToText});

  final Uri url;
  final PdfToText _pdfToText;

  @override
  Future<ScrapedMenu> scrape(Fetcher fetcher, IsoWeek week) async =>
      parseDivanMenu(await _pdfToText(await fetcher.getBytes(url)));
}

final _week = RegExp(r'\bV(?:ecka)?\s*(\d{1,2})(?!\d)', caseSensitive: false);
// The name must start with a letter, so "11.00 – 15.00" is not a dish.
final _numberedDish = RegExp(r'^\d{1,2}\s*[.)]\s*(\p{L}.*)$', unicode: true);
final _weeklySpecial = RegExp(
  r'^Veckans\s*([^:]+):\s*(.+?)(?:\s+(\d+)\s*:?\s*-?)?$',
  caseSensitive: false,
);
final _price = RegExp(r'\bPris:\s*(\d+)', caseSensitive: false);
final _includes = RegExp(
  r'^(INKL:.*?)(?:\s*\bPris:.*)?$',
  caseSensitive: false,
);

/// Reads the text of Divan's lunch PDF.
ScrapedMenu parseDivanMenu(String text) {
  final lines = [
    for (final line in text.split(RegExp(r'[\r\n\f]+')))
      if (cleanText(line) case final String clean when clean.isNotEmpty) clean,
  ];

  final names = <String>[];
  Dish? special;
  String? includes;
  int? price;
  for (final line in lines) {
    price ??= findPrice(_price.firstMatch(line)?.group(1));
    if (_numberedDish.firstMatch(line) case final match?) {
      names.add(match.group(1)!);
    } else if (_weeklySpecial.firstMatch(line) case final match?) {
      special = dishIn(
        Language.sv,
        match.group(2)!,
        category: 'Veckans ${match.group(1)!.trim().toLowerCase()}',
        price: findPrice(match.group(3)),
      );
    } else if (_includes.firstMatch(line) case final match?) {
      includes = match.group(1);
    } else if (names.isNotEmpty &&
        special == null &&
        line.startsWith(RegExp('[a-zåäö]'))) {
      // The rest of a dish name that wrapped onto the next line.
      names.last = '${names.last} $line';
    }
  }

  return ScrapedMenu(
    week: switch (_week.firstMatch(lines.join('\n'))?.group(1)) {
      final String number => int.parse(number),
      null => null,
    },
    weekly: [
      for (final name in names) dishIn(Language.sv, name, price: price),
      ?special,
    ],
    notes: includes == null ? null : LocalizedText(sv: includes),
  );
}
