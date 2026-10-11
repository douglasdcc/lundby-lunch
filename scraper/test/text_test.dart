import 'package:html/parser.dart' as html;
import 'package:lunch_core/lunch_core.dart';
import 'package:lunch_scraper/lunch_scraper.dart';
import 'package:test/test.dart';

void main() {
  test('cleanText collapses whitespace and drops special spaces', () {
    final nbsp = String.fromCharCode(0xa0);
    final zeroWidth = String.fromCharCode(0x200b);
    expect(
      cleanText('  Fish$nbsp$nbsp of\n the${zeroWidth}day  '),
      'Fish of theday',
    );
  });

  test('textLines breaks at <br> and block elements', () {
    final fragment = html.parseFragment(
      '<div><h4>Monday</h4><p>Soup<br>Bread <b>and</b> butter</p>Tea</div>',
    );
    expect(textLines(fragment), ['Monday', 'Soup', 'Bread and butter', 'Tea']);
  });

  test('textLines skips scripts and styles', () {
    final fragment = html.parseFragment(
      '<p>Soup</p><script>x()</script><style>p{}</style>',
    );
    expect(textLines(fragment), ['Soup']);
  });

  test('weekdayFromName reads Swedish and English names', () {
    expect(weekdayFromName('Måndag'), 1);
    expect(weekdayFromName(' FRIDAY: '), 5);
    expect(weekdayFromName('Söndag'), 7);
    expect(weekdayFromName('Monday special'), isNull);
  });

  test('findWeekNumber finds "Vecka" and "Week" numbers', () {
    expect(findWeekNumber('Lunch at Roots   Week 41'), 41);
    expect(findWeekNumber('Lunchmeny vecka 41Välkomna!'), 41);
    expect(findWeekNumber('Vecka 7'), 7);
    expect(findWeekNumber('Weekly specials'), isNull);
  });

  test('findPrice reads the first number', () {
    expect(findPrice('115 kr'), 115);
    expect(findPrice('Pris: 99:-'), 99);
    expect(findPrice(null), isNull);
    expect(findPrice('free'), isNull);
  });

  test('extractTags splits diet labels off the name', () {
    final soup = extractTags('Soup with croutons (G)(L)');
    expect(soup.name, 'Soup with croutons');
    expect(soup.tags, ['G', 'L']);

    final halloumi = extractTags('Halloumi and spinach (L), including Friday cake');
    expect(halloumi.name, 'Halloumi and spinach, including Friday cake');
    expect(halloumi.tags, ['L']);

    expect(extractTags('Plain dish').tags, isEmpty);
  });

  test('guessLanguage tells Swedish from English', () {
    expect(guessLanguage('Kokt torsk med äggsås och potatis'), Language.sv);
    expect(
      guessLanguage('Boiled cod with egg sauce and potatoes'),
      Language.en,
    );
    expect(guessLanguage('Gyros'), isNull);
  });
}
