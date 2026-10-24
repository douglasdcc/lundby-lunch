import 'dart:io';

import 'package:lunch_core/lunch_core.dart';
import 'package:lunch_scraper/lunch_scraper.dart';
import 'package:test/test.dart';

import '../testing.dart';

bool _hasPdfToText() {
  try {
    // Any exit code will do: xpdf's `pdftotext -v` exits with 99.
    Process.runSync('pdftotext', ['-v']);
    return true;
  } on ProcessException {
    return false;
  }
}

void main() {
  group('parseDivanMenu', () {
    final menu = parseDivanMenu(fixture('divan.txt'));

    test('reads the week and has the same dishes all week', () {
      expect(menu.week, 43);
      expect(menu.days, isEmpty);
      expect(menu.weekly, hasLength(11));
    });

    test('reads numbered dishes in Swedish at the shared price', () {
      final first = menu.weekly.first;
      expect(
        first.name.sv,
        'Kolgrillade kalvfärsbiffar med champinjonsås & råstekpotatis',
      );
      expect(first.name.en, isNull);
      expect(first.category, isNull);
      expect(first.price, 159);
      expect(
        menu.weekly[1].name.sv,
        'Kebab med pommes & mild sås / Kebab i pitabröd',
      );
    });

    test('joins dish names that wrap onto the next line', () {
      expect(
        menu.weekly[9].name.sv,
        'Kolgrillad Adana (stark) lammfärsspett med ris, råstek potatis & '
        'vitlöksyoghurt',
      );
    });

    test('reads the weekly special with its own price', () {
      final special = menu.weekly.last;
      expect(special.name.sv, 'Oxfilé med valfri sås & räfflad potatis');
      expect(special.category?.sv, 'Veckans kött');
      expect(special.price, 289);
    });

    test('reads what the price includes as a note, without the price', () {
      expect(
        menu.notes?.sv,
        'INKL: Salladsbuffé, bröd, smör, dricka, kaffe och dessert',
      );
      expect(menu.notes?.en, isNull);
    });

    test('handles Windows line endings', () {
      final crlf = parseDivanMenu(
        fixture('divan.txt').replaceAll('\n', '\r\n'),
      );
      expect(crlf.weekly[9].name.sv, menu.weekly[9].name.sv);
      expect(crlf.weekly.last.price, 289);
    });

    test('text without a menu has no week and no dishes', () {
      final empty = parseDivanMenu('Stängt för semester');
      expect(empty.week, isNull);
      expect(empty.hasDishes, isFalse);
      expect(empty.notes, isNull);
    });
  });

  test('scrape converts the downloaded PDF to text', () async {
    const url = 'https://divan.example/lunch.pdf';
    List<int>? converted;
    final parser = DivanParser(
      Uri.parse(url),
      pdfToText: (pdf) async {
        converted = pdf;
        return fixture('divan.txt');
      },
    );

    final menu = await parser.scrape(
      FakeFetcher({url: 'pdf bytes'}),
      IsoWeek(2026, 43),
    );

    expect(converted, 'pdf bytes'.codeUnits);
    expect(menu.week, 43);
    expect(menu.weekly, hasLength(11));
  });

  test('pdftotext reads the real PDF', () async {
    final text = await runPdfToText(
      File('test/fixtures/divan.pdf').readAsBytesSync(),
    );
    final menu = parseDivanMenu(text);
    expect(menu.week, 43);
    expect(
      [for (final dish in menu.weekly) dish.name.sv],
      [
        for (final dish in parseDivanMenu(fixture('divan.txt')).weekly)
          dish.name.sv,
      ],
    );
    expect(menu.notes?.sv, parseDivanMenu(fixture('divan.txt')).notes?.sv);
  }, skip: _hasPdfToText() ? false : 'pdftotext is not installed');
}
