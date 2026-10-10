import 'json.dart';

/// Languages the menus and the app are available in.
enum Language {
  sv,
  en;

  static Language? tryParse(String? code) {
    for (final language in values) {
      if (language.name == code) return language;
    }
    return null;
  }
}

/// A text in Swedish and/or English.
final class LocalizedText {
  const LocalizedText({this.sv, this.en});

  factory LocalizedText.fromJson(JsonMap json) =>
      LocalizedText(sv: json['sv'] as String?, en: json['en'] as String?);

  final String? sv;
  final String? en;

  String? operator [](Language language) => switch (language) {
    Language.sv => sv,
    Language.en => en,
  };

  /// The text in [language], falling back to the other language.
  String resolve(Language language) => this[language] ?? sv ?? en ?? '';

  bool get isEmpty => (sv ?? '').isEmpty && (en ?? '').isEmpty;

  JsonMap toJson() => {'sv': ?sv, 'en': ?en};
}
