// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Lundby Lunch';

  @override
  String get navToday => 'Idag';

  @override
  String get navWeek => 'Vecka';

  @override
  String get navSettings => 'Inställningar';

  @override
  String weekNumber(int week) {
    return 'Vecka $week';
  }

  @override
  String get allWeek => 'Hela veckan';

  @override
  String get noMenuForDay => 'Ingen meny för den här dagen.';

  @override
  String get menuMissing => 'Veckans meny är inte publicerad än.';

  @override
  String get menuError => 'Kunde inte läsa restaurangens meny.';

  @override
  String get openWebsite => 'Öppna webbplats';

  @override
  String staleWeek(int shown, int target) {
    return 'Visar vecka $shown. Menyerna för vecka $target är inte publicerade än.';
  }

  @override
  String get loadErrorTitle => 'Kunde inte hämta menyerna';

  @override
  String get loadErrorMessage => 'Kontrollera anslutningen och försök igen.';

  @override
  String get retry => 'Försök igen';

  @override
  String get refreshFailed => 'Kunde inte uppdatera. Visar sparade menyer.';

  @override
  String lastUpdated(String time) {
    return 'Uppdaterad $time';
  }

  @override
  String price(int price) {
    return '$price kr';
  }

  @override
  String get allRestaurantsHidden =>
      'Alla restauranger är dolda. Slå på dem i Inställningar.';

  @override
  String get settingsLanguage => 'Språk';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Ljust';

  @override
  String get themeDark => 'Mörkt';

  @override
  String get settingsStartScreen => 'Startskärm';

  @override
  String get settingsRestaurants => 'Restauranger';

  @override
  String get settingsRestaurantsHint =>
      'Dra för att ändra ordning. Stäng av för att dölja.';

  @override
  String get settingsRestaurantsEmpty =>
      'Restaurangerna visas här när menyerna har hämtats.';

  @override
  String get settingsAbout => 'Om appen';

  @override
  String get aboutText =>
      'Menyerna hämtas en gång i veckan från restaurangernas webbplatser. Rätter och priser kan ändras, så kontrollera med restaurangen.';

  @override
  String get sampleDataNotice => 'Den här versionen visar exempeldata.';
}
