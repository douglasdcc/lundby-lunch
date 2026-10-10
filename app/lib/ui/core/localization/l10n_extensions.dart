import 'package:flutter/widgets.dart';
import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// The language the app is currently shown in.
  Language get language =>
      Language.tryParse(Localizations.localeOf(this).languageCode) ??
      Language.en;
}

extension LanguageLocale on Language {
  Locale get locale => Locale(name);

  /// The language's name in that language.
  String get nativeName => switch (this) {
    Language.sv => 'Svenska',
    Language.en => 'English',
  };
}
