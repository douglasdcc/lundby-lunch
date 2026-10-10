import 'package:lunch_core/lunch_core.dart';
import 'package:test/test.dart';

void main() {
  test('resolve returns the requested language', () {
    const text = LocalizedText(sv: 'Soppa', en: 'Soup');
    expect(text.resolve(Language.sv), 'Soppa');
    expect(text.resolve(Language.en), 'Soup');
  });

  test('resolve falls back to the other language', () {
    expect(const LocalizedText(sv: 'Soppa').resolve(Language.en), 'Soppa');
    expect(const LocalizedText(en: 'Soup').resolve(Language.sv), 'Soup');
  });

  test('toJson omits missing languages', () {
    expect(const LocalizedText(en: 'Soup').toJson(), {'en': 'Soup'});
  });

  test('Language.tryParse returns null for unknown codes', () {
    expect(Language.tryParse('sv'), Language.sv);
    expect(Language.tryParse('de'), isNull);
    expect(Language.tryParse(null), isNull);
  });
}
